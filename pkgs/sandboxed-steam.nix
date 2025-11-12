{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "sandboxed-steam-wayland";
  version = "1.0";
  nativeBuildInputs = [ pkgs.makeWrapper ];
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/bin $out/share/applications
    makeWrapper ${pkgs.steam}/bin/steam $out/bin/steam \
      --run 'mkdir -p "$HOME/.local/share/app-isolation/steam"; sleep 2' \
      --set STEAM_RUNTIME_PREFER_HOST_LIBRARIES "0" \
      --set STEAM_RUNTIME "1" \
      --set HOSTNAME "research-workstation" \
      --set USER "researcher" \
      --set STEAM_DISABLE_TELEMETRY "1" \
      --set __GL_SHADER_DISK_CACHE_PATH "$HOME/.local/share/app-isolation/steam/shader_cache" \
      --add-flags "-silent" \
      --set SDL_VIDEODRIVER "x11" \
      --set GDK_BACKEND "x11" \
      --set QT_QPA_PLATFORM "xcb" \
      --set __NV_PRIME_RENDER_OFFLOAD "1" \
      --set __VK_LAYER_NV_optimus "NVIDIA_only" \
      --set __GLX_VENDOR_LIBRARY_NAME "nvidia" \
      --set __GL_GSYNC_ALLOWED "1" \
      --set __GL_VRR_ALLOWED "1" \
      --set STEAM_WEB_CLIENT_ARGS "--disable-gpu-sandbox --use-gl=desktop" \
      --unset LIBVA_DRIVER_NAME \
      --unset VDPAU_DRIVER

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
