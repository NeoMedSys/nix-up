{ pkgs, ... }:
let
  clammy = pkgs.callPackage ../pkgs/clammy.nix {};

  clammy-dbus-policy = pkgs.writeTextFile {
    name = "clammy-dbus-policy.conf";
    destination = "/share/dbus-1/system.d/clammy-policy.conf";
    text = ''
      <!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
       "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
      <busconfig>
        <policy user="*">
          <allow receive_sender="org.freedesktop.login1"
                 receive_interface="org.freedesktop.DBus.Properties"
                 receive_member="PropertiesChanged"
                 receive_path="/org/freedesktop/login1"/>
        </policy>
      </busconfig>
    '';
  };

in
{
  environment.systemPackages = [ clammy ];

  services.dbus = {
    enable = true;
    packages = [ clammy-dbus-policy ];
  };

  systemd.user.services.clammy = {
    description = "Clammy - Clamshell mode daemon for Sway";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${clammy}/bin/clammy --verbose";
      Restart = "on-failure";
      RestartSec = "5s";
    };

    path = with pkgs; [ sway swaylock-effects swayidle ];
  };
}
