{ pkgs, ... }:
{
  services.flatpak.enable = true;

  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };

  systemd.services.flatpak-apps = {
    wantedBy = [ "multi-user.target" ];
    after = [ "flatpak-repo.service" ];
    path = [ pkgs.flatpak ];
    script = ''
      # Install communication apps
      flatpak install -y flathub com.slack.Slack
      flatpak install -y flathub com.microsoft.Teams
      flatpak install -y flathub us.zoom.Zoom

      # Install entertainment apps
      flatpak install -y flathub com.stremio.Stremio
      flatpak install -y flathub com.spotify.Client
    '';
  };

  # Tech-lord resistance: Override hostname for Flatpak apps
  environment.variables = {
    # Hostname spoofing for privacy
    HOSTNAME = "research-workstation";
    USER = "researcher";
    
    # Disable telemetry for Flatpak apps
    SLACK_DISABLE_TELEMETRY = "1";
    TEAMS_DISABLE_TELEMETRY = "1";
    ZOOM_DISABLE_ANALYTICS = "1";
  };

  # Create wrapper scripts that set privacy variables
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "slack" ''
      exec flatpak run --env=HOSTNAME=research-workstation --env=USER=researcher --env=SLACK_DISABLE_TELEMETRY=1 com.slack.Slack "$@"
    '')
    (writeShellScriptBin "teams" ''
      exec flatpak run --env=HOSTNAME=research-workstation --env=USER=researcher --env=TEAMS_DISABLE_TELEMETRY=1 com.microsoft.Teams "$@"
    '')
    (writeShellScriptBin "zoom" ''
      exec flatpak run --env=HOSTNAME=research-workstation --env=USER=researcher --env=ZOOM_DISABLE_ANALYTICS=1 us.zoom.Zoom "$@"
    '')
    (writeShellScriptBin "stremio" ''
      exec flatpak run --env=HOSTNAME=research-workstation --env=USER=researcher com.stremio.Stremio "$@"
    '')
    (writeShellScriptBin "spotify" ''
      exec flatpak run --env=HOSTNAME=research-workstation --env=USER=researcher com.spotify.Client "$@"
    '')
  ];
}
