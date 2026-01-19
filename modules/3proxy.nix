# 3proxy configuration
{ config, lib, pkgs, ... }:

with lib;

{
  options.proxy = {
    httpPort = mkOption {
      type = types.port;
      default = 3128;
      description = "HTTP proxy port";
    };

    socksPort = mkOption {
      type = types.port;
      default = 1080;
      description = "SOCKS5 proxy port";
    };

    users = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of user:CL:password entries";
      example = [ "users testuser:CL:testpass123" ];
    };
  };

  config = {
    services._3proxy = {
      enable = true;
      services = [
        {
          type = "proxy";
          bindPort = config.proxy.httpPort;
          auth = [ "strong" ];
          acl = [{ rule = "allow"; users = [ "*" ]; }];
        }
        {
          type = "socks";
          bindPort = config.proxy.socksPort;
          auth = [ "strong" ];
          acl = [{ rule = "allow"; users = [ "*" ]; }];
        }
      ];
      extraConfig = concatStringsSep "\n" config.proxy.users;
    };

    networking.firewall.allowedTCPPorts = [
      config.proxy.httpPort
      config.proxy.socksPort
    ];
  };
}
