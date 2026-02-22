{ pkgs, lib, inputs, ... }:
let
  clammy = pkgs.callPackage ../../packages/clammy.nix { inherit inputs; };

  clammy-start-script = pkgs.writeShellScriptBin "clammy-start-session" ''
    #!${pkgs.bash}/bin/bash

    # Wait for niri to fully initialize
    ${pkgs.coreutils}/bin/sleep 2

    # Import environment and wait for completion
    ${pkgs.systemd}/bin/systemctl --user import-environment --wait \
      WAYLAND_DISPLAY \
      XDG_RUNTIME_DIR \
      DBUS_SESSION_BUS_ADDRESS \
      NIRI_SOCKET

    ${pkgs.systemd}/bin/systemctl --user restart clammy.service
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
    partOf = [ "graphical-session.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${clammy}/bin/clammy";
      Restart = "on-failure";
      RestartSec = "5s";
      PassEnvironment = "WAYLAND_DISPLAY NIRI_SOCKET XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS";
      Environment = "CLAMMY_IDLE_TIMEOUT_S=60 CLAMMY_SLEEP_TIMEOUT_S=60";
    };
  };
}
