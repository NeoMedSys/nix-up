{ pkgs, ... }:

let
  spotify-sandbox = pkgs.writeShellScriptBin "spotify" ''
    ISOLATION_DIR="$HOME/.local/share/app-isolation/spotify"
    mkdir -p "$ISOLATION_DIR"
    USER_ID=$(id -u)
    XDG_RT="/run/user/$USER_ID"

    exec ${pkgs.systemd}/bin/systemd-run \
      --user --scope --collect \
      --unit=sandboxed-spotify-$(date +%s) \
      -p MemoryHigh=2G \
      -p MemoryMax=4G \
      ${pkgs.bubblewrap}/bin/bwrap \
        --unshare-all \
        --share-net \
        --die-with-parent \
        --new-session \
        --hostname "workstation" \
        --proc /proc \
        --dev-bind /dev/dri /dev/dri \
        --dev /dev \
        --tmpfs /tmp \
        --tmpfs /dev/shm \
        --ro-bind /nix /nix \
        --ro-bind /run/current-system /run/current-system \
        --ro-bind /etc/fonts /etc/fonts \
        --ro-bind /etc/resolv.conf /etc/resolv.conf \
        --ro-bind /etc/machine-id /etc/machine-id \
        --ro-bind /etc/passwd /etc/passwd \
        --ro-bind /etc/group /etc/group \
        --ro-bind /etc/hosts /etc/hosts \
        --ro-bind "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" /etc/ssl/certs/ca-certificates.crt \
        --bind "$ISOLATION_DIR" "$HOME/.config/spotify" \
        --dir "$HOME" \
        --dir "$XDG_RT" \
        --ro-bind-try "$XDG_RT/$WAYLAND_DISPLAY" "$XDG_RT/$WAYLAND_DISPLAY" \
        --ro-bind-try "$XDG_RT/pipewire-0" "$XDG_RT/pipewire-0" \
        --ro-bind-try "$XDG_RT/pulse" "$XDG_RT/pulse" \
        --setenv HOME "$HOME" \
        --setenv XDG_RUNTIME_DIR "$XDG_RT" \
        --setenv WAYLAND_DISPLAY "''${WAYLAND_DISPLAY:-wayland-0}" \
        --setenv XDG_SESSION_TYPE "wayland" \
        --setenv SPOTIFY_DISABLE_TELEMETRY "1" \
        --setenv HOSTNAME "workstation" \
        --setenv SSL_CERT_FILE /etc/ssl/certs/ca-certificates.crt \
        --setenv NIX_SSL_CERT_FILE /etc/ssl/certs/ca-certificates.crt \
        ${pkgs.spotify}/bin/spotify \
          --ozone-platform=wayland \
          --enable-gpu-rasterization \
          --enable-zero-copy \
          --ignore-gpu-blocklist \
          --enable-features=VaapiVideoDecoder,VaapiVideoEncoder \
          "$@"
  '';
in
pkgs.stdenv.mkDerivation {
  name = "sandboxed-spotify-wayland";
  version = "2.0";
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/bin $out/share/applications $out/share/icons/hicolor/scalable/apps

    if [ -f "${pkgs.spotify}/share/icons/hicolor/scalable/apps/spotify.svg" ]; then
      cp "${pkgs.spotify}/share/icons/hicolor/scalable/apps/spotify.svg" $out/share/icons/hicolor/scalable/apps/
    elif [ -f "${pkgs.spotify}/share/pixmaps/spotify.png" ]; then
      cp "${pkgs.spotify}/share/pixmaps/spotify.png" $out/share/icons/hicolor/scalable/apps/spotify.svg
    fi

    cp ${spotify-sandbox}/bin/spotify $out/bin/spotify
    chmod +x $out/bin/spotify

    cat > $out/share/applications/spotify.desktop << EOF
[Desktop Entry]
Type=Application
Name=Spotify
Comment=Spotify Music (Sandboxed)
Exec=$out/bin/spotify %u
Icon=$out/share/icons/hicolor/scalable/apps/spotify.svg
Terminal=false
Categories=AudioVideo;Audio;Player;
StartupWMClass=Spotify
NoDisplay=false
EOF
  '';
}
