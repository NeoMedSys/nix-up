{ pkgs, ... }:
pkgs.stdenv.mkDerivation {
  name = "sandboxed-slack";
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
      --add-flags "--ro-bind /tmp/.X11-unix /tmp/.X11-unix" \
      --add-flags "--bind \"\$HOME/.local/share/slack-sandboxed\" \"\$HOME/.config/Slack\"" \
      --add-flags "--ro-bind \"\$XDG_RUNTIME_DIR/pulse\" \"\$XDG_RUNTIME_DIR/pulse\"" \
      --add-flags "--ro-bind \"\$XDG_RUNTIME_DIR/bus\" \"\$XDG_RUNTIME_DIR/bus\"" \
      --add-flags "--setenv DISPLAY \"\$DISPLAY\"" \
      --add-flags "${pkgs.slack}/bin/slack"
  '';
}
