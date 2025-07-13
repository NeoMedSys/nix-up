# Initial configuration for NixOS minimal ISO bootstrap
# Copy this to /mnt/etc/nixos/configuration.nix during installation
# CUSTOMIZE: Change username below to match your flake.nix user setting

{ config, pkgs, ... }:

{
	imports = [
		./hardware-configuration.nix
	];

	# Enable flakes for the initial setup
	nix.settings.experimental-features = [ "nix-command" "flakes" ];

	# Use the systemd-boot EFI boot loader
	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;

	# Networking
	networking.hostName = "perseus";
	networking.networkmanager.enable = true;

	# Set your time zone
	time.timeZone = "Europe/Amsterdam";

	# Select internationalisation properties
	i18n.defaultLocale = "en_US.UTF-8";
	console = {
		font = "Lat2-Terminus16";
		useXkbConfig = true;
	};

	# Configure keymap
	services.xserver.xkb.layout = "us";
	services.xserver.xkb.options = "eurosign:e,caps:escape";

	# Define user account - CHANGE "algol" to your username if desired
	users.users.algol = {
		isNormalUser = true;
		extraGroups = [ "wheel" "networkmanager" ];
		shell = pkgs.bash;  # Start with bash, will switch to zsh later
	};

	# Enable sudo without password for initial setup
	security.sudo.wheelNeedsPassword = false;

	# Essential packages for initial setup
	environment.systemPackages = with pkgs; [
		vim
		git
		curl
		wget
		htop
	];

	# Enable SSH for remote management (optional)
	services.openssh = {
		enable = true;
		settings = {
			PermitRootLogin = "no";
			PasswordAuthentication = true;  # Allow during setup
		};
	};

	# Allow unfree packages
	nixpkgs.config.allowUnfree = true;

	# This value determines the NixOS release
	system.stateVersion = "25.05";
}
