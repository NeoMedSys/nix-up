{ pkgs, ... }:

let
  stremio-launcher = pkgs.writeShellScriptBin "stremio" ''
    # 1. Define the Jail Directory
    ISOLATION_DIR="$HOME/.local/share/app-isolation/stremio"
    mkdir -p "$ISOLATION_DIR"

    # 2. Prepare Bubblewrap
    # We bind the essential system paths so Stremio can run and find MPV.
    # We explicitly map the isolation dir to $HOME so Stremio cannot escape.
    
    exec ${pkgs.bubblewrap}/bin/bwrap \
      --unshare-all \
      --share-net \
      --die-with-parent \
      --dir /tmp \
      --dev /dev \
      --proc /proc \
      --ro-bind /nix /nix \
      --ro-bind /run/current-system /run/current-system \
      --ro-bind /run/opengl-driver /run/opengl-driver \
      --ro-bind /etc/profiles /etc/profiles \
      --ro-bind /etc/static /etc/static \
      --ro-bind /etc/fonts /etc/fonts \
      --ro-bind /etc/ssl /etc/ssl \
      --ro-bind /etc/machine-id /etc/machine-id \
      --ro-bind /sys/dev /sys/dev \
      --ro-bind /sys/devices /sys/devices \
      --ro-bind /sys/class /sys/class \
      --script-opts=ytdl_hook-try_ytdl_first=no \  # Prevent it from calling youtube-dl automatically
      --load-scripts=no \                          # Disable all external scripts
      --network-timeout=10                         # Fail fast on network hangs
      --bind /run/user/$(id -u) /run/user/$(id -u) \
      --tmpfs /home \
      --bind "$ISOLATION_DIR" "$HOME" \
      --setenv HOME "$HOME" \
      --setenv XDG_CONFIG_HOME "$HOME/.config" \
      --setenv XDG_DATA_HOME "$HOME/.local/share" \
      --setenv XDG_CACHE_HOME "$HOME/.cache" \
      --setenv QT_QPA_PLATFORM wayland \
      ${pkgs.stremio}/bin/stremio "$@"
  '';
in
pkgs.stdenv.mkDerivation {
  name = "sandboxed-stremio";
  version = "1.2";
  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/bin $out/share/applications
    cp ${stremio-launcher}/bin/stremio $out/bin/stremio
    chmod +x $out/bin/stremio

    cat > $out/share/applications/stremio.desktop << EOF
[Desktop Entry]
Type=Application
Name=Stremio (Prison)
Comment=Sandboxed via Bubblewrap
Exec=$out/bin/stremio
Icon=${pkgs.stremio}/share/icons/hicolor/128x128/apps/stremio.png
Terminal=false
Categories=AudioVideo;Video;Player;
StartupWMClass=stremio
EOF
  '';
}
