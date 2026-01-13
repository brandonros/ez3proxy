{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, disko, agenix, impermanence }:
    let
      sshPubKey = builtins.readFile ./secrets/deploy-key.pub;
      # Systems to provide devShells for
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
    in {
    nixosConfigurations.ez3proxy = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit sshPubKey; };
      modules = [
        disko.nixosModules.disko
        agenix.nixosModules.default
        impermanence.nixosModules.impermanence
        ./modules/vultr-base.nix
        ./modules/3proxy.nix
        { vultr.hostname = "ez3proxy"; }
      ];
    };

    devShells = forAllSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.mkShell {
          packages = [
            pkgs.opentofu  # open-source terraform fork
            pkgs.age
            pkgs.just
            pkgs.jq
            pkgs.curl
          ];
          shellHook = ''
            alias terraform=tofu
            echo "ez3proxy dev shell"
            echo "  tofu: $(tofu version -json | jq -r .terraform_version)"
            echo "  just: $(just --version)"
            echo "  age:  $(age --version)"
          '';
        };
      });
  };
}
