{ config, pkgs, inputs, user ? "algol", ... }:
{
	# i3 window manager configuration
	services.xserver = {
		enable = true;
		windowManager.i3 = {
			enable = true;
			extraPackages = with pkgs; [
				dmenu
				i3status
				i3lock
				i3blocks
				feh
				rofi
			];
		};
		displayManager = {
			defaultSession = "none+i3";
			lightdm.enable = true;
		};
	};
	
	# Copy i3 configuration files to system
	environment.etc."i3/config".source = "${inputs.self}/i3-config/config";
	
	# Create user i3 config directory and link files
	system.userActivationScripts.i3 = ''
		mkdir -p ~/.config/i3
		ln -sf /etc/i3/config ~/.config/i3/config
	'';
	
	# Enable compositor for transparency effects
	services.picom = {
		enable = true;
		fade = true;
		shadow = true;
		fadeSteps = [ 0.028 0.03 ];
		fadeDelta = 10;
		shadowOpacity = 0.75;
	};
}
