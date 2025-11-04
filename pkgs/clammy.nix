{ pkgs, lib, ... }:

let
  clammySourceDir = builtins.path { path = ../programs/clammy; };

  # The wrapper will provide the PATH for ALL binaries.
  runtimeDeps = with pkgs; [
    sway 
    swayidle 
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

  buildInputs = with pkgs; [
    dbus
    systemd
  ] ++ runtimeDeps;

  # This hook sets the PATH for both swaymsg and swayidle.
  postInstall = ''
    wrapProgram $out/bin/clammy \
      --prefix PATH : ${lib.makeBinPath runtimeDeps}
  '';

  
  meta = with lib; {
    description = "Clamshell mode daemon for Sway";
    homepage = "https://github.com/NeoMedSys/perseus";
    license = licenses.gpl3;
    platforms = platforms.linux;
    mainProgram = "clammy";
  };
}
