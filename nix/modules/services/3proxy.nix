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

    usersSecretFile = mkOption {
      type = types.path;
      description = "Path to age-encrypted 3proxy users file";
    };
  };

  config = {
    age.secrets.proxyUsers = {
      file = config.proxy.usersSecretFile;
      mode = "0444";
    };

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
      usersFile = config.age.secrets.proxyUsers.path;
    };

    networking.firewall.allowedTCPPorts = [
      config.proxy.httpPort
      config.proxy.socksPort
    ];
  };
}
