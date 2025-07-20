{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "sandboxed-teams";
  version = "1.0";

  nativeBuildInputs = [ pkgs.makeWrapper ];
  buildInputs = [ pkgs.bubblewrap pkgs.teams-for-linux ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin

    makeWrapper ${pkgs.teams-for-linux}/bin/teams-for-linux $out/bin/teams \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.bubblewrap ]} \
      --add-flags "--run" \
      --add-flags "bwrap \\
        --dev-bind / / \\
        --ro-bind /nix/store /nix/store \\
        --proc /proc \\
        --dev /dev \\
        --ro-bind /etc/resolv.conf /etc/resolv.conf \\
        --symlink usr/lib /lib \\
        --symlink usr/lib64 /lib64 \\
        --symlink usr/bin /bin \\
        --symlink usr/sbin /sbin \\
        \
        # Create a persistent directory for Teams data
        --bind $HOME/.local/share/teams-sandboxed $HOME/.config/teams-for-linux \\
        \
        # Grant access to necessary services
        --ro-bind /var/run/dbus /var/run/dbus \\
        --ro-bind $XDG_RUNTIME_DIR/pulse $XDG_RUNTIME_DIR/pulse \\
        --ro-bind $XDG_RUNTIME_DIR/bus $XDG_RUNTIME_DIR/bus \\
        \
        # X11 or Wayland access
        --ro-bind /tmp/.X11-unix /tmp/.X11-unix \\
        --setenv DISPLAY $DISPLAY \\
        \
        # The command to run inside the sandbox
        /usr/bin/teams-for-linux"
  '';
}
