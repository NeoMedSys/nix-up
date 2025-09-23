{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "sandboxed-steam-wayland";
  version = "1.0";
  nativeBuildInputs = [ pkgs.makeWrapper ];
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/bin $out/share/applications
    # Create a simpler steam wrapper that OpenSnitch can intercept
    makeWrapper ${pkgs.steam}/bin/steam $out/bin/steam \
      --run 'mkdir -p "$HOME/.local/share/app-isolation/steam"' \
      --set STEAM_RUNTIME_PREFER_HOST_LIBRARIES "0" \
      --set STEAM_RUNTIME "1" \
      --set HOSTNAME "research-workstation" \
      --set USER "researcher" \
      --set STEAM_DISABLE_TELEMETRY "1" \
      --set __GL_SHADER_DISK_CACHE_PATH "$HOME/.local/share/app-isolation/steam/shader_cache" \
      --set __GL_THREADED_OPTIMIZATIONS "1" \
      --set MESA_GL_VERSION_OVERRIDE "4.6" \
      --set MESA_GLSL_VERSION_OVERRIDE "460" \
      --set LIBVA_DRIVER_NAME "nvidia" \
      --set VDPAU_DRIVER "nvidia" \
      --add-flags "-silent"
    # Create desktop file
    cat > $out/share/applications/steam.desktop << EOF
[Desktop Entry]
Type=Application
Name=Steam
Comment=Steam Gaming Platform (Privacy-focused)
Exec=$out/bin/steam %u
Icon=steam
Terminal=false
Categories=Game;Network;
StartupWMClass=Steam
NoDisplay=false
EOF
  '';
}
