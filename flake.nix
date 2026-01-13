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
  };
}
