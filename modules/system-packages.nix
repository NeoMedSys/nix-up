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
		
		# Window manager tools (moved from i3.nix)
		i3
		i3status
		i3lock
		i3blocks
		dmenu
		rofi
		feh
		picom
		nitrogen
		arandr
		polybar
		
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
		
		# Zsh and theme
		zsh
		zsh-powerlevel10k
		zsh-syntax-highlighting
		
		# Fonts
		fira-code
		meslo-lgs-nf
		font-awesome
		dejavu_fonts
		liberation_ttf
		fira-code-symbols
	];
}
