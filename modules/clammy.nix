{ pkgs, lib, ... }:
let
  clammy = pkgs.callPackage ../pkgs/clammy.nix {};

  clammy-start-script = pkgs.writeShellScriptBin "clammy-start-sway" ''
    #!${pkgs.bash}/bin/bash
    systemctl --user import-environment --wait \
      WAYLAND_DISPLAY \
      SWAYSOCK \
      XDG_RUNTIME_DIR \
      DBUS_SESSION_BUS_ADDRESS \
      XDG_CURRENT_DESKTOP \
      XDG_SESSION_TYPE \
      XDG_SESSION_DESKTOP \
      XDG_DATA_DIRS \
      XDG_CONFIG_DIRS
      
    systemctl --user restart clammy.service
  '';

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
    description = "Clammy - Clamshell mode daemon for Sway";
    
    # No auto-start. Sway config will start it.
    
    serviceConfig = {
      Type = "simple";
      ExecStart = "${clammy}/bin/clammy --verbose";
      Restart = "on-failure";
      RestartSec = "5s";

      # This is still needed for the 'swayidle' thread.
      Environment = [
        "PATH=${lib.makeBinPath [
          pkgs.swayidle
          pkgs.coreutils
        ]}"
      ];
    };
  };
}
