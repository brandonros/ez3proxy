#!/usr/bin/env just --justfile

set shell := ["bash", "-euo", "pipefail", "-c"]

# Default recipe
default:
    @just --list

# One-time setup: generate keys and create secrets
init:
    just keygen
    just hostkeygen
    just secrets-init
    just encrypt
    @echo ""
    @echo "Setup complete! Run: just go"

# Generate SSH deploy key
keygen:
    #!/usr/bin/env bash
    if [ -f secrets/deploy-key ]; then
        echo "Deploy key already exists at secrets/deploy-key"
    else
        mkdir -p secrets
        ssh-keygen -t ed25519 -f secrets/deploy-key -N ""
    fi

# Generate SSH host key (for agenix)
hostkeygen:
    #!/usr/bin/env bash
    if [ -f secrets/host-key ]; then
        echo "Host key already exists at secrets/host-key"
    else
        mkdir -p secrets
        ssh-keygen -t ed25519 -f secrets/host-key -N "" -C "ez3proxy"
    fi

# Create secrets files interactively
secrets-init:
    #!/usr/bin/env bash
    mkdir -p secrets
    if [ ! -f secrets/password-hash ]; then
        read -s -p "Enter system password: " password
        echo
        nix-shell -p python3Packages.passlib --run "python3 -c \"from passlib.hash import sha512_crypt; print(sha512_crypt.hash('$password'))\"" > secrets/password-hash
        echo "Created secrets/password-hash"
    fi
    if [ ! -f secrets/proxy-users ]; then
        read -p "Enter proxy username: " proxy_user
        read -s -p "Enter proxy password: " proxy_pass
        echo
        echo "users ${proxy_user}:CL:${proxy_pass}" > secrets/proxy-users
        echo "Created secrets/proxy-users"
    fi

# Encrypt secrets with age
encrypt:
    age -r "$(cat secrets/host-key.pub)" -o secrets/proxy-users.age secrets/proxy-users
    age -r "$(cat secrets/host-key.pub)" -o secrets/password-hash.age secrets/password-hash
    rm -f secrets/proxy-users secrets/password-hash
    @echo "Plaintext secrets removed"

# Get server IP from terraform
server-ip:
    @cd terraform && terraform output -raw server_ipv4 2>/dev/null

# Deploy infrastructure
deploy:
    cd terraform && terraform init -upgrade && terraform apply

# Wait for SSH
wait:
    #!/usr/bin/env bash
    set +e
    server_ip=$(just server-ip)
    echo "Waiting for SSH on ${server_ip}..."
    while ! ssh -i secrets/deploy-key -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes "root@${server_ip}" 'echo ok' 2>/dev/null; do
        sleep 5
    done
    echo "SSH ready"

# Bootstrap NixOS (destructive - reformats disks)
bootstrap:
    #!/usr/bin/env bash
    server_ip=$(just server-ip)
    echo "Installing NixOS on ${server_ip}..."
    # Prepare host key for agenix decryption (in /persist for impermanence)
    tmp=$(mktemp -d)
    install -d -m 755 "$tmp/persist/etc/ssh"
    install -m 600 secrets/host-key "$tmp/persist/etc/ssh/ssh_host_ed25519_key"
    install -m 644 secrets/host-key.pub "$tmp/persist/etc/ssh/ssh_host_ed25519_key.pub"
    nix run github:nix-community/nixos-anywhere -- --flake .#ez3proxy --target-host "root@${server_ip}" -i secrets/deploy-key --extra-files "$tmp"
    rm -rf "$tmp"

# SSH into server
ssh:
    #!/usr/bin/env bash
    ssh -i secrets/deploy-key -o StrictHostKeyChecking=no "root@$(just server-ip)"

# Rebuild from remote flake (after git push)
rebuild:
    #!/usr/bin/env bash
    ssh -i secrets/deploy-key -o StrictHostKeyChecking=no "root@$(just server-ip)" \
        'nixos-rebuild switch --refresh --flake github:brandonros/ez3proxy#ez3proxy'

# Show 3proxy logs
logs:
    #!/usr/bin/env bash
    ssh -i secrets/deploy-key -o StrictHostKeyChecking=no "root@$(just server-ip)" 'journalctl -u 3proxy -f'

# Test proxy connectivity
test user pass:
    #!/usr/bin/env bash
    server_ip=$(just server-ip)
    echo "Testing HTTP proxy..."
    curl -s -x "http://{{user}}:{{pass}}@${server_ip}:3128" https://ifconfig.me && echo
    echo "Testing SOCKS5 proxy..."
    curl -s -x "socks5://{{user}}:{{pass}}@${server_ip}:1080" https://ifconfig.me && echo

# Destroy infrastructure
destroy:
    cd terraform && terraform destroy

# Full deploy
go:
    just deploy
    just wait
    just bootstrap
    @echo "Server ready at $(just server-ip)"
