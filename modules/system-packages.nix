{ pkgs, userConfig ? null, flakehub, inputs, ... }:
let
  sandboxed-teams = import ../pkgs/sandboxed-teams.nix { inherit pkgs; };
  sandboxed-slack = import ../pkgs/sandboxed-slack.nix { inherit pkgs; };
  sandboxed-stremio = import ../pkgs/sandboxed-stremio.nix { inherit pkgs; };
  wayland-apps = import ../pkgs/sandboxed-apps.nix { inherit pkgs; };

  availableBrowsers = {
    firefox = pkgs.firefox;
  };

  browserPackages = if userConfig != null
    then map (browserName: availableBrowsers.${browserName}) (builtins.filter (browser: browser != "librewolf") userConfig.browsers)
    else [ availableBrowsers.firefox ]; # fallback default
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
    btop
    jq
    fastfetch
    fzf
    libinput-gestures
    libinput
    ripgrep
    tmux
    ydotool
    pciutils
    usbutils
    iw
    bolt

    # File manager and themes
    nemo
    juno-theme

    # Desktop utilities
    brightnessctl
    playerctl
    pavucontrol
    gnupg
    libnotify
    mdcat
    networkmanagerapplet
    gammastep
    dunst

    # Wayland-specific tools
    swayfx
    swayidle
    swaybg
    wl-clipboard
    grim
    slurp
    rofi-wayland
    xdg-desktop-portal
    xdg-desktop-portal-wlr
    waybar
    swaylock-effects
    sweet # GTK theme

    # Network and Bluetooth GUI tools
    overskride # Modern Rust+GTK4 Bluetooth manager

    # Terminal emulator
    alacritty

    # Entertainment
    wayland-apps.sandboxed-stremio-wayland
    spotify

    # Communication Apps (Sandboxed)
    wayland-apps.sandboxed-teams-wayland
    wayland-apps.sandboxed-slack-wayland
    wayland-apps.sandboxed-zoom-wayland

    # Gaming utilities
    gamemode
    gamescope
    mangohud
    antimicrox

    # Network tools
    dig
    iftop
    nethogs

    # Encryption tools
    age
    sops

    # Screen Recording
    obs-studio
    wf-recorder

    # Secure communication
    signal-desktop
    element-desktop

    # Privacy and security tools
    dnscrypt-proxy2
    opensnitch
    opensnitch-ui

    # Privacy utilities
    tor
    torsocks
    proxychains-ng

    # System security auditing tools
    lynis
    chkrootkit

    # Office and document tools
    onlyoffice-bin
    zathura
    evince
    tectonic

    # Bluetooth tools
    bluez
    bluez-tools

    # Zsh and theme
    zsh
    zsh-powerlevel10k
    zsh-syntax-highlighting

    # Fonts and cursors
    fira-code
    meslo-lgs-nf
    font-awesome_6
    dejavu_fonts
    liberation_ttf
    fira-code-symbols
    papirus-icon-theme
    bibata-cursors

    # Pandoc and live MD rendering script
    pandoc
    (pkgs.writeScriptBin "mdlive" ''
      #!/bin/bash
      FILE="$1"
      HTML="/tmp/$(basename "$FILE" .md).html"
      pandoc "$FILE" -s -o "$HTML"
      librewolf "$HTML" &
      while inotifywait -e modify "$FILE"; do
        pandoc "$FILE" -s -o "$HTML"
      done
    '')
    inotify-tools
  ] ++ browserPackages;

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
    nerd-fonts.symbols-only # More comprehensive Nerd Fonts collection
    nerd-fonts.fira-code
    font-awesome_5
  ];
}
