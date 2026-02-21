{ pkgs, ... }:

let
  stremio-launcher = pkgs.writeShellScriptBin "stremio" ''

    if ! ip addr show mullvad > /dev/null 2>&1; then
        notify-send "Security Alert" "VPN is NOT connected. App will not launch."
        exit 1
    fi

    # 1. Define the Jail Directory
    ISOLATION_DIR="$HOME/.local/share/app-isolation/stremio"
    mkdir -p "$ISOLATION_DIR"

    USER_ID=$(id -u)
    WAYLAND_SOCK=''${WAYLAND_DISPLAY:-wayland-0}

    # 2. Launch Bubblewrap (The Prison)
    exec ${pkgs.bubblewrap}/bin/bwrap \
      --unshare-all \
      --share-net \
      --die-with-parent \
      --new-session \
      --hostname "stremio-prison" \
      --proc /proc \
      --dev /dev \
      --tmpfs /tmp \
      --tmpfs /dev/shm \
      --ro-bind /nix /nix \
      --ro-bind /run/current-system /run/current-system \
      --ro-bind /run/opengl-driver /run/opengl-driver \
      --ro-bind /etc/fonts /etc/fonts \
      --ro-bind /etc/ssl /etc/ssl \
      --ro-bind /etc/resolv.conf /etc/resolv.conf \
      --ro-bind /etc/machine-id /etc/machine-id \
      --dir /run/user/$USER_ID \
      --ro-bind-try /run/user/$USER_ID/$WAYLAND_SOCK /run/user/$USER_ID/$WAYLAND_SOCK \
      --ro-bind-try /run/user/$USER_ID/pulse /run/user/$USER_ID/pulse \
      --bind-try /run/user/$USER_ID/pipewire-0 /run/user/$USER_ID/pipewire-0 \
      --ro-bind /dev/dri /dev/dri \
      --bind "$ISOLATION_DIR" "$HOME" \
      --setenv HOME "$HOME" \
      --setenv XDG_RUNTIME_DIR "/run/user/$USER_ID" \
      --setenv QT_QPA_PLATFORM "wayland" \
      ${pkgs.stremio}/bin/stremio \
        --script-opts=ytdl_hook-try_ytdl_first=no \
        --load-scripts=no \
        "$@"
  '';
in
pkgs.stdenv.mkDerivation {
  pname = "sandboxed-stremio";
  version = "1.3";

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/bin $out/share/applications

    # We use 'ln -s' to point to the launcher we built above
    ln -s ${stremio-launcher}/bin/stremio $out/bin/stremio

    # Create the Desktop Entry
    cat > $out/share/applications/stremio.desktop << EOF
[Desktop Entry]
Type=Application
Name=Stremio (Prison)
Comment=Sandboxed via Bubblewrap (Wayland Native)
Exec=$out/bin/stremio
Icon=${pkgs.stremio}/share/icons/hicolor/128x128/apps/stremio.png
Terminal=false
Categories=AudioVideo;Video;Player;
StartupWMClass=stremio
EOF
  '';
}
