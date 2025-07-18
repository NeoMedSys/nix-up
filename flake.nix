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

    mkSystem = { hasGPU, devTools ? [], ... }:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs version flakehub;
          user = "jon";
          userSpecifiedBrowsers = [ "brave" ];
          isLaptop = true;
          inherit hasGPU devTools;
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
      # Default configuration WITHOUT GPU
      perseus = mkSystem {
        hasGPU = false;
        devTools = [ "python" "go" ];
      };

      # A second configuration WITH GPU
      "perseus-gpu" = mkSystem {
        hasGPU = true;
        devTools = [ "python" "go" ];
      };
    };
  };
}
