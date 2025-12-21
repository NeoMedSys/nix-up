{ pkgs, userConfig, inputs, ... }:
{
  programs.niri.enable = true;

  environment.etc."niri/config.kdl".text = ''
    input {
        touchpad {
            tap
            dwt
            middle-emulation false
        }
    }

    output "eDP-1" {
        scale 1.5
    }

    layout {
        gaps 12
        center-focused-column "never"
        focus-ring {
            width 3
            active-color "#ca9ee6" // Mauve
            inactive-color "#45475a"
        }
    }

    window-rule {
        match { is-active false; }
        opacity 0.85
    }

    binds {
        Mod+Return { spawn "alacritty"; }
        Mod+D { spawn "rofi" "-show" "drun"; }
        Mod+Q { close-window; }
        Mod+Left  { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Shift+Left  { move-column-left; }
        Mod+Shift+Right { move-column-right; }
    }

    spawn-at-startup "waybar"
    spawn-at-startup "swaybg -i ~/.config/sway/wallpaper.png -m fill"
    spawn-at-startup "clammy-start-session"
  '';
}
