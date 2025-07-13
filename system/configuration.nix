{ config, lib, pkgs, inputs, isLaptop, hasGPU, user, userSpecifiedBrowsers, ... }:
{
	imports = [
		# Hardware and disk configuration
		"${inputs.self}/system/hardware-configuration.nix"
		"${inputs.self}/system/disko-config.nix"
		
		# Core system modules
		"${inputs.self}/modules/environment.nix"
		"${inputs.self}/modules/system-packages.nix"
		"${inputs.self}/modules/zsh.nix"
		"${inputs.self}/modules/nixvim.nix"
		"${inputs.self}/modules/ssh-config.nix"
		
		# Desktop environment
		"${inputs.self}/modules/i3.nix"
		"${inputs.self}/modules/polybar.nix"
		
		# Gaming and graphics (conditional)
		"${inputs.self}/modules/steam.nix"
	] ++ lib.optionals hasGPU [
		"${inputs.self}/modules/nvidia.nix"
	] ++ [
		# VPN
		"${inputs.self}/modules/expressvpn.nix"
	];

	# System identification
	networking.hostName = "perseus";

	# Enable flakes
	nix.settings.experimental-features = [ "nix-command" "flakes" ];

	# System state version - NEVER change this after initial install
	system.stateVersion = "25.05";
}
