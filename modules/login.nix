{ config, pkgs, ... }:
{
  # Enable X11 and display manager
  services.xserver = {
    enable = true;
    
    # Display manager - lightweight and works well with i3
    displayManager.lightdm = {
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
        cursorTheme = {
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Classic";
        };
      };
    };
  };
  
