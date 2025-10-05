{ pkgs, ... }:
let
  clammy = pkgs.callPackage ../pkgs/clammy.nix {};
in
{
  # Install clammy package
  environment.systemPackages = [ clammy ];

  # User systemd service (started manually by Sway, not auto-started)
  systemd.user.services.clammy = {
    description = "Clammy - Clamshell mode daemon for Sway";
    documentation = [ "https://github.com/NeoMedSys/perseus" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${clammy}/bin/clammy --verbose"; # Remove --verbose after testing
      Restart = "on-failure";
      RestartSec = "5s";

      # Security hardening
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      NoNewPrivileges = true;

      Environment = [
        "PATH=${pkgs.swayidle}/bin:${pkgs.sway}/bin:${pkgs.systemd}/bin:${pkgs.swaylock-effects}/bin:/run/current-system/sw/bin"
      ];
    };
  };
}
