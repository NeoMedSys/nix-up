{
  description = "Perseus - NixOS Laptop Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixvim.url = "github:nix-community/nixvim/nixos-25.05";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    version = "0.1.0";

    # Define a function to build a system, avoiding duplication
    mkSystem = { hasGPU ? true, devTools ? [], ... }:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs version;
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
      perseus = mkSystem {
        hasGPU = false;
        devTools = [ "python" "go" ];
      };
    };
  };
}
