{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "sandboxed-spotify-wayland";
  version = "1.0";
  nativeBuildInputs = [ pkgs.makeWrapper ];
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/bin $out/share/applications
    # Create the spotify wrapper with GPU access
    makeWrapper ${pkgs.systemd}/bin/systemd-run $out/bin/spotify \
      --run 'mkdir -p "$HOME/.local/share/app-isolation/spotify"' \
      --add-flags "--user --scope -p MemoryHigh=2G -p MemoryMax=4G" \
      --add-flags "${pkgs.spotify}/bin/spotify" \
      --add-flags "--user-data-dir=\"\$HOME/.local/share/app-isolation/spotify\"" \
      --add-flags "--enable-gpu-rasterization" \
      --add-flags "--enable-zero-copy" \
      --add-flags "--ignore-gpu-blocklist" \
      --add-flags "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder" \
      --add-flags "--ozone-platform=wayland" \
      --set HOSTNAME "research-workstation" \
      --set USER "researcher" \
      --set SPOTIFY_DISABLE_TELEMETRY "1"
    # Create desktop file
    cat > $out/share/applications/spotify.desktop << EOF
[Desktop Entry]
Type=Application
Name=Spotify
Comment=Spotify Music Player (Privacy-focused)
Exec=$out/bin/spotify %u
Icon=spotify
Terminal=false
Categories=AudioVideo;Audio;Player;
StartupWMClass=Spotify
NoDisplay=false
EOF
  '';
}
