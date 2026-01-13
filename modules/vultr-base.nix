# Vultr VPS base configuration
{ config, lib, pkgs, sshPubKey, ... }:

with lib;

{
  options.vultr = {
    hostname = mkOption {
      type = types.str;
      default = "nixos";
      description = "System hostname";
    };
  };

  config = {
    # Tell agenix where to find the host key (before impermanence bind mount)
    age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

    # Agenix secret for password hash
    age.secrets.passwordHash = {
      file = ../secrets/password-hash.age;
      owner = "root";
      mode = "0400";
    };

    # Disk configuration (single disk /dev/vda, UEFI boot)
    # Root is tmpfs (ephemeral), persistent data on /persist
    disko.devices = {
      disk.main = {
        device = "/dev/vda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            nix = {
              size = "20G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/nix";
              };
            };
            persist = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/persist";
              };
            };
          };
        };
      };
      nodev."/" = {
        fsType = "tmpfs";
        mountOptions = [ "defaults" "size=512M" "mode=755" ];
      };
    };

    # Ensure these are available early for boot
    fileSystems."/persist".neededForBoot = true;
    fileSystems."/nix".neededForBoot = true;

    # Impermanence - declare what survives reboots
    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/var/lib/fail2ban"
        "/etc/ssh"  # SSH host keys (needed for agenix decryption)
      ];
      files = [
        "/etc/machine-id"
      ];
    };

    # Boot (UEFI with systemd-boot)
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Virtio drivers for Vultr/KVM
    boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_blk" "virtio_scsi" "ahci" "sd_mod" ];

    # Networking
    networking.hostName = config.vultr.hostname;
    networking.useDHCP = true;
    networking.firewall.allowedTCPPorts = [ 22 ];

    # Root user
    users.users.root = {
      openssh.authorizedKeys.keys = [ sshPubKey ];
      hashedPasswordFile = config.age.secrets.passwordHash.path;
    };

    # Normal user with sudo
    users.users.user = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ sshPubKey ];
      hashedPasswordFile = config.age.secrets.passwordHash.path;
    };
    security.sudo.wheelNeedsPassword = false;

    # SSH
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
      };
    };

    # Security
    services.fail2ban.enable = true;

    # Auto-upgrades
    system.autoUpgrade = {
      enable = true;
      allowReboot = false;
    };

    # System
    system.stateVersion = "25.11";
  };
}
