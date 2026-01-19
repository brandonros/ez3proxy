{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-vps-template.url = "github:brandonros/nix-vps-template";
  };

  outputs = { nixpkgs, nix-vps-template, ... }: {
    nixosConfigurations.ez3proxy = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nix-vps-template.nixosModules.default
        { 
          vps.sshPubKey = builtins.readFile ./assets/deploy-key.pub; 
          vps.hostname = "ez3proxy";
        }

        ./3proxy.nix
        {
          # Configure proxy users (change these!)
          proxy.users = [
            "users testuser:CL:testpass123"
          ];
        }
      ];
    };
  };
}
