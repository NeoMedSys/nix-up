{ config, pkgs, lib, ... }:
{
	# Redshift blue light filter service
	services.redshift = {
		enable = true;
		temperature = {
			day = 6500;    # Normal daylight color
			night = 3500;  # Warm evening color
		};
		brightness = {
			day = "1.0";
			night = "0.9";
		};
		# Start transitioning at 10 PM, fully warm by 11 PM
		dawnTime = "6:00-7:00";
		duskTime = "22:00-23:00";  # 10 PM to 11 PM
	};
	
	# Amsterdam coordinates (adjust to your location)
	location = {
		latitude = 52.37;
		longitude = 4.89;
	};
	
	# Install redshift packages
	environment.systemPackages = with pkgs; [
		redshift
	];
	
	# Disable the default systemd service since we'll control it manually
	systemd.services.redshift.enable = false;
	systemd.user.services.redshift.enable = false;
	
	# Create a custom redshift config
	environment.etc."redshift.conf" = {
		text = ''
			[redshift]
			temp-day=6500
			temp-night=3500
			transition=1
			brightness-day=1.0
			brightness-night=0.9
			location-provider=manual
			adjustment-method=randr
			
			[manual]
			lat=52.37
			lon=4.89
		'';
	};
}
