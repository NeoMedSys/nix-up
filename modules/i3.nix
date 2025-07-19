{ config, pkgs, inputs, ... }:
{
  # This section declaratively manages all your config files
  environment.etc = {
    "i3/config".source = "${inputs.self}/i3-config/config";
    "i3status-rust/config.toml".source = "${inputs.self}/i3status-rust-config/config.toml";
    "polybar/config.ini".source = "${inputs.self}/polybar-config/config.ini";
    "polybar/launch.sh" = {
      source = "${inputs.self}/polybar-config/launch.sh";
      mode = "0755";
    };
    "dunst/dunstrc".source = "${inputs.self}/dunst-config/dunstrc";
    "rofi/config.rasi".source = "${inputs.self}/rofi-config/config.rasi";
  };

  # This script creates symlinks in your home directory
  system.userActivationScripts.i3-configs = ''
    mkdir -p ~/.config/{i3,i3status-rust,dunst,polybar,rofi}
    ln -sf /etc/i3/config ~/.config/i3/config
    ln -sf /etc/i3status-rust/config.toml ~/.config/i3status-rust/config.toml
    ln -sf /etc/polybar/config.ini ~/.config/polybar/config.ini
    ln -sf /etc/polybar/launch.sh ~/.config/polybar/launch.sh
    ln -sf /etc/dunst/dunstrc ~/.config/dunst/dunstrc
    ln -sf /etc/rofi/config.rasi ~/.config/rofi/config.rasi
  '';

  # Enable the picom compositor service
  services.picom = {
    enable = true;
    fade = true;
    shadow = true;
  };
}
