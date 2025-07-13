{
	description = "
	Perseus v0.1.0 - NixOS Laptop Configuration
	------------------------------------------
	
	Complete NixOS setup for development and gaming laptop.
	Includes i3, polybar, steam, NVIDIA drivers, and dev tools.
	Use kernel 6.12 LTS or 6.14 for Nvidia compatibility.
	
	Configurable via environment variables:
	- PERSEUS_USER: username (default: 'algol')
	- PERSEUS_BROWSERS: comma-separated browsers (default: 'brave')
	- PERSEUS_DEV_TOOLS: comma-separated dev tools (default: '', options: python,go,rust,nextjs)
	- PERSEUS_LAPTOP: enable laptop optimizations (default: 'true')
	- PERSEUS_GPU: enable NVIDIA support (default: 'true')
	
	Example usage:
	PERSEUS_USER=alice PERSEUS_BROWSERS=firefox,chromium PERSEUS_DEV_TOOLS=python,rust,nextjs nixos-anywhere --flake github:user/perseus#perseus root@target
	";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
		nixvim.url = "github:nix-community/nixvim/nixos-25.05";
		disko.url = "github:nix-community/disko";
		disko.inputs.nixpkgs.follows = "nixpkgs";
	};

	outputs = { self, nixpkgs, nixvim, disko, ... }@inputs: let
		pkgs = import nixpkgs { system = "x86_64-linux"; };
		
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
		
		# Get configuration from environment variables
		user = getEnvWithDefault "PERSEUS_USER" "algol";
		browsersString = getEnvWithDefault "PERSEUS_BROWSERS" "brave";
		devToolsString = getEnvWithDefault "PERSEUS_DEV_TOOLS" "";
		userSpecifiedBrowsers = parseBrowsers browsersString;
		devTools = parseDevTools devToolsString;
		isLaptop = parseBool (getEnvWithDefault "PERSEUS_LAPTOP" "true");
		hasGPU = parseBool (getEnvWithDefault "PERSEUS_GPU" "true");
		
	in {
		nixosConfigurations = {
			# Main Perseus configuration with environment variable support
			perseus = nixpkgs.lib.nixosSystem {
				system = "x86_64-linux";
				specialArgs = { 
					inherit inputs user userSpecifiedBrowsers devTools isLaptop hasGPU;
				};
				modules = [
					./system/configuration.nix
					nixvim.nixosModules.nixvim
					disko.nixosModules.disko
				];
			};
			
			# Static configuration examples for common setups
			perseus-desktop = nixpkgs.lib.nixosSystem {
				system = "x86_64-linux";
				specialArgs = { 
					inherit inputs; 
					user = "algol";
					userSpecifiedBrowsers = [ "brave" ];
					devTools = [ "python" "go" "rust" "nextjs" ];  # Full dev setup
					isLaptop = false;  # Desktop optimizations
					hasGPU = true;
				};
				modules = [
					./system/configuration.nix
					nixvim.nixosModules.nixvim
					disko.nixosModules.disko
				];
			};
			
			perseus-server = nixpkgs.lib.nixosSystem {
				system = "x86_64-linux";
				specialArgs = { 
					inherit inputs; 
					user = "algol";
					userSpecifiedBrowsers = [ ];  # No browsers for server
					devTools = [ "python" "go" ];  # Server-side development only
					isLaptop = false;
					hasGPU = false;  # No GPU for server
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
