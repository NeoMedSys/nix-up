{ pkgs, userConfig ? null, flakehub, inputs, ... }:
let
  sandboxed-teams = import ../pkgs/sandboxed-teams.nix { inherit pkgs; };
  sandboxed-slack = import ../pkgs/sandboxed-slack.nix { inherit pkgs; };
  sandboxed-stremio = import ../pkgs/sandboxed-stremio.nix { inherit pkgs; };
  wayland-apps = import ../pkgs/sandboxed-apps.nix { inherit pkgs; };

  availableBrowsers = {
    librewolf = import ../pkgs/librewolf-with-policies.nix { inherit pkgs inputs; }; 
    firefox = pkgs.firefox;
  };

  browserPackages = if userConfig != null
    then map (browserName: availableBrowsers.${browserName}) userConfig.browsers
    else [ availableBrowsers.librewolf availableBrowsers.firefox ]; # fallback default
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
    rofi
    tmux
    xsel
    ydotool
    pciutils
    usbutils
    iw
    wirelesstools
    bolt

    # File manager and themes
    nemo
    juno-theme

    # Desktop utilities
    brightnessctl
    i3lock-fancy
    playerctl
    pavucontrol
    gnupg
    libnotify
    mdcat
    networkmanagerapplet
    xorg.xrandr # Useful for arandr or manual display config
    xss-lock
    gammastep
    dunst

    # Window manager tools (some are needed for configs even if WM is module-managed)
    arandr # X11 display config GUI
    dmenu
    feh # Sets wallpaper in i3
    i3
    i3blocks
    picom
    polybar # Bar for i3
    nitrogen
    sweet # GTK theme

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


    # Network and Bluetooth GUI tools
    overskride # Modern Rust+GTK4 Bluetooth manager

    # Screenshot tools
    scrot
    flameshot

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

    # Fonts
    fira-code
    meslo-lgs-nf
    font-awesome_6
    dejavu_fonts
    liberation_ttf
    fira-code-symbols
    papirus-icon-theme

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
