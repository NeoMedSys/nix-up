{ config, pkgs, lib, ... }:
{
	# Gammastep blue light filter service (Wayland native)
	services.gammastep = {
		enable = true;
		temperature = {
			day = 6500;    # Normal daylight color
			night = 3500;  # Warm evening color
		};
		brightness = {
			day = "1.0";
			night = "0.9";
		};
	};
	
	# Amsterdam coordinates (adjust to your location)
	location = {
		latitude = 52.37;
		longitude = 4.89;
	};
	
	environment.systemPackages = with pkgs; [
		gammastep
	];
	
	# Create a custom gammastep config
	environment.etc."gammastep.conf" = {
		text = ''
			[gammastep]
			temp-day=6500
			temp-night=3500
			transition=1
			brightness-day=1.0
			brightness-night=0.9
			location-provider=manual
			adjustment-method=wayland
			dawn-time=06:00-07:00
			dusk-time=22:00-23:00
			
			[manual]
			lat=52.37
			lon=4.89
		'';
	};
}
