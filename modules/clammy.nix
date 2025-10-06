{ pkgs, ... }:
let
  clammy = pkgs.callPackage ../pkgs/clammy.nix {};
in
{
  # Install clammy package
  environment.systemPackages = [ clammy ];
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

    path = with pkgs; [ sway swaylock-effects ];
  };
}
