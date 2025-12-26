{ pkgs, lib, inputs }:
let
  clammySourceDir = builtins.path { path = ../programs/clammy; };
  dms = inputs.dms.packages.${pkgs.system}.default;
  runtimeDeps = [
    dms 
    pkgs.quickshell
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
    # For zbus
    dbus
    systemd
    # For wayland-client
    wayland
    wayland-protocols
    wlr-protocols # For wayland-protocols-wlr
  ] ++ runtimeDeps;

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
