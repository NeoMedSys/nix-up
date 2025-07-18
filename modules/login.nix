{ config, pkgs, ... }:
{
  services.displayManager.defaultSession = "none+i3";
  # Display manager configuration
  services.xserver.displayManager = {
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
