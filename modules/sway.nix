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
        # Explicitly route camera requests to GTK portal
        "org.freedesktop.impl.portal.Camera" = [ "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        # Keep screen capture with WLR
        "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
      };
    };
  };

  security.pam.services.swaylock = {
    text = ''
      auth sufficient pam_fprintd.so
      auth include login
    '';
  };

  # Ensure fprintd service is available and started
  systemd.services.fprintd.wantedBy = [ "multi-user.target" ];
  systemd.services.fprintd.serviceConfig.Type = "simple";
  
  # Force fprintd to start early
  systemd.user.services.fprintd-user = {
    description = "Ensure fprintd is available for user session";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/true";
      ExecStartPost = "${pkgs.systemd}/bin/systemctl --no-block start fprintd";
      RemainAfterExit = true;
    };
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
