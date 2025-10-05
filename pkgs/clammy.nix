{ pkgs, lib, ... }:

let
  clammySourceDir = builtins.path { path = ../programs/clammy; };
in
pkgs.rustPlatform.buildRustPackage {
  pname = "clammy";
  version = "0.1.0";

  # Use the local source directory
  src = clammySourceDir;

  # Cargo.lock must exist in programs/clammy directory
  # Run: cd programs/clammy && cargo generate-lockfile
  cargoLock = {
    lockFile = "${clammySourceDir}/Cargo.lock";
  };

  # System dependencies needed for zbus (D-Bus)
  nativeBuildInputs = with pkgs; [
    pkg-config
  ];

  buildInputs = with pkgs; [
    dbus
    systemd
  ];

  # Runtime dependencies
  propagatedBuildInputs = with pkgs; [
    sway
    systemd
    swaylock-effects
  ];

  meta = with lib; {
    description = "Clamshell mode daemon for Sway";
    homepage = "https://github.com/your-repo/perseus";
    license = licenses.gpl3;
    platforms = platforms.linux;
    mainProgram = "clammy";
  };
}
