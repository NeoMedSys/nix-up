{ config, pkgs, ... }:
{
	# ExpressVPN configuration
	# Note: ExpressVPN requires manual download from their website
	
	# Enable OpenVPN service
	services.openvpn.servers = {
		# Example ExpressVPN configuration
		# Replace with actual .ovpn files from ExpressVPN
		# expressvpn = {
		#   config = '' config /path/to/expressvpn.ovpn '';
		#   autoStart = false;
		# };
	};
	
	# NetworkManager OpenVPN plugin
	networking.networkmanager.plugins = with pkgs; [
		networkmanager-openvpn
	];
	
	# Firewall rules for VPN
	networking.firewall = {
		# Allow OpenVPN traffic
		allowedUDPPorts = [ 1194 ];
		allowedTCPPorts = [ 443 1723 ];
	};
	
	# DNS configuration for VPN
	networking.resolvconf.enable = true;
	
	# Create a script for manual ExpressVPN installation
	environment.etc."expressvpn-install.sh" = {
		text = ''
			#!/bin/bash
			echo "ExpressVPN Installation Instructions:"
			echo "1. Download ExpressVPN Linux package from https://www.expressvpn.com/support/vpn-setup/app-for-linux/"
			echo "2. Install the .deb package manually with alien or extract and install"
			echo "3. Run 'expressvpn activate' with your activation code"
			echo "4. Use 'expressvpn connect' to connect to VPN"
			echo ""
			echo "Alternative: Use OpenVPN with ExpressVPN .ovpn files"
			echo "Download .ovpn files from ExpressVPN dashboard and use with NetworkManager"
		'';
		mode = "0755";
	};
}
