{ config, pkgs, inputs, user ? "algol", ... }:
{
  # Copy i3 configuration files to system
  environment.etc."i3/config".source = "${inputs.self}/i3-config/config";
  environment.etc."i3status-rust/config.toml".source = "${inputs.self}/i3status-rust-config/config.toml";

  # Polybar
  environment.etc."polybar/config.ini".source = "${inputs.self}/polybar-config/config.ini";
  environment.etc."polybar/launch.sh" = { 
    source = "${inputs.self}/polybar-config/launch.sh";
    mode = "0755"; 
  };

  # Create user i3 config directory and link files
  system.userActivationScripts.i3 = ''
    mkdir -p ~/.config/i3
    mkdir -p ~/.config/i3status-rust
    ln -sf /etc/i3/config ~/.config/i3/config
    ln -sf /etc/i3status-rust/config.toml ~/.config/i3status-rust/config.toml
  '';

  # Enable compositor for transparency effects
  services.picom = {
    enable = true;
    fade = true;
    shadow = true;
    fadeSteps = [ 0.028 0.03 ];
    fadeDelta = 10;
    shadowOpacity = 0.75;
  };
}
