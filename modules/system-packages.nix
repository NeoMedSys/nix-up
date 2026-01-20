{ pkgs, userConfig ? null, flakehub, inputs, ... }:
let
  sandboxed-slack = import ../pkgs/sandboxed-slack.nix { inherit pkgs; };
  sandboxed-spotify = import ../pkgs/sandboxed-spotify.nix { inherit pkgs; };
  sandboxed-steam = import ../pkgs/sandboxed-steam.nix { inherit pkgs; };
  sandboxed-teams = import ../pkgs/sandboxed-teams.nix { inherit pkgs; };
  sandboxed-stremio = import ../pkgs/sandboxed-stremio.nix { inherit pkgs; };
  sandboxed-logseq = import ../pkgs/sandboxed-logseq.nix { inherit pkgs userConfig; };
  sandboxed-frontend = pkgs.callPackage ../pkgs/sandboxed-frontend.nix {};
  perseus-net = pkgs.callPackage ../pkgs/perseus-net.nix {};
  dms = inputs.dms.packages.${pkgs.system}.default;
  dgop = inputs.dgop.packages.${pkgs.system}.default;
  ntl-daemon = pkgs.callPackage ../pkgs/ntl-daemon.nix {};
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
    dms
    dgop
    quickshell
    direnv
    btop
    jq
    fastfetch
    fzf
    libinput
    ripgrep
    tmux
    ydotool
    pciutils
    usbutils
    iw
    bolt
    upower
    v4l-utils
    libcamera
    networkmanagerapplet
    ntl-daemon
    evtest
    libinput

    # ipu6
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    gst_all_1.icamerasrc-ipu6
    gst_all_1.gst-libav
    libcamera
    xdg-desktop-portal-gtk

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
    xwayland-satellite

    # Wayland-specific tools
    wl-clipboard
    xdg-desktop-portal
    xdg-desktop-portal-wlr
    sweet # GTK theme

    # Network and Bluetooth GUI tools
    overskride # Modern Rust+GTK4 Bluetooth manager

    # Terminal emulator
    alacritty

    # Entertainment - now handled by Flatpak
    sandboxed-spotify
    sandboxed-steam
    # sandboxed-stremio
    mpv

    # Communication Apps - now handled by Flatpak
    sandboxed-slack

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
    dnscrypt-proxy
    opensnitch
    opensnitch-ui

    # Privacy utilities
    tor
    torsocks
    proxychains-ng

    # System security auditing tools
    lynis

    # Office and document tools
    rnote
    sandboxed-logseq
    sandboxed-teams
    onlyoffice-desktopeditors
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
    adwaita-icon-theme
    hicolor-icon-theme
    tela-icon-theme

    libayatana-appindicator

    # Never trust anything a frontend developer makes
    sandboxed-frontend

    # Pandoc and live MD rendering script
    pandoc
    wkhtmltopdf
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
    perseus-net
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
    noto-fonts-color-emoji
    nerd-fonts.symbols-only # More comprehensive Nerd Fonts collection
    nerd-fonts.fira-code
    font-awesome_5
  ];
}
