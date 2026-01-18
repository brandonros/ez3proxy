# ez3proxy

Minimal 3proxy server on NixOS using [nix-vps-template](https://github.com/brandonros/nix-vps-template).

## Deploy

```bash
# From nix-vps-template repo:
just go                                       # deploy base NixOS VPS
just rebuild brandonros/ez3proxy ez3proxy     # switch to ez3proxy
```

## Configure

Edit `flake.nix` to set proxy credentials:

```nix
proxy.users = [
  "users myuser:CL:mypassword"
];
```

## Test

```bash
curl -x "http://user:pass@SERVER_IP:3128" https://ifconfig.me
curl -x "socks5://user:pass@SERVER_IP:1080" https://ifconfig.me
```
