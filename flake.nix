{
  description = "Perseus - NixOS Laptop Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixvim.url = "github:nix-community/nixvim/nixos-25.05";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    flakehub.url = "github:DeterminateSystems/fh";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, flakehub, ... }@inputs:
  let
    version = "1.1.0";
    userConfig = import ./user-config.nix;
    lib = nixpkgs.lib;
    
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
          ] ++ lib.optionals userConfig.vpn [
          inputs.sops-nix.nixosModules.sops
        ];
      };
  in
  {
    nixosConfigurations = {
      "${userConfig.hostname}" = mkSystem {};
    };
  };
}
