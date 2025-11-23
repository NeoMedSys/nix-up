{ pkgs, ... }:

let
  # We define the launcher script to handle the environment hand-off
  steam-launcher = pkgs.writeShellScriptBin "steam" ''
    # 1. Setup isolation directory
    ISOLATION_DIR="$HOME/.local/share/app-isolation/steam"
    mkdir -p "$ISOLATION_DIR/shader_cache"
    
    # 2. Define standard audio/display variables if missing
    : ''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}
    : ''${PULSE_SERVER:=unix:$XDG_RUNTIME_DIR/pulse/native}
    : ''${WAYLAND_DISPLAY:=wayland-1}
    : ''${DISPLAY:=:0}

    # 3. Launch via systemd-run
    # We explicitly pass (-E) every critical variable to ensure the 
    # scope inherits the GPU drivers and library paths correctly.
    exec ${pkgs.systemd}/bin/systemd-run \
      --user \
      --scope \
      --unit=sandboxed-steam-$(date +%s) \
      --description="Sandboxed Steam (Privacy Focused)" \
      -p MemoryHigh=12G \
      -p MemoryMax=14G \
      -E "PULSE_SERVER=$PULSE_SERVER" \
      -E "DISPLAY=$DISPLAY" \
      -E "WAYLAND_DISPLAY=$WAYLAND_DISPLAY" \
      -E "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR" \
      -E "XDG_SESSION_TYPE=$XDG_SESSION_TYPE" \
      -E "NIXOS_OZONE_WL=1" \
      -E "STEAM_RUNTIME=1" \
      -E "STEAM_RUNTIME_PREFER_HOST_LIBRARIES=0" \
      -E "SDL_VIDEODRIVER=x11" \
      -E "GDK_BACKEND=x11" \
      -E "__NV_PRIME_RENDER_OFFLOAD=1" \
      -E "__VK_LAYER_NV_optimus=NVIDIA_only" \
      -E "__GLX_VENDOR_LIBRARY_NAME=nvidia" \
      -E "__GL_GSYNC_ALLOWED=1" \
      -E "__GL_VRR_ALLOWED=1" \
      ${pkgs.steam}/bin/steam \
        -silent \
        -noverifyfiles \
        -console \
        -user-data-dir="$ISOLATION_DIR" \
        "$@"
  '';
in
pkgs.stdenv.mkDerivation {
  name = "sandboxed-steam-wayland";
  version = "1.2";
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin $out/share/applications
    
    # Install the launcher
    cp ${steam-launcher}/bin/steam $out/bin/steam
    chmod +x $out/bin/steam

    # Create desktop entry
    cat > $out/share/applications/steam.desktop << EOF
[Desktop Entry]
Type=Application
Name=Steam
Comment=Steam Gaming Platform (Privacy-focused)
Exec=$out/bin/steam %u
Icon=steam
Terminal=false
Categories=Game;Network;
StartupWMClass=Steam
NoDisplay=false
EOF
  '';
}
