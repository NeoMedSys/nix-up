{ lib, pkgs, ... }:
{
	# Global software packages to install
	environment.systemPackages = with pkgs; [
		# Development tools
		curl
		git
		gcc
		openssl
		
		# System utilities
		htop
		jq
		fastfetch
		fzf
		ripgrep
		# tmux
		xsel
		
		# Desktop utilities (moved from other modules)
		brightnessctl
		playerctl
		pavucontrol
		networkmanagerapplet
                xorg.xrandr
		
		# Window manager tools (moved from i3.nix)
		i3
		i3status-rust
		i3lock
		i3blocks
		dmenu
		rofi
		feh
		picom
		nitrogen
		arandr
		
		# Network and Bluetooth GUI tools
		networkmanagerapplet
		overskride  # Modern Rust+GTK4 Bluetooth manager
		
		# Screenshot tools
		scrot
		flameshot
		
		# Terminal emulator
		alacritty
		
		# Gaming utilities (moved from steam.nix)
		gamemode
		gamescope
		mangohud
		antimicrox
		
		# VPN and network tools (moved from expressvpn.nix)
		#openvpn
		#networkmanager-openvpn
		dig
		#wget
		
		# Bluetooth tools
		bluez
		bluez-tools
		
		# Zsh and theme
		zsh
		zsh-powerlevel10k
		zsh-syntax-highlighting
		
		# Fonts
		fira-code
		meslo-lgs-nf
		font-awesome_6
		dejavu_fonts
		liberation_ttf
		fira-code-symbols
	];

  	# This registers the fonts with your system so applications can find them.
	fonts.packages = with pkgs; [
		fira-code
		meslo-lgs-nf
		font-awesome_6
		dejavu_fonts
		liberation_ttf
		fira-code-symbols
	];
}
