{ pkgs, lib, ... }:
let
  clammy = pkgs.callPackage ../pkgs/clammy.nix {};

  # RENAMED: This is now a generic session script.
  clammy-start-script = pkgs.writeShellScriptBin "clammy-start-session" ''
    #!${pkgs.bash}/bin/bash
    # Imports the *minimal* environment clammy needs to connect
    # to the Wayland compositor and D-Bus.
    systemctl --user import-environment --wait \
      WAYLAND_DISPLAY \
      XDG_RUNTIME_DIR \
      DBUS_SESSION_BUS_ADDRESS \
      NIRI_SOCKET

    systemctl --user restart clammy.service
  '';

  # (clammy-dbus-policy remains the same)
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
  environment.systemPackages = [ clammy clammy-start-script ];

  services.dbus = {
    enable = true;
    packages = [ clammy-dbus-policy ];
  };

  systemd.user.services.clammy = {
    description = "Clammy - Clamshell mode daemon for Wayland";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${clammy}/bin/clammy --verbose";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
