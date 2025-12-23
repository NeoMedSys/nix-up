{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "sandboxed-slack-wayland";
  version = "1.0";
  nativeBuildInputs = [ pkgs.makeWrapper ];
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/bin $out/share/applications $out/share/icons/hicolor/scalable/apps
    
    cp ${pkgs.slack}/share/icons/hicolor/scalable/apps/slack.svg $out/share/icons/hicolor/scalable/apps/ || \
    cp ${pkgs.slack}/share/pixmaps/slack.png $out/share/icons/hicolor/scalable/apps/slack.svg || true
    
    makeWrapper ${pkgs.systemd}/bin/systemd-run $out/bin/slack \
      --run 'mkdir -p "$HOME/.local/share/app-isolation/slack"' \
      --add-flags "--user --scope -p MemoryHigh=4G -p MemoryMax=6G" \
      --add-flags "${pkgs.slack}/bin/slack" \
      --add-flags "--user-data-dir=\"\$HOME/.local/share/app-isolation/slack\"" \
      --add-flags "--force-device-scale-factor=1.0" \
      --add-flags "--high-dpi-support=1" \
      --add-flags "--enable-wayland-ime" \
      --add-flags "--enable-features=UseOzonePlatform,WebRTCPipeWireCapturer" \
      --add-flags "--ozone-platform=wayland" \
      --add-flags "--disable-features=WebRtcUsePortal" \
      --set HOSTNAME "research-workstation" \
      --set USER "researcher" \
      --set SLACK_DISABLE_TELEMETRY "1" \
      --set GDK_SCALE "1" \
      --set GDK_DPI_SCALE "1" \
      --set WAYLAND_DISPLAY "wayland-1" \
      --set XDG_SESSION_TYPE "wayland" \
      --set XDG_CURRENT_DESKTOP "sway" \
      --set XDG_RUNTIME_DIR "/run/user/1001"
    
    # Create desktop file with correct icon path
    cat > $out/share/applications/slack.desktop << EOF
[Desktop Entry]
Type=Application
Name=Slack
Comment=Slack Desktop App (Privacy-focused)
Exec=$out/bin/slack %u
Icon=$out/share/icons/hicolor/scalable/apps/slack.svg
Terminal=false
MimeType=x-scheme-handler/slack;
Categories=Network;InstantMessaging;
StartupWMClass=Slack
NoDisplay=false
EOF
  '';
}
