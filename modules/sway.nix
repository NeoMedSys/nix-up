{ pkgs, inputs, userConfig, lib, ... }:
{
  # Basic Sway setup only
  programs.sway = {
    enable = true;
    package = pkgs.swayfx;
    wrapperFeatures.gtk = true;
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config = {
      common = {
        default = [ "gtk" ];
      };
      sway = {
        default = lib.mkForce [ "wlr" "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
    };
  };

  security.pam.services.swaylock = {
  text = ''
    # First, try fingerprint authentication. If it succeeds, we're done.
    auth sufficient pam_fprintd.so
    # If fingerprint fails or isn't used, fall back to the standard login (password).
    auth include login
  '';
};

  # Basic Sway config only
  environment.etc."sway/config".source = "${inputs.self}/configs/sway-config/config";
  environment.etc."waybar/config".source = "${inputs.self}/configs/waybar-config/config.json";
  environment.etc."waybar/style.css".source = "${inputs.self}/configs/waybar-config/style.css";


  # Basic config symlink only
  system.userActivationScripts.sway-configs = ''
    mkdir -p ~/.config/sway ~/.config/waybar 
    ln -sf /etc/sway/config ~/.config/sway/config
    ln -sf /etc/waybar/config ~/.config/waybar/config
    ln -sf /etc/waybar/style.css ~/.config/waybar/style.css
    cp ${inputs.self}/${userConfig.wallpaperPath} ~/.config/sway/wallpaper.png
  '';
}
