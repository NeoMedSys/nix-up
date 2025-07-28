{
  description = "Perseus - NixOS Laptop Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixvim.url = "github:nix-community/nixvim/nixos-25.05";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    flakehub.url = "github:DeterminateSystems/fh";
  };

  outputs = { self, nixpkgs, flakehub, ... }@inputs:
  let
    version = "1.0.0";

    # Import user configuration
    userConfig = import ./user-config.nix;

    mkSystem = { ... }:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs version flakehub userConfig;
        };
        modules = [
          ./system/configuration.nix
          inputs.nixvim.nixosModules.nixvim
          inputs.disko.nixosModules.disko
        ];
      };
  in
  {
    nixosConfigurations = {
      # Use hostname from config
      "${userConfig.hostname}" = mkSystem {};
    };
  };
}
