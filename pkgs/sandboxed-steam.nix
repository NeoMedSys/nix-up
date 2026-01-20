{ pkgs, ... }:

let
  # Explicitly include tools needed for the Steam Runtime to unpack itself
  runtimeDependencies = with pkgs; [
    coreutils
    gnutar
    gzip
    xz
    dbus
    kmod # Needed for hardware detection
  ];

  steam-launcher = pkgs.writeShellScriptBin "steam" ''
    # 1. Setup isolation directory
    export ISOLATION_DIR="$HOME/.local/share/app-isolation/steam"
    mkdir -p "$ISOLATION_DIR"

    # 2. Fix NixOS 25.11 'unbound variable' crashes
    # The wrapper script uses 'set -u', so these MUST be defined.
    export LD_LIBRARY_PATH="''${LD_LIBRARY_PATH:-}"
    export STEAM_EXTRA_PROFILE="''${STEAM_EXTRA_PROFILE:-}"
    export STEAM_RUNTIME="''${STEAM_RUNTIME:-1}"
    
    # 3. Path & Home Isolation
    # We redirect HOME so Steam data stays in the isolation folder
    export HOME="$ISOLATION_DIR"
    # Ensure the bootstrap can find tar/gzip/etc.
    export PATH="${pkgs.lib.makeBinPath runtimeDependencies}:/run/current-system/sw/bin:$PATH"

    # 4. Environment variables for Display/Audio/Controller
    : ''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}
    : ''${PULSE_SERVER:=unix:$XDG_RUNTIME_DIR/pulse/native}
    : ''${WAYLAND_DISPLAY:=wayland-1}
    : ''${DISPLAY:=:0}

    # 5. Execute via systemd-run
    exec ${pkgs.systemd}/bin/systemd-run \
      --user \
      --scope \
      --collect \
      --unit=sandboxed-steam-$(date +%s) \
      --description="Sandboxed Steam" \
      -p MemoryHigh=12G \
      -p MemoryMax=14G \
      -E "HOME=$HOME" \
      -E "PATH=$PATH" \
      -E "LD_LIBRARY_PATH=$LD_LIBRARY_PATH" \
      -E "STEAM_EXTRA_PROFILE=$STEAM_EXTRA_PROFILE" \
      -E "STEAM_RUNTIME=$STEAM_RUNTIME" \
      -E "PULSE_SERVER=$PULSE_SERVER" \
      -E "DISPLAY=$DISPLAY" \
      -E "WAYLAND_DISPLAY=$WAYLAND_DISPLAY" \
      -E "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR" \
      -E "NIXOS_OZONE_WL=1" \
      ${pkgs.steam}/bin/steam \
        -silent \
        -console \
        "$@"
  '';
in
pkgs.stdenv.mkDerivation {
  name = "sandboxed-steam-wayland";
  version = "1.4";
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin $out/share/applications $out/share/icons/hicolor/scalable/apps

    # Use the icon from the steam package
    if [ -f "${pkgs.steam}/share/icons/hicolor/scalable/apps/steam.svg" ]; then
      cp "${pkgs.steam}/share/icons/hicolor/scalable/apps/steam.svg" $out/share/icons/hicolor/scalable/apps/
    elif [ -f "${pkgs.steam}/share/pixmaps/steam.png" ]; then
      cp "${pkgs.steam}/share/pixmaps/steam.png" $out/share/icons/hicolor/scalable/apps/steam.png
    fi

    cp ${steam-launcher}/bin/steam $out/bin/steam
    chmod +x $out/bin/steam

    cat > $out/share/applications/steam.desktop << EOF
[Desktop Entry]
Type=Application
Name=Steam (Sandboxed)
Exec=$out/bin/steam %u
Icon=steam
Terminal=false
Categories=Game;Network;
StartupWMClass=Steam
EOF
  '';
}
