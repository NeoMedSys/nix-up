{ pkgs, userConfig ? null, ... }:
let
  # Use coordinates from userConfig or fallback to Amsterdam
  latitude = if userConfig != null then toString userConfig.latitude else "52.37";
  longitude = if userConfig != null then toString userConfig.longitude else "4.89";

  gammastep-toggle = pkgs.writeShellScriptBin "gammastep-toggle" ''
    if systemctl --user is-active --quiet gammastep.service; then
        systemctl --user stop gammastep.service
        notify-send "Gammastep Off" -i display-brightness
        echo "Gammastep Off"
    else
        systemctl --user start gammastep.service
        notify-send "Gammastep On" -i display-brightness  
        echo "Gammastep On"
    fi
  '';
in
{
  environment.systemPackages = [ gammastep-toggle ];

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
