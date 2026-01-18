# ez3proxy

3proxy on NixOS, deployed to Vultr with one command.

Built on [nix-vps-template](https://github.com/brandonros/nix-vps-template).

## Quick Start

```bash
nix develop
just init           # generates keys, prompts for passwords
export VULTR_API_KEY="your-key"
just go             # provisions VM, installs NixOS, starts 3proxy
```

## Usage

```bash
# Test proxy
just test myuser mypassword

# Or manually
curl -x http://user:pass@<ip>:3128 https://ifconfig.me
curl -x socks5://user:pass@<ip>:1080 https://ifconfig.me

# View logs
just logs

# SSH access
just ssh

# Update after git push
just rebuild

# Tear down
just destroy
```

## Configuration

Edit [flake.nix](flake.nix) to customize:

```nix
{
  vps.hostname = "ez3proxy";
  vps.passwordSecretFile = ./secrets/password-hash.age;
  proxy.usersSecretFile = ./secrets/proxy-users.age;
  # proxy.httpPort = 3128;
  # proxy.socksPort = 1080;
}
```

Edit [terraform/main.tf](terraform/main.tf) for infrastructure (region, plan, etc).
