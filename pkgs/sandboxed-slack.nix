{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "sandboxed-slack";
  version = "1.0";

  nativeBuildInputs = [ pkgs.makeWrapper ];
  buildInputs = [ pkgs.bubblewrap pkgs.slack ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin

    makeWrapper ${pkgs.slack}/bin/slack $out/bin/slack \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.bubblewrap ]} \
      --add-flags "--disable-gpu-sandbox" \
      --run "mkdir -p $HOME/.local/share/slack-sandboxed" \
      --run "exec bwrap \
        --dev-bind / / \
        --ro-bind /nix/store /nix/store \
        --proc /proc \
        --dev /dev \
        --ro-bind /etc/resolv.conf /etc/resolv.conf \
        --symlink usr/lib /lib \
        --symlink usr/lib64 /lib64 \
        --symlink usr/bin /bin \
        --symlink usr/sbin /sbin \
        \
        --bind $HOME/.local/share/slack-sandboxed $HOME/.config/Slack \
        \
        --ro-bind /var/run/dbus /var/run/dbus \
        --ro-bind $XDG_RUNTIME_DIR/pulse $XDG_RUNTIME_DIR/pulse \
        --ro-bind $XDG_RUNTIME_DIR/bus $XDG_RUNTIME_DIR/bus \
        \
        --ro-bind /tmp/.X11-unix /tmp/.X11-unix \
        --setenv DISPLAY $DISPLAY \
        \
        ${pkgs.slack}/bin/.slack-wrapped --disable-gpu-sandbox \"\$@\""
  '';
}
