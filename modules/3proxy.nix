# 3proxy configuration using built-in nixpkgs module
{ config, lib, pkgs, ... }:

{
  # Declare the agenix secret (world-readable for DynamicUser service)
  age.secrets.proxyUsers = {
    file = ../secrets/proxy-users.age;
    mode = "0444";
  };

  services._3proxy = {
    enable = true;
    services = [
      {
        type = "proxy";
        bindPort = 3128;
        auth = [ "strong" ];
        acl = [{ rule = "allow"; users = [ "*" ]; }];
      }
      {
        type = "socks";
        bindPort = 1080;
        auth = [ "strong" ];
        acl = [{ rule = "allow"; users = [ "*" ]; }];
      }
    ];
    usersFile = config.age.secrets.proxyUsers.path;  # /run/agenix/proxyUsers
  };

  networking.firewall.allowedTCPPorts = [ 3128 1080 ];
}
