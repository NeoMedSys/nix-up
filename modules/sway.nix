# modules/sway.nix - ONLY Sway-specific additions (no duplication!)
{ config, pkgs, lib, inputs, user ? "algol", ... }:

{
  # Enable Sway with Wayland packages
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      # Sway-specific tools (not in your existing packages)
      swaylock-effects    # Screen locker 
      swayidle           # Idle management
      swaybg             # Background setter
      
      # Wayland utilities
      wl-clipboard       # Clipboard
      grim               # Screenshots
      slurp              # Screen area selection
      
      # Wayland versions of existing tools
      rofi-wayland       # Wayland rofi
      
      # Optional Wayland alternatives
      waybar             # Alternative status bar
      wofi               # Alternative launcher
      mako               # Alternative notifications
      
      # Display tools
      kanshi             # Display configuration
      gammastep          # Blue light filter (replaces redshift)
    ];
  };

  # Sway login manager (parallel to your existing LightDM)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd sway";
        user = "greeter";
      };
    };
  };

  # XDG Portal for Wayland (screen sharing, file picking)
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
  };

  # Wayland-specific environment variables ONLY
  environment.sessionVariables = {
    # Wayland session identification
    XDG_CURRENT_DESKTOP = "sway";
    XDG_SESSION_DESKTOP = "sway";
    XDG_SESSION_TYPE = "wayland";
    
    # Application compatibility
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    MOZ_ENABLE_WAYLAND = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    SDL_VIDEODRIVER = "wayland";
  };

  # PAM service for swaylock
  security.pam.services.swaylock = {};

  # Sway configuration files
  environment.etc = {
    "sway/config".source = "${inputs.self}/configs/sway-config/config";
    "sway/i3status-rust.toml".source = "${inputs.self}/configs/i3status-rust-config/config.toml";
  };

  # Create Sway config symlinks
  system.userActivationScripts.sway-configs = ''
    mkdir -p ~/.config/sway
    ln -sf /etc/sway/config ~/.config/sway/config
    ln -sf /etc/sway/i3status-rust.toml ~/.config/sway/i3status-rust.toml
  '';
}
