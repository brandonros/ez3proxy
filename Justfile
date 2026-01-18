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

# Create and encrypt secrets in one step (no plaintext touches disk)
secrets-init:
    #!/usr/bin/env bash
    mkdir -p secrets
    host_pub=$(cat secrets/host-key.pub)

    if [ ! -f secrets/password-hash.age ]; then
        read -s -p "Enter system password: " password
        echo
        nix-shell -p mkpasswd --run "mkpasswd -m sha-512 '$password'" \
            | age -r "$host_pub" -o secrets/password-hash.age
        echo "Created secrets/password-hash.age"
    fi

    if [ ! -f secrets/proxy-users.age ]; then
        read -p "Enter proxy username: " proxy_user
        read -s -p "Enter proxy password: " proxy_pass
        echo
        echo "users ${proxy_user}:CL:${proxy_pass}" \
            | age -r "$host_pub" -o secrets/proxy-users.age
        echo "Created secrets/proxy-users.age"
    fi

# Get server IP from tofu output
server-ip:
    @cd terraform && tofu output -raw server_ipv4 2>/dev/null

# Deploy infrastructure
deploy:
    cd terraform && tofu init -upgrade && tofu apply

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
    nix run github:nix-community/nixos-anywhere -- \
        --build-on-remote \
        --flake .#ez3proxy \
        --target-host "root@${server_ip}" \
        -i secrets/deploy-key \
        --extra-files "$tmp"
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
    cd terraform && tofu destroy

# Full deploy
go:
    just deploy
    just wait
    just bootstrap
    @echo "Server ready at $(just server-ip)"
