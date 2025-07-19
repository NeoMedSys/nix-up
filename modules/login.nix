services.xserver.displayManager.lightdm = {
  enable = true;
  greeters.gtk = {
    enable = true;
    # Use the same Nerd Font as your desktop for consistency
    font = {
      name = "MesloLGS NF";
      size = 11;
    };
    theme = {
      package = pkgs.arc-theme;
      name = "Arc-Dark";
    };
    iconTheme = {
      package = pkgs.arc-icon-theme;
      name = "Arc";
    };
    # background = "${inputs.self}/assets/wallpaper.png";
  };
};
