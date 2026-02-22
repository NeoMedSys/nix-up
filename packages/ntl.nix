{ pkgs, lib, ... }:

let
  src = builtins.path { path = ../programs/ntl; };
in
pkgs.rustPlatform.buildRustPackage {
  pname = "nasty-tech-lords";
  version = "0.2.0";

  inherit src;

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  nativeBuildInputs = with pkgs; [
    pkg-config
  ];

  buildInputs = with pkgs; [ ];

  meta = with lib; {
    description = "Rust-based security audit tool for Perseus";
    homepage = "https://github.com/NeoMedSys/perseus";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "nasty-tech-lords";
  };
}
