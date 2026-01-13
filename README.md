# ez3proxy

NixOS-based 3proxy deployment on Vultr.

## How it works

1. Terraform provisions a Debian VM on Vultr
2. nixos-anywhere converts it to NixOS
3. 3proxy runs via the built-in nixpkgs module
4. Secrets are [age](https://github.com/FiloSottile/age)-encrypted and decrypted on the server via [agenix](https://github.com/ryantm/agenix)
5. Root filesystem is ephemeral (tmpfs) via [impermanence](https://github.com/nix-community/impermanence) - reboots wipe everything not explicitly persisted

## Prerequisites

- [just](https://github.com/casey/just)
- [Terraform](https://www.terraform.io/)
- [Nix](https://nixos.org/download.html) with flakes enabled

## Quick start

```bash
# One-time setup (prompts for passwords interactively)
just init

# Set your Vultr API key and deploy
export VULTR_API_KEY="your-api-key"
just go
```

## Commands

```bash
$ just
Available recipes:
    bootstrap    # Bootstrap NixOS (destructive - reformats disks)
    default      # Default recipe
    deploy       # Deploy infrastructure
    destroy      # Destroy infrastructure
    encrypt      # Encrypt secrets with age
    go           # Full deploy
    hostkeygen   # Generate SSH host key (for agenix)
    init         # One-time setup: generate keys and create secrets
    keygen       # Generate SSH deploy key
    logs         # Show 3proxy logs
    rebuild      # Rebuild from remote flake (after git push)
    secrets-init # Create secrets files interactively
    server-ip    # Get server IP from terraform
    ssh          # SSH into server
    wait         # Wait for SSH
```

## Usage

```bash
# HTTP proxy
curl -x http://myuser:mypassword@<server-ip>:3128 https://ifconfig.me

# SOCKS5
curl -x socks5://myuser:mypassword@<server-ip>:1080 https://ifconfig.me
```
