{ pkgs, userConfig, ... }:

{
  services.flatpak.enable = true;

  services.flatpak.remotes = [
    { name = "flathub"; location = "https://dl.flathub.org/repo/flathub.flatpakrepo"; }
  ];

  services.flatpak.packages = [
    "com.slack.Slack"
    "com.spotify.Client"
    "com.valvesoftware.Steam"
    "com.github.IsmaelMartinez.teams_for_linux"
    "us.zoom.Zoom"
  ];

  # Ensure Flatpak apps appear in launcher
  environment.sessionVariables = {
    XDG_DATA_DIRS = [ "/var/lib/flatpak/exports/share" ];
  };

  # Apply permission overrides after Flatpak apps are installed
  systemd.services.flatpak-managed-install.serviceConfig.ExecStartPost =
    pkgs.writeShellScript "flatpak-overrides" ''
      # --- GLOBAL ---
      ${pkgs.flatpak}/bin/flatpak override --system \
        --nosocket=x11 \
        --nosocket=fallback-x11 \
        --nosocket=pcsc \
        --nosocket=cups \
        --env=ELECTRON_DISABLE_CRASH_REPORTER=1 \
        --env=HOSTNAME=workstation

      # --- SLACK (video calls, screen sharing) ---
      ${pkgs.flatpak}/bin/flatpak override --system com.slack.Slack \
        --socket=wayland \
        --socket=pulseaudio \
        --socket=system-bus \
        --socket=session-bus \
        --nosocket=x11 \
        --device=all \
        --filesystem=xdg-download \
        --nofilesystem=home \
        --nofilesystem=host \
        --talk-name=org.freedesktop.portal.Camera \
        --env=SLACK_DISABLE_TELEMETRY=1

      # --- SPOTIFY (audio only) ---
      ${pkgs.flatpak}/bin/flatpak override --system com.spotify.Client \
        --socket=wayland \
        --socket=pulseaudio \
        --nosocket=x11 \
        --device=dri \
        --nofilesystem=home \
        --nofilesystem=host \
        --env=SPOTIFY_DISABLE_TELEMETRY=1

      # --- STEAM ---
      ${pkgs.flatpak}/bin/flatpak override --system com.valvesoftware.Steam \
        --socket=wayland \
        --socket=x11 \
        --socket=pulseaudio \
        --device=all \
        --filesystem=xdg-download

      # --- TEAMS (video calls, screen sharing) ---
      ${pkgs.flatpak}/bin/flatpak override --system com.github.IsmaelMartinez.teams_for_linux \
        --socket=wayland \
        --socket=pulseaudio \
        --socket=system-bus \
        --socket=session-bus \
        --nosocket=x11 \
        --device=all \
        --filesystem=xdg-download \
        --nofilesystem=home \
        --nofilesystem=host \
        --talk-name=org.freedesktop.portal.Camera \
        --env=TEAMS_DISABLE_TELEMETRY=1

      # --- ZOOM (video calls, screen sharing) ---
      ${pkgs.flatpak}/bin/flatpak override --system us.zoom.Zoom \
        --socket=wayland \
        --socket=pulseaudio \
        --socket=system-bus \
        --socket=session-bus \
        --nosocket=x11 \
        --device=all \
        --filesystem=xdg-download \
        --nofilesystem=home \
        --nofilesystem=host \
        --talk-name=org.freedesktop.portal.Camera \
        --env=ZOOM_DISABLE_TELEMETRY=1 \
        --env=ZOOM_DISABLE_ANALYTICS=1
    '';
}
