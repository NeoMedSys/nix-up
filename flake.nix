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

    userConfig = if builtins.pathExists ./user-config.nix 
      then import ./user-config.nix 
      else builtins.trace "WARNING: Using default config. Run './perseus.sh' to customize." { 
        username = "user"; 
        hostname = "nixos"; 
        timezone = "Europe/Amsterdam";
        isLaptop = true;
        hasGPU = false;
        browsers = [ "brave" "firefox" ];
        devTools = [ "python" "go" ];
        gaming = true;
        privacy = true;
        vpn = false;
        gitName = "User";
        gitEmail = "user@example.com";
        latitude = 52.37;
        longitude = 4.89;
      };

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
