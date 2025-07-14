{ config, pkgs, ... }:
{
  # Display manager configuration
  services.xserver.displayManager = {
    defaultSession = "none+i3";
    lightdm = {
      enable = true;
      greeters.gtk = {
        enable = true;
        theme = {
          package = pkgs.arc-theme;
          name = "Arc-Dark";
        };
        iconTheme = {
          package = pkgs.arc-icon-theme;
          name = "Arc";
        };
      };
    };
  };
}
