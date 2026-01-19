# ez3proxy

Minimal 3proxy server on NixOS using [nix-vps-template](https://github.com/brandonros/nix-vps-template).

## Deploy

```bash
# From nix-vps-template repo:
just go                                       # deploy base NixOS VPS
just rebuild brandonros/ez3proxy              # switch to ez3proxy
```

## Configure

Edit `flake.nix` to set proxy credentials:

```nix
proxy.users = [
  "users testuser:CL:testpass123"
];
```

## Test

```bash
curl -x "http://testuser:testpass123@SERVER_IP:3128" https://ifconfig.me
curl -x "socks5://testuser:testpass123@SERVER_IP:1080" https://ifconfig.me
```
