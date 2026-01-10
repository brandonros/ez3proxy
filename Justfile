#!/usr/bin/env just --justfile

set shell := ["bash", "-euo", "pipefail", "-c"]

# Default recipe
default:
    @just --list

# Get server IP from terraform
server-ip:
    @cd terraform && terraform output -raw server_ipv4 2>/dev/null

# Deploy infrastructure
deploy:
    cd terraform && terraform init -upgrade && terraform apply

# Wait for server to be available
wait:
    #!/usr/bin/env bash
    server_ip=$(just server-ip)
    echo "Waiting for SSH on ${server_ip}..."
    while ! nc -z "${server_ip}" 22 2>/dev/null; do
        sleep 2
    done
    echo "SSH available"

    echo "Waiting for cloud-init to complete..."
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "user@${server_ip}" \
        'cloud-init status --wait' || true
    echo "Server ready"

# SSH into server
ssh:
    #!/usr/bin/env bash
    server_ip=$(just server-ip)
    ssh -o StrictHostKeyChecking=no "user@${server_ip}"

# Update and restart app on server
update:
    #!/usr/bin/env bash
    server_ip=$(just server-ip)
    ssh -o StrictHostKeyChecking=no "user@${server_ip}" '\
        cd ~/ez3proxy && \
        git pull && \
        sudo systemctl restart ez3proxy && \
        sudo systemctl status ez3proxy --no-pager'

# Show logs from server
logs:
    #!/usr/bin/env bash
    server_ip=$(just server-ip)
    ssh -o StrictHostKeyChecking=no "user@${server_ip}" \
        'sudo journalctl -u ez3proxy -f'

# Destroy infrastructure
destroy:
    cd terraform && terraform destroy

# Full deploy: provision + wait
go:
    just deploy
    just wait
    @echo "Server ready at $(just server-ip)"
