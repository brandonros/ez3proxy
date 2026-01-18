{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-vps-template = {
      url = "github:brandonros/nix-vps-template";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-vps-template }:
    let
      sshPubKey = builtins.readFile ./secrets/deploy-key.pub;
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
    in {
    nixosConfigurations.ez3proxy = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit sshPubKey; };
      modules = [
        nix-vps-template.nixosModules.default
        ./nix/modules/services/3proxy.nix
        {
          vps.hostname = "ez3proxy";
          vps.passwordSecretFile = ./secrets/password-hash.age;
          proxy.usersSecretFile = ./secrets/proxy-users.age;
        }
      ];
    };

    devShells = forAllSystems (system: {
      default = nix-vps-template.devShells.${system}.default;
    });
  };
}
