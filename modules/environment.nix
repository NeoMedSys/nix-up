{ config, pkgs, lib, isLaptop ? true, hasGPU ? true, user ? "algol", userSpecifiedBrowsers ? [ "brave" ], ... }:
{
	# Use the systemd-boot EFI boot loader
	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;

	# Set time zone
	time.timeZone = "Europe/Amsterdam";

	# Internationalization
	i18n.defaultLocale = "en_US.UTF-8";
	console = {
		font = "Lat2-Terminus16";
		useXkbConfig = true;
	};

	# Configure keymap
	services.xserver = {
		enable = true;
		xkb.layout = "us";
		xkb.options = "eurosign:e,caps:escape";
		
		# Enable i3 window manager
		windowManager.i3.enable = true;
	};

	# User configuration
	users.users.${user} = {
		isNormalUser = true;
		extraGroups = [ "wheel" "networkmanager" "audio" "video" "docker" ];
		shell = pkgs.zsh;
		packages = with pkgs; [
			tree
		];
	};

	# Sudo configuration
	security.sudo.extraRules = [
		{
			users = [ user ];
			commands = [
				{
					command = "ALL";
					options = [ "NOPASSWD" "NOSETENV" ];
				}
			];
		}
	];

	# Network configuration
	networking = {
		networkmanager.enable = true;
		nameservers = [ "1.1.1.1" "1.0.0.1" "8.8.8.8" "8.8.4.4" ];
		firewall.allowedTCPPorts = [ 7775 ];
	};

	# Audio
	hardware.pulseaudio.enable = false;
	security.rtkit.enable = true;
	services.pipewire = {
		enable = true;
		alsa.enable = true;
		alsa.support32Bit = true;
		pulse.enable = true;
	};

	# System packages - only essential desktop packages here
	environment.systemPackages = with pkgs; [
		# Browsers - user specified
	] ++ map (browser: pkgs.${browser}) userSpecifiedBrowsers ++ [
		# Media & Entertainment - specific to desktop environment  
		stremio
	];

	# Environment variables
	environment.variables = {
		EDITOR = "nvim";
		VISUAL = "nvim";
	};

	# Allow unfree packages
	nixpkgs.config.allowUnfree = true;

	# Garbage collection
	nix.gc = {
		automatic = true;
		dates = "weekly";
		options = "--delete-older-than 30d";
	};

	# Performance optimizations
	nix.settings = {
		auto-optimise-store = true;
		max-jobs = "auto";
		cores = 0; # Use all available cores
	};

	# Laptop-specific optimizations
	powerManagement = lib.mkIf isLaptop {
		enable = true;
		cpuFreqGovernor = "powersave";
	};

	# Docker support
	virtualisation.docker = {
		enable = true;
		enableNvidia = hasGPU;
	};
}
