{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-vps-template.url = "github:brandonros/nix-vps-template";
  };

  outputs = { nixpkgs, nix-vps-template, ... }: {
    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nix-vps-template.nixosModules.default
        {
          vps.sshPubKey = builtins.readFile ./keys/deploy-key.pub;
          vps.hostname = "ez3proxy";
        }
        ./modules/3proxy.nix
        {
          proxy.users = [
            "users testuser:CL:testpass123"
          ];
        }
      ];
    };
  };
}
