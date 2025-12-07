{
  description = "Perseus - NixOS Laptop Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixvim.url = "github:nix-community/nixvim/nixos-25.11";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    flakehub.url = "github:DeterminateSystems/fh";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    thunderbird-catppuccin.url = "github:catppuccin/thunderbird";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    catppuccin-firefox = {
      url = "github:catppuccin/firefox";
      flake = false;
    };
    betterfox = {
      url = "github:yokoffing/Betterfox";
      flake = false;
    };
  };

  outputs = { nixpkgs, flakehub, home-manager, ... }@inputs:
  let
    version = "1.2.0"; 
    userConfig = import ./user-config.nix;
    lib = nixpkgs.lib;

    mkSystem = { ... }:
      nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs version flakehub userConfig;
        };
        modules = [
          ./system/configuration.nix
          inputs.nixvim.nixosModules.nixvim
          inputs.disko.nixosModules.disko
          home-manager.nixosModules.home-manager
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
