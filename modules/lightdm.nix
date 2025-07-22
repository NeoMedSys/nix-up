# lightdm.nix
{ pkgs, inputs, ... }:

{
  services.xserver.displayManager.lightdm = {
    enable = true;
    greeters.gtk = {
      enable = true;
      # These sections correctly install and set the theme/icons.
      theme = {
        package = pkgs.arc-theme;
        name = "Arc-Dark";
      };
      iconTheme = {
        package = pkgs.arc-icon-theme;
        name = "Arc";
      };

      # This is the correct way to set the background.
      # It adds the line directly to the generated config file.
      extraConfig = ''
        background = "${inputs.self}/assets/wallpaper.png";
      '';
    };
  };
}
