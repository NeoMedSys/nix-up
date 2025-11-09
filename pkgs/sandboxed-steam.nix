{ pkgs, ... }:
pkgs.writeShellScriptBin "steam" ''
  # XDG-based isolation - isolate Steam's data without breaking system access
  export XDG_DATA_HOME="$HOME/.local/share/app-isolation/steam/data"
  export XDG_CONFIG_HOME="$HOME/.local/share/app-isolation/steam/config"
  export XDG_CACHE_HOME="$HOME/.local/share/app-isolation/steam/cache"
  export XDG_STATE_HOME="$HOME/.local/share/app-isolation/steam/state"

  # Create directories
  mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

  # Wayland session info
  export WAYLAND_DISPLAY="wayland-1"
  export XDG_SESSION_TYPE="wayland"
  export XDG_CURRENT_DESKTOP="sway"

  # Privacy settings
  export HOSTNAME="research-workstation"
  export USER="researcher"
  export STEAM_DISABLE_TELEMETRY="1"

  # Graphics optimization
  export __GL_SHADER_DISK_CACHE_PATH="$XDG_CACHE_HOME/steam_shader_cache"
  export __GL_THREADED_OPTIMIZATIONS="1"

  # Execute steam from the NixOS steam package (set by programs.steam.enable)
  exec ${pkgs.steam}/bin/steam "$@"
''
