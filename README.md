# ez3proxy
Easy to deploy 3proxy setup

## Quick start

Requires [just](https://github.com/casey/just). Run `just` to see all commands.

```bash
$ just
Available recipes:
    default   # Default recipe
    deploy    # Deploy infrastructure
    destroy   # Destroy infrastructure
    go        # Full deploy: provision + wait
    logs      # Show logs from server
    server-ip # Get server IP from terraform
    ssh       # SSH into server
    update    # Update and restart app on server
    wait      # Wait for server to be available
```

## How to use

```bash
# http proxy
curl -x http://myuser:mypassword@96.30.192.125:3128 https://ifconfig.me

# socks
curl -x socks5://myuser:mypassword@96.30.192.125:1080 https://ifconfig.me
```
