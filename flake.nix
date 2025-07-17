{
	description = "Perseus v0.1.0 - NixOS Laptop Configuration";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
		nixvim.url = "github:nix-community/nixvim/nixos-25.05";
		disko.url = "github:nix-community/disko";
		disko.inputs.nixpkgs.follows = "nixpkgs";
	};

	outputs = { self, nixpkgs, nixvim, disko, ... }@inputs: let
		# Helper function to get environment variables with defaults
		getEnvWithDefault = varName: defaultValue:
			if builtins.getEnv varName != ""
			then builtins.getEnv varName
			else defaultValue;
		
		# Parse comma-separated browsers
		parseBrowsers = browserString:
			if browserString == "" then [ "brave" ]
			else builtins.filter (x: x != "") (nixpkgs.lib.splitString "," browserString);
		
		# Parse comma-separated dev tools
		parseDevTools = devToolsString:
			if devToolsString == "" then [ ]
			else builtins.filter (x: x != "") (nixpkgs.lib.splitString "," devToolsString);
		
		# Parse boolean environment variables
		parseBool = boolString:
			if boolString == "false" then false else true;
		
	in {
		nixosConfigurations = {
			# The one and only configuration for your machine
			perseus = nixpkgs.lib.nixosSystem {
				system = "x86_64-linux";
				specialArgs = {
					inherit inputs;
					user = getEnvWithDefault "PERSEUS_USER" "jon";
					userSpecifiedBrowsers = parseBrowsers (getEnvWithDefault "PERSEUS_BROWSERS" "brave");
					devTools = parseDevTools (getEnvWithDefault "PERSEUS_DEV_TOOLS" "");
					isLaptop = parseBool (getEnvWithDefault "PERSEUS_LAPTOP" "true");
					hasGPU = parseBool (getEnvWithDefault "PERSEUS_GPU" "false"); # Defaulting to true
				};
				modules = [
					./system/configuration.nix
					nixvim.nixosModules.nixvim
					disko.nixosModules.disko
				];
			};
		};
	};
}
