{ pkgs, lib, ... }:

let
  clammySourceDir = builtins.path { path = ../programs/clammy; };

  # The wrapper will provide the PATH for our lock command.
  runtimeDeps = with pkgs; [
  ];
in
pkgs.rustPlatform.buildRustPackage {
  pname = "clammy";
  version = "0.1.0";
  src = clammySourceDir;

  cargoLock = {
    lockFile = "${clammySourceDir}/Cargo.lock";
  };

  nativeBuildInputs = with pkgs; [
    pkg-config
    makeWrapper
  ];

  # These are the C libraries our Rust code links against.
  buildInputs = with pkgs; [
    # For zbus
    dbus
    systemd

    # For wayland-client
    wayland
    wayland-protocols
    wlr-protocols # For wayland-protocols-wlr
  ] ++ runtimeDeps;

  # This hook ensures $PATH contains swaylock-effects
  # when the clammy service runs.
  postInstall = ''
    wrapProgram $out/bin/clammy \
      --prefix PATH : ${lib.makeBinPath runtimeDeps}
  '';

  meta = with lib; {
    description = "Clamshell mode daemon for Wayland";
    homepage = "https://github.com/NeoMedSys/perseus";
    license = licenses.gpl3;
    platforms = platforms.linux;
    mainProgram = "clammy";
  };
}
