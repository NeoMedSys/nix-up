{ pkgs, inputs, lib, ... }:
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
    "picom.conf".source = "${inputs.self}/configs/picom-config/picom.conf";
    "alacritty/alacritty.toml".source = "${inputs.self}/configs/alacritty-config/alacritty.toml";
  };


}
