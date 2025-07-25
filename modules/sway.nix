{ config, pkgs, lib, inputs, user ? "algol", ... }:
{
  # Basic Sway setup only
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  # Minimal PAM for swaylock
  security.pam.services.swaylock = {};

  # Basic Sway config only
  environment.etc."sway/config".source = "${inputs.self}/configs/sway-config/config";
  environment.etc."waybar/config".source = "${inputs.self}/configs/waybar-config/config.json";
  environment.etc."waybar/style.css".source = "${inputs.self}/configs/waybar-config/style.css";


  # Basic config symlink only
  system.userActivationScripts.sway-configs = ''
    mkdir -p ~/.config/sway
    ln -sf /etc/sway/config ~/.config/sway/config
    ln -sf /etc/waybar/config ~/.config/waybar/config
    ln -sf /etc/waybar/style.css ~/.config/waybar/style.css
  '';
}
