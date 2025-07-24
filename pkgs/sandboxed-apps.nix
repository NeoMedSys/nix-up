{ pkgs, ... }:

let
  # Sandboxed Teams for Wayland
  sandboxed-teams-wayland = pkgs.stdenv.mkDerivation {
    name = "sandboxed-teams-wayland";
    version = "1.0";
    nativeBuildInputs = [ pkgs.makeWrapper ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${pkgs.bubblewrap}/bin/bwrap $out/bin/teams \
        --run 'mkdir -p "$HOME/.local/share/teams-sandboxed"' \
        --add-flags "--dev-bind / /" \
        --add-flags "--ro-bind /nix/store /nix/store" \
        --add-flags "--proc /proc" \
        --add-flags "--dev /dev" \
        --add-flags "--ro-bind /etc/resolv.conf /etc/resolv.conf" \
        --add-flags "--ro-bind /var/run/dbus /var/run/dbus" \
        --add-flags "--bind \"\$HOME/.local/share/teams-sandboxed\" \"\$HOME/.config/teams-for-linux\"" \
        --add-flags "--ro-bind \"\$XDG_RUNTIME_DIR/pulse\" \"\$XDG_RUNTIME_DIR/pulse\"" \
        --add-flags "--ro-bind \"\$XDG_RUNTIME_DIR/bus\" \"\$XDG_RUNTIME_DIR/bus\"" \
        --add-flags "--ro-bind \"\$XDG_RUNTIME_DIR/wayland-0\" \"\$XDG_RUNTIME_DIR/wayland-0\"" \
        --add-flags "--setenv WAYLAND_DISPLAY \"\$WAYLAND_DISPLAY\"" \
        --add-flags "--setenv XDG_SESSION_TYPE wayland" \
        --add-flags "${pkgs.teams-for-linux}/bin/teams-for-linux"
    '';
  };

  # Sandboxed Slack for Wayland  
  sandboxed-slack-wayland = pkgs.stdenv.mkDerivation {
    name = "sandboxed-slack-wayland";
    version = "1.0";
    nativeBuildInputs = [ pkgs.makeWrapper ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${pkgs.bubblewrap}/bin/bwrap $out/bin/slack \
        --run 'mkdir -p "$HOME/.local/share/slack-sandboxed"' \
        --add-flags "--dev-bind / /" \
        --add-flags "--ro-bind /nix/store /nix/store" \
        --add-flags "--proc /proc" \
        --add-flags "--dev /dev" \
        --add-flags "--ro-bind /etc/resolv.conf /etc/resolv.conf" \
        --add-flags "--ro-bind /var/run/dbus /var/run/dbus" \
        --add-flags "--bind \"\$HOME/.local/share/slack-sandboxed\" \"\$HOME/.config/Slack\"" \
        --add-flags "--ro-bind \"\$XDG_RUNTIME_DIR/pulse\" \"\$XDG_RUNTIME_DIR/pulse\"" \
        --add-flags "--ro-bind \"\$XDG_RUNTIME_DIR/bus\" \"\$XDG_RUNTIME_DIR/bus\"" \
        --add-flags "--ro-bind \"\$XDG_RUNTIME_DIR/wayland-0\" \"\$XDG_RUNTIME_DIR/wayland-0\"" \
        --add-flags "--setenv WAYLAND_DISPLAY \"\$WAYLAND_DISPLAY\"" \
        --add-flags "--setenv XDG_SESSION_TYPE wayland" \
        --add-flags "${pkgs.slack}/bin/slack"
    '';
  };

  # Sandboxed Stremio for Wayland
  sandboxed-stremio-wayland = pkgs.stdenv.mkDerivation {
    name = "sandboxed-stremio-wayland";
    version = "1.0";
    nativeBuildInputs = [ pkgs.makeWrapper ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${pkgs.bubblewrap}/bin/bwrap $out/bin/stremio \
        --run 'mkdir -p "$HOME/.local/share/stremio-sandboxed"' \
        --add-flags "--dev-bind / /" \
        --add-flags "--ro-bind /nix/store /nix/store" \
        --add-flags "--proc /proc" \
        --add-flags "--dev /dev" \
        --add-flags "--ro-bind /etc/resolv.conf /etc/resolv.conf" \
        --add-flags "--unshare-pid" \
        --add-flags "--unshare-uts" \
        --add-flags "--bind \"\$HOME/.local/share/stremio-sandboxed\" \"\$HOME/.config/Stremio\"" \
        --add-flags "--bind \"\$HOME/Downloads\" \"\$HOME/Downloads\"" \
        --add-flags "--dev-bind /dev/dri /dev/dri" \
        --add-flags "--ro-bind \"\$XDG_RUNTIME_DIR/pulse\" \"\$XDG_RUNTIME_DIR/pulse\"" \
        --add-flags "--ro-bind /run/dbus /run/dbus" \
        --add-flags "--ro-bind \"\$XDG_RUNTIME_DIR/wayland-0\" \"\$XDG_RUNTIME_DIR/wayland-0\"" \
        --add-flags "--setenv WAYLAND_DISPLAY \"\$WAYLAND_DISPLAY\"" \
        --add-flags "--setenv XDG_SESSION_TYPE wayland" \
        --add-flags "${pkgs.stremio}/bin/stremio"
    '';
  };

in
{
  inherit sandboxed-teams-wayland sandboxed-slack-wayland sandboxed-stremio-wayland;
}
