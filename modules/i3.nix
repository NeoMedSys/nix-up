{ config, pkgs, ... }:
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
