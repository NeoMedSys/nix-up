{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "sandboxed-slack-wayland";
  version = "1.0";
  nativeBuildInputs = [ pkgs.makeWrapper ];
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/bin $out/share/applications
    # Create the slack wrapper
    makeWrapper ${pkgs.systemd}/bin/systemd-run $out/bin/slack \
      --run 'mkdir -p "$HOME/.local/share/app-isolation/slack"' \
      --add-flags "--user --scope -p MemoryHigh=4G -p MemoryMax=6G" \
      --add-flags "${pkgs.slack}/bin/slack" \
      --add-flags "--user-data-dir=\"\$HOME/.local/share/app-isolation/slack\"" \
      --add-flags "--force-device-scale-factor=1.0" \
      --add-flags "--high-dpi-support=1" \
      --add-flags "--disable-gpu" \
      --add-flags "--enable-wayland-ime" \
      --add-flags "--property=\"NoNewPrivileges=true\"" \
      --set HOSTNAME "research-workstation" \
      --set USER "researcher" \
      --set SLACK_DISABLE_TELEMETRY "1" \
      --set GDK_SCALE "1" \
      --set GDK_DPI_SCALE "1"
    # Create desktop file for URL handler registration
    cat > $out/share/applications/slack.desktop << EOF
[Desktop Entry]
Type=Application
Name=Slack
Comment=Slack Desktop App (Privacy-focused)
Exec=$out/bin/slack %u
Icon=slack
Terminal=false
MimeType=x-scheme-handler/slack;
Categories=Network;InstantMessaging;
StartupWMClass=Slack
NoDisplay=false
EOF
  '';
}
