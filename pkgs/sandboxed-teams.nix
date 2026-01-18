{ pkgs, ... }:

let
  teams-launcher = pkgs.writeShellScriptBin "teams" ''
    ISOLATION_DIR="$HOME/.local/share/app-isolation/teams"
    mkdir -p "$ISOLATION_DIR"

    USER_ID=$(id -u)
    WAYLAND_SOCK=''${WAYLAND_DISPLAY:-wayland-0}

    exec ${pkgs.bubblewrap}/bin/bwrap \
      --unshare-all \
      --share-net \
      --die-with-parent \
      --new-session \
      --hostname "teams-prison" \
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
      --ro-bind-try /run/user/$USER_ID/bus /run/user/$USER_ID/bus \
      --ro-bind /dev/dri /dev/dri \
      --ro-bind-try /dev/video0 /dev/video0 \
      --ro-bind-try /dev/video1 /dev/video1 \
      --bind "$ISOLATION_DIR" "$HOME" \
      --setenv HOME "$HOME" \
      --setenv XDG_RUNTIME_DIR "/run/user/$USER_ID" \
      --setenv WAYLAND_DISPLAY "$WAYLAND_SOCK" \
      --setenv DBUS_SESSION_BUS_ADDRESS "unix:path=/run/user/$USER_ID/bus" \
      --setenv XDG_SESSION_TYPE "wayland" \
      --setenv XDG_CURRENT_DESKTOP "sway" \
      ${pkgs.teams-for-linux}/bin/teams-for-linux \
        --ozone-platform=wayland \
        --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer \
        --disable-features=WebRtcUsePortal \
        --enable-wayland-ime \
        "$@"
  '';
in
pkgs.stdenv.mkDerivation {
  pname = "sandboxed-teams-wayland";
  version = "1.2";

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/bin $out/share/applications $out/share/icons/hicolor/scalable/apps

    ln -s ${teams-launcher}/bin/teams $out/bin/teams

    cp ${pkgs.teams-for-linux}/share/icons/hicolor/scalable/apps/teams-for-linux.svg $out/share/icons/hicolor/scalable/apps/teams.svg || \
    cp ${pkgs.teams-for-linux}/share/icons/hicolor/256x256/apps/teams-for-linux.png $out/share/icons/hicolor/scalable/apps/teams.svg || true

    cat > $out/share/applications/teams.desktop << EOF
[Desktop Entry]
Type=Application
Name=Teams (Prison)
Comment=Microsoft Teams (Strict Bubblewrap Isolation)
Exec=$out/bin/teams %u
Icon=$out/share/icons/hicolor/scalable/apps/teams.svg
Terminal=false
MimeType=x-scheme-handler/msteams;
Categories=Network;InstantMessaging;
StartupWMClass=teams-for-linux
EOF
  '';
}
