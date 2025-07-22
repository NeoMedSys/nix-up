# pkgs/sandboxed-stremio.nix
{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "sandboxed-stremio";
  version = "1.0";

  nativeBuildInputs = [ pkgs.makeWrapper ];
  buildInputs = [ pkgs.bubblewrap pkgs.stremio ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin

    makeWrapper ${pkgs.stremio}/bin/stremio $out/bin/stremio \
      --add-flags "--run" \
      --add-flags "bwrap \\
        /* --- Base Sandbox Setup --- */
        --ro-bind /nix/store /nix/store \\
        --proc /proc \\
        --dev /dev \\
        --ro-bind /etc/resolv.conf /etc/resolv.conf \\
        --unshare-pid \\
        --unshare-uts \\
        --symlink usr/lib /lib \\
        --symlink usr/lib64 /lib64 \\
        --symlink usr/bin /bin \\
        --symlink usr/sbin /sbin \\

        /* --- Persistent Stremio Configuration --- */
        /* Isolate config to its own directory, maps to where Stremio expects it */
        --bind $HOME/.local/share/stremio-sandboxed $HOME/.config/Stremio \\

        /* --- Secure Home Directory Access --- */
        /* Only allow access to the Downloads folder, not the entire home */
        --bind $HOME/Downloads $HOME/Downloads \\

        /* --- Hardware, Sound, and Display Server Access --- */
        /* Allow GPU hardware acceleration */
        --dev-bind /dev/dri /dev/dri \\
        /* Allow sound */
        --ro-bind $XDG_RUNTIME_DIR/pulse $XDG_RUNTIME_DIR/pulse \\
        /* Allow D-Bus for desktop integration */
        --ro-bind /run/dbus /run/dbus \\
        /* X11 Access */
        --ro-bind /tmp/.X11-unix /tmp/.X11-unix \\
        --setenv DISPLAY $DISPLAY \\
        /* Wayland Access */
        --ro-bind $XDG_RUNTIME_DIR/wayland-0 $XDG_RUNTIME_DIR/wayland-0 \\
        --setenv WAYLAND_DISPLAY $WAYLAND_DISPLAY \\

        /* --- The command to run inside the sandbox --- */
        /usr/bin/stremio"
  '';
}
