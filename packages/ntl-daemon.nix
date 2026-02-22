{ pkgs, lib }:

let
  src = builtins.path { path = ../programs/ntl-daemon; };
in
pkgs.rustPlatform.buildRustPackage {
  pname = "ntl-daemon";
  version = "0.1.0";

  inherit src;

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  nativeBuildInputs = with pkgs; [
    pkg-config
  ];

  buildInputs = with pkgs; [
    dbus
  ];

  meta = with lib; {
    description = "NTL system tray daemon";
    platforms = platforms.linux;
    mainProgram = "ntl-daemon";
  };
}
