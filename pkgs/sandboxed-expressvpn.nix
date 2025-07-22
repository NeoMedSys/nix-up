{ pkgs, expressvpn-unwrapped, ... }:

pkgs.stdenv.mkDerivation {
  name = "sandboxed-expressvpn";
  version = expressvpn-unwrapped.version;

  src = ./../vendor/expressvpn_3.83.0.2-1_amd64.deb;

  sha256 = "b0ee2882da2122934b752f4b5651e563e3d1ecf5b8c53895b5cc2d2dd4fdebd6";

  nativeBuildInputs = [ pkgs.makeWrapper ];
  buildInputs = [ pkgs.bubblewrap ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin

    makeWrapper ${expressvpn-unwrapped}/bin/expressvpn $out/bin/expressvpn \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.bubblewrap ]} \
      --add-flags "--run" \
      --add-flags "bwrap \\
        --dev-bind / / \\
        --ro-bind /nix/store /nix/store \\
        --proc /proc \\
        --dev /dev \\
        \
        # Persistent config/cache directory
        --bind $HOME/.local/share/expressvpn-sandboxed $HOME/.cache/expressvpn \\
        \
        # Allow communication with the daemon
        --ro-bind /var/run/dbus /var/run/dbus \\
        --ro-bind $XDG_RUNTIME_DIR/bus $XDG_RUNTIME_DIR/bus \\
        \
        # The command to run inside the sandbox
        /usr/bin/expressvpn"
  '';
}
