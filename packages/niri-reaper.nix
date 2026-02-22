{ pkgs, lib }:
let
  sourceDir = builtins.path { path = ../programs/niri-reaper; };
  runtimeDeps = [
    pkgs.niri
    pkgs.flatpak
  ];
in
pkgs.rustPlatform.buildRustPackage {
  pname = "niri-reaper";
  version = "0.1.0";
  src = sourceDir;
  cargoLock = {
    lockFile = "${sourceDir}/Cargo.lock";
  };
  nativeBuildInputs = with pkgs; [
    makeWrapper
  ];
  postInstall = ''
    wrapProgram $out/bin/niri-reaper \
      --prefix PATH : ${lib.makeBinPath runtimeDeps}
  '';
  meta = with lib; {
    description = "Reaps orphaned Flatpak processes when niri windows close";
    homepage = "https://github.com/NeoMedSys/perseus";
    license = licenses.gpl3;
    platforms = platforms.linux;
    mainProgram = "niri-reaper";
  };
}
