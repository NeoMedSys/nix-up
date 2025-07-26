{ pkgs, ... }:

let
  # Data isolation + full functionality -- Restricting Telemetry is handled by networking
  
  # Privacy-focused Slack with data isolation
  sandboxed-slack-wayland = pkgs.stdenv.mkDerivation {
    name = "sandboxed-slack-wayland";
    version = "1.0";
    nativeBuildInputs = [ pkgs.makeWrapper ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${pkgs.slack}/bin/slack $out/bin/slack \
        --run 'mkdir -p "$HOME/.local/share/app-isolation/slack"' \
        --run 'mkdir -p "$HOME/.local/share/app-isolation/slack/.config"' \
        --run 'mkdir -p "$HOME/.local/share/app-isolation/slack/.local/share"' \
        --set HOME "$HOME/.local/share/app-isolation/slack" \
        --set HOSTNAME "research-workstation" \
        --set USER "researcher" \
        --set LOGNAME "researcher" \
        --set SLACK_DISABLE_TELEMETRY "1" \
        --set WAYLAND_DISPLAY "$WAYLAND_DISPLAY" \
        --set XDG_SESSION_TYPE "wayland" \
        --set XDG_RUNTIME_DIR "$XDG_RUNTIME_DIR"
    '';
  };

  # Privacy-focused Teams with data isolation  
  sandboxed-teams-wayland = pkgs.stdenv.mkDerivation {
    name = "sandboxed-teams-wayland";
    version = "1.0";
    nativeBuildInputs = [ pkgs.makeWrapper ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${pkgs.teams-for-linux}/bin/teams-for-linux $out/bin/teams \
        --run 'mkdir -p "$HOME/.local/share/app-isolation/teams"' \
        --run 'mkdir -p "$HOME/.local/share/app-isolation/teams/.config"' \
        --run 'mkdir -p "$HOME/.local/share/app-isolation/teams/.local/share"' \
        --set HOME "$HOME/.local/share/app-isolation/teams" \
        --set HOSTNAME "research-workstation" \
        --set USER "researcher" \
        --set LOGNAME "researcher" \
        --set TEAMS_DISABLE_TELEMETRY "1" \
        --set WAYLAND_DISPLAY "$WAYLAND_DISPLAY" \
        --set XDG_SESSION_TYPE "wayland" \
        --set XDG_RUNTIME_DIR "$XDG_RUNTIME_DIR"
    '';
  };

  # Privacy-focused Stremio with data isolation
  sandboxed-stremio-wayland = pkgs.stdenv.mkDerivation {
    name = "sandboxed-stremio-wayland";
    version = "1.0";
    nativeBuildInputs = [ pkgs.makeWrapper ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${pkgs.stremio}/bin/stremio $out/bin/stremio \
        --run 'mkdir -p "$HOME/.local/share/app-isolation/stremio"' \
        --run 'mkdir -p "$HOME/.local/share/app-isolation/stremio/.config"' \
        --run 'mkdir -p "$HOME/.local/share/app-isolation/stremio/.local/share"' \
        --set HOME "$HOME/.local/share/app-isolation/stremio" \
        --set HOSTNAME "research-workstation" \
        --set USER "researcher" \
        --set WAYLAND_DISPLAY "$WAYLAND_DISPLAY" \
        --set XDG_SESSION_TYPE "wayland" \
        --set XDG_RUNTIME_DIR "$XDG_RUNTIME_DIR"
    '';
  };

in
{
  inherit sandboxed-teams-wayland sandboxed-slack-wayland sandboxed-stremio-wayland;
}
