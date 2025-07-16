{ config, pkgs, inputs, user ? "algol", ... }:
let
  # Define the path to the config file here to keep it clean
  configFile = config.environment.etc."i3status-rust/config.toml".source;
  statusCmd = "${pkgs.i3status-rust}/bin/i3status-rust ${configFile}";
in
{
  # Copy i3 configuration files to system
  environment.etc."i3/config".source = "${inputs.self}/i3-config/config";
  environment.etc."i3status-rust/config.toml".source = "${inputs.self}/i3status-rust-config/config.toml";

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

  # This correctly appends a generated bar block to your main i3 config
  services.xserver.windowManager.i3.extraConfig = ''
    bar {
      status_command ${statusCmd}
      font pango:MesloLGS NF 10
      position top
      colors {
        background            #282A2E
        statusline            #C5C8C6
        separator             #373B41

        #                     border    background   text
        focused_workspace     #4a90e2   #4a90e2      #ffffff
        active_workspace      #373B41   #373B41      #ffffff
        inactive_workspace    #282A2E   #282A2E      #888888
        urgent_workspace      #A54242   #A54242      #ffffff
      }
    }
  '';
}
