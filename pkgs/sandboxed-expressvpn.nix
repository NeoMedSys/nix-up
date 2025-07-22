{ pkgs, expressvpn-unwrapped, ... }:

pkgs.writeShellScriptBin "expressvpn" ''
  #!${pkgs.stdenv.shell}
  
  mkdir -p "$HOME/.local/share/expressvpn-sandboxed"
  
  BWRAP_ARGS=(
    --share-net
    --dev-bind / /
    --ro-bind /nix/store /nix/store
    --proc /proc
    --dev /dev
    --ro-bind /etc/resolv.conf /etc/resolv.conf
    --ro-bind /etc/ssl/certs /etc/ssl/certs
    --ro-bind /etc/machine-id /etc/machine-id   # <-- Add this
    --ro-bind /etc/passwd /etc/passwd         # <-- Add this
    --ro-bind /etc/group /etc/group           # <-- Add this
    --bind "$HOME/.local/share/expressvpn-sandboxed" "$HOME/.cache/expressvpn"
    --ro-bind /var/run/dbus /var/run/dbus
    --ro-bind "$XDG_RUNTIME_DIR/bus" "$XDG_RUNTIME_DIR/bus"
  )
  
  exec ${pkgs.bubblewrap}/bin/bwrap "''${BWRAP_ARGS[@]}" \
    ${expressvpn-unwrapped}/usr/bin/expressvpn "$@"
''
