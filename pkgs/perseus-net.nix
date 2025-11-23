{ pkgs, lib, ... }:

let
  src = builtins.path { path = ../programs/perseus-net; };
in
pkgs.rustPlatform.buildRustPackage {
  pname = "perseus-net";
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
    description = "Rust-based WiFi menu for Rofi";
    mainProgram = "perseus-net";
    platforms = platforms.linux;
  };
}
