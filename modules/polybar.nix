{ config, pkgs, inputs, ... }:
{
	# Polybar configuration - imports config from polybar-config directory
	
	# Copy polybar configuration files to system
	environment.etc."polybar/config.ini".source = "${inputs.self}/polybar-config/config.ini";
	environment.etc."polybar/launch.sh" = {
		source = "${inputs.self}/polybar-config/launch.sh";
		mode = "0755";
	};
	
	# Create user polybar config directory and link files
	system.userActivationScripts.polybar = ''
		mkdir -p ~/.config/polybar
		ln -sf /etc/polybar/config.ini ~/.config/polybar/config.ini
		ln -sf /etc/polybar/launch.sh ~/.config/polybar/launch.sh
	'';
	
	# Enable polybar service for user sessions
	systemd.user.services.polybar = {
		description = "Polybar status bar";
		after = [ "graphical-session-pre.target" ];
		partOf = [ "graphical-session.target" ];
		wantedBy = [ "graphical-session.target" ];
		serviceConfig = {
			Type = "forking";
			ExecStart = "/etc/polybar/launch.sh";
			Environment = "PATH=${pkgs.polybar}/bin:${pkgs.i3}/bin:${pkgs.xorg.xrandr}/bin";
			RestartSec = 5;
			Restart = "always";
		};
	};
}
