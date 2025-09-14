# flake.nix (Simplified and Corrected)
{
  description = "Perseus - NixOS Laptop Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixvim.url = "github:nix-community/nixvim/nixos-25.05";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    flakehub.url = "github:DeterminateSystems/fh";
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    version = "1.0.0";
    user-configuration = import ./user-config.nix;
  in
  {
    nixosConfigurations.perseus = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        { _module.args.userConfig = user-configuration; }
        { _module.args.inputs = inputs; }
        ./system/configuration.nix
      ];
    };
  };
}
