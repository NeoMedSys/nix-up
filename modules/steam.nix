{ config, pkgs, ... }:
{
	# Steam and gaming configuration
	programs.steam = {
		enable = true;
		remotePlay.openFirewall = true;
		dedicatedServer.openFirewall = true;
		gamescopeSession.enable = true;
	};
	
	# GameMode for performance optimization
        programs.gamemode = {
          enable = true;
        };	

	# 32-bit libraries for gaming compatibility
	hardware.graphics = {
		enable = true;
		enable32Bit = true;
	};
	
	# Steam-specific packages only
	environment.systemPackages = with pkgs; [
		steam
		steamcmd
		steam-run
	];
	
	# Enable controller support
	hardware.steam-hardware.enable = true;
	
	# Networking for gaming
	networking.firewall = {
		allowedTCPPorts = [ 27036 27037 ];
		allowedUDPPorts = [ 27031 27036 ];
	};
}
