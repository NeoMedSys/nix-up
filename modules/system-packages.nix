{ lib, pkgs, config, flakehub, ... }:
let
  sandboxed-teams = import ../pkgs/sandboxed-teams.nix { inherit pkgs; };
  sandboxed-slack = import ../pkgs/sandboxed-slack.nix { inherit pkgs; };
  sandboxed-stremio = import ../pkgs/sandboxed-stremio.nix { inherit pkgs; };
  wayland-apps = import ../pkgs/sandboxed-apps.nix { inherit pkgs; };

in
{
  # Global software packages to install
  environment.systemPackages = with pkgs; [
    # Development tools
    flakehub.packages.${pkgs.system}.default

    curl
    git
    gcc
    openssl
    vscodium
    
    # System utilities
    direnv
    htop
    jq
    fastfetch
    fzf
    ripgrep
    rofi
    tmux
    xsel
    
    # Desktop utilities (moved from other modules)
    brightnessctl
    i3lock-fancy
    playerctl
    pavucontrol
    dunst
    gammastep
    libnotify
    mdcat
    networkmanagerapplet
    xorg.xrandr
    xss-lock
    
    # Window manager tools (moved from i3.nix)
    arandr
    dmenu
    i3
    i3status-rust
    i3lock
    i3blocks
    rofi
    feh
    picom
    polybar
    nitrogen
    sweet
    
    # sway
    sway
    swaylock-effects
    swayidle
    swaybg
    wl-clipboard
    grim
    slurp
    rofi-wayland
    waybar
    xdg-desktop-portal
    xdg-desktop-portal-wlr

    # Network and Bluetooth GUI tools
    networkmanagerapplet
    overskride  # Modern Rust+GTK4 Bluetooth manager
    
    # Screenshot tools
    scrot
    flameshot
    
    # Terminal emulator
    alacritty

    # Entertainment
    wayland-apps.sandboxed-stremio-wayland

    # comms
    wayland-apps.sandboxed-teams-wayland
    wayland-apps.sandboxed-slack-wayland
    wayland-apps.sandboxed-zoom-wayland
    
    # Muzicha
    spotify
    
    # Gaming utilities (moved from steam.nix)
    gamemode
    gamescope
    mangohud
    antimicrox
    
    # VPN and network tools (moved from expressvpn.nix)
    #openvpn
    #networkmanager-openvpn
    dig
    #wget

    # Privacy and security tools
    dnscrypt-proxy2
    opensnitch
    opensnitch-ui
    iftop
    nethogs
    
    # Encryption tools
    gnupg
    age
    sops

    # Screen Recording
    obs-studio
    wf-recorder

    # Secure communication
    signal-desktop
    element-desktop
    
    # Privacy utilities
    tor
    torsocks
    proxychains-ng
    
    # System security
    lynis  # Security auditing tool
    chkrootkit
    fail2ban

    # Bluetooth tools
    bluez
    bluez-tools
    
    # Zsh and theme
    zsh
    zsh-powerlevel10k
    zsh-syntax-highlighting

    # Office and document tools  
    onlyoffice-bin
    zathura
    evince
    tectonic
    
    # Fonts
    fira-code
    meslo-lgs-nf
    font-awesome_6
    dejavu_fonts
    liberation_ttf
    fira-code-symbols

    # Pandoc and live MD rendering
    pandoc
    (pkgs.writeScriptBin "mdlive" ''
        #!${pkgs.bash}/bin/bash
        FILE="$1"
        HTML="/tmp/$(basename "$FILE" .md).html"
        
        pandoc "$FILE" -s -o "$HTML"
        brave "$HTML" &
        
        while inotifywait -e modify "$FILE"; do
            pandoc "$FILE" -s -o "$HTML"
        done
    '')
    inotify-tools

  # X11 versions with different names (for fallback)
  (pkgs.writeScriptBin "stremio-x11" ''
    exec ${sandboxed-stremio}/bin/stremio "$@"
  '')
  (pkgs.writeScriptBin "teams-x11" ''
    exec ${sandboxed-teams}/bin/teams "$@"
  '')
  (pkgs.writeScriptBin "slack-x11" ''
    exec ${sandboxed-slack}/bin/slack "$@"  
  '')
  ];


  # This registers the fonts with your system so applications can find them.
  fonts.packages = with pkgs; [
    fira-code
    meslo-lgs-nf
    font-awesome_6
    dejavu_fonts
    liberation_ttf
    fira-code-symbols
    # Additional icon fonts for better brand logos
    material-design-icons
    material-icons
    noto-fonts-emoji
    nerd-fonts.symbols-only  # More comprehensive Nerd Fonts collection
    nerd-fonts.fira-code
    font-awesome_5
  ];
}
