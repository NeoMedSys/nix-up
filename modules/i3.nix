{ config, pkgs, inputs, ... }:
{
  # This section declaratively manages all your config files
  environment.etc = {
    "i3/config".source = "${inputs.self}/configs/i3-config/config";
    "i3status-rust/config.toml".source = "${inputs.self}/configs/i3status-rust-config/config.toml";
    "polybar/config.ini".source = "${inputs.self}/configs/polybar-config/config.ini";
    "polybar/launch.sh" = {
      source = "${inputs.self}/configs/polybar-config/launch.sh";
      mode = "0755";
    };
    "dunst/dunstrc".source = "${inputs.self}/configs/dunst-config/dunstrc";
    "rofi/config.rasi".source = "${inputs.self}/configs/rofi-config/config.rasi";
    "alacritty/alacritty.yaml".source = "${inputs.self}/configs/alacritty-config/alacritty.yaml";
    "picom.conf".source = "${inputs.self}/configs/picom-config/picom.conf";
  };

  # This script creates symlinks in your home directory
  system.userActivationScripts.i3-configs = ''
    mkdir -p ~/.config/{i3,i3status-rust,dunst,polybar,rofi,alacritty,picom} # <-- Add picom
    ln -sf /etc/i3/config ~/.config/i3/config
    ln -sf /etc/i3status-rust/config.toml ~/.config/i3status-rust/config.toml
    ln -sf /etc/polybar/config.ini ~/.config/polybar/config.ini
    ln -sf /etc/polybar/launch.sh ~/.config/polybar/launch.sh
    ln -sf /etc/dunst/dunstrc ~/.config/dunst/dunstrc
    ln -sf /etc/rofi/config.rasi ~/.config/rofi/config.rasi
    ln -sf /etc/alacritty/alacritty.yaml ~/.config/alacritty/alacritty.yml # Corrected target name
    ln -sf /etc/picom.conf ~/.config/picom.conf
  '';

  # The services.picom block is now REMOVED
}
