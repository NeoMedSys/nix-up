{ pkgs, ... }:
let
  # Privacy-focused Slack with automatic URL handler registration
  sandboxed-slack-wayland = pkgs.stdenv.mkDerivation {
    name = "sandboxed-slack-wayland";
    version = "1.0";
    nativeBuildInputs = [ pkgs.makeWrapper ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin $out/share/applications
      # Create the slack wrapper
      # Remove user-data-dir if UX becomes annoying
      makeWrapper ${pkgs.slack}/bin/slack $out/bin/slack \
        --run 'mkdir -p "$HOME/.local/share/app-isolation/slack"' \
        --add-flags "--user-data-dir=\"\$HOME/.local/share/app-isolation/slack\"" \
        --set HOSTNAME "research-workstation" \
        --set USER "researcher" \
        --set SLACK_DISABLE_TELEMETRY "1"
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
  };
  # Privacy-focused Teams with URL handler registration
  sandboxed-teams-wayland = pkgs.stdenv.mkDerivation {
    name = "sandboxed-teams-wayland";
    version = "1.0";
    nativeBuildInputs = [ pkgs.makeWrapper ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin $out/share/applications
      # Create the teams wrapper
      makeWrapper ${pkgs.teams-for-linux}/bin/teams-for-linux $out/bin/teams \
        --run 'mkdir -p "$HOME/.local/share/app-isolation/teams"' \
        --add-flags "--user-data-dir=\"\$HOME/.local/share/app-isolation/teams\"" \
        --set HOSTNAME "research-workstation" \
        --set USER "researcher" \
        --set TEAMS_DISABLE_TELEMETRY "1"
      # Create desktop file for URL handler registration
      cat > $out/share/applications/teams-for-linux.desktop << EOF
[Desktop Entry]
Type=Application
Name=Microsoft Teams
Comment=Microsoft Teams (Privacy-focused)
Exec=$out/bin/teams %u
Icon=teams-for-linux
Terminal=false
MimeType=x-scheme-handler/msteams;
Categories=Network;InstantMessaging;
StartupWMClass=teams-for-linux
NoDisplay=false
EOF
    '';
  };
  # Privacy-focused Stremio
  sandboxed-stremio-wayland = pkgs.stdenv.mkDerivation {
    name = "sandboxed-stremio-wayland";
    version = "1.0";
    nativeBuildInputs = [ pkgs.makeWrapper ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin $out/share/applications
      # Create the stremio wrapper
      makeWrapper ${pkgs.stremio}/bin/stremio $out/bin/stremio \
        --run 'mkdir -p "$HOME/.local/share/app-isolation/stremio"' \
        --add-flags "--user-data-dir=\"\$HOME/.local/share/app-isolation/stremio\"" \
        --set HOSTNAME "research-workstation" \
        --set USER "researcher"
      # Create desktop file
      cat > $out/share/applications/stremio.desktop << EOF
[Desktop Entry]
Type=Application
Name=Stremio
Comment=Stremio Media Player (Privacy-focused)
Exec=$out/bin/stremio %u
Icon=stremio
Terminal=false
Categories=AudioVideo;Video;Player;
StartupWMClass=Stremio
NoDisplay=false
EOF
    '';
  };
  # Privacy-focused Zoom
  sandboxed-zoom-wayland = pkgs.stdenv.mkDerivation {
    name = "sandboxed-zoom-wayland";
    version = "1.0";
    nativeBuildInputs = [ pkgs.makeWrapper ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin $out/share/applications
      # Create the zoom wrapper
      makeWrapper ${pkgs.zoom-us}/bin/zoom-us $out/bin/zoom \
        --run 'mkdir -p "$HOME/.local/share/app-isolation/zoom"' \
        --add-flags "--user-data-dir=\"\$HOME/.local/share/app-isolation/zoom\"" \
        --set HOSTNAME "research-workstation" \
        --set USER "researcher" \
      # Create desktop file for URL handler registration
      cat > $out/share/applications/zoom.desktop << EOF
[Desktop Entry]
Type=Application
Name=Zoom
Comment=Zoom Video Conferencing (Privacy-focused)
Exec=$out/bin/zoom %u
Icon=zoom
Terminal=false
MimeType=x-scheme-handler/zoommtg;x-scheme-handler/zoomphonecall;
Categories=Network;AudioVideo;
StartupWMClass=zoom
NoDisplay=false
EOF
    '';
  };
in
{
  inherit sandboxed-teams-wayland sandboxed-slack-wayland sandboxed-stremio-wayland;
}
