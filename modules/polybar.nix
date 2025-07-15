{ config, pkgs, inputs, ... }:
{
	# Polybar configuration - imports config from polybar-config directory
	
	# Copy polybar configuration files to system
	environment.etc."polybar/config.ini".source = "${inputs.self}/polybar-config/config.ini";
	environment.etc."polybar/launch.sh" = {
		source = "${inputs.self}/polybar-config/launch.sh";
		mode = "0755";
	};
	
	# Copy polybar scripts
	environment.etc."polybar/scripts/wifi.sh" = {
		source = "${inputs.self}/polybar-config/scripts/wifi.sh";
		mode = "0755";
	};
	environment.etc."polybar/scripts/bluetooth.sh" = {
		source = "${inputs.self}/polybar-config/scripts/bluetooth.sh";
		mode = "0755";
	};
	
	# Create user polybar config directory and link files
	system.userActivationScripts.polybar = ''
		mkdir -p ~/.config/polybar/scripts
		ln -sf /etc/polybar/config.ini ~/.config/polybar/config.ini
		ln -sf /etc/polybar/launch.sh ~/.config/polybar/launch.sh
		ln -sf /etc/polybar/scripts/wifi.sh ~/.config/polybar/scripts/wifi.sh
		ln -sf /etc/polybar/scripts/bluetooth.sh ~/.config/polybar/scripts/bluetooth.sh
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
			Environment = "PATH=${pkgs.polybar}/bin:${pkgs.i3}/bin:${pkgs.xorg.xrandr}/bin:${pkgs.networkmanager}/bin:${pkgs.bluez}/bin";
			RestartSec = 5;
			Restart = "always";
		};
	};
}
