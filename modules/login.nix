{ pkgs, inputs, ... }:
{
  # General display manager settings
  services.displayManager.defaultSession = "none+i3";

  # Specific settings for the LightDM GTK Greeter
  services.xserver.displayManager.lightdm = {
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
      # All custom settings go in extraConfig
      extraConfig = ''
        background=${inputs.self}/assets/wallpaper.png
        font-name=MesloLGS NF 11
      '';
    };
  };
}
