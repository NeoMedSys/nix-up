{ pkgs, userConfig ? null, ... }:
let
  # Use coordinates from userConfig or fallback to Amsterdam
  latitude = if userConfig != null then toString userConfig.latitude else "52.37";
  longitude = if userConfig != null then toString userConfig.longitude else "4.89";
in
{
  # Gammastep blue light filter service (Wayland native)
  systemd.user.services.gammastep = {
    description = "Gammastep blue light filter";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.gammastep}/bin/gammastep -l 52.37:4.89 -t 6500:3500 -b 1.0:0.9 -P -v";
      Restart = "always";
      RestartSec = 3;
    };
  };
  
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
      lat=${latitude}
      lon=${longitude}
    '';
  };
}
