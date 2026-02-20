{
  description = "Perseus - NixOS Laptop Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixvim.url = "github:nix-community/nixvim/nixos-25.11";

    dgop.url = "github:AvengeMedia/dgop";
    dgop.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    flakehub.url = "github:DeterminateSystems/fh";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";


    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    dms.url = "github:AvengeMedia/DankMaterialShell";
    dms.inputs.nixpkgs.follows = "nixpkgs";

    danksearch.url = "github:AvengeMedia/danksearch";
    danksearch.inputs.nixpkgs.follows = "nixpkgs";

    #oisd = {
    #  url = "https://big.oisd.nl/domainswild";
    #  flake = false;
    #};

    thunderbird-catppuccin.url = "github:catppuccin/thunderbird";
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
    version = "1.3.0";
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
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs userConfig; };
            };
          }
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
