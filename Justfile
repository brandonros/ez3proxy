#!/usr/bin/env just --justfile

# Import base infrastructure recipes from nix-vps-template
import? '.just-base.just'

set shell := ["bash", "-euo", "pipefail", "-c"]

# === Project Config ===

flake_target := ".#ez3proxy"
github_repo := "brandonros/ez3proxy"

# === Overrides ===

# Create proxy-specific secrets (extends base)
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

# === Service ===

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
