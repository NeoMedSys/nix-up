{ pkgs, userConfig ? null, flakehub, inputs, ... }:
let
  sandboxed-slack = import ../pkgs/sandboxed-slack.nix { inherit pkgs; };
  sandboxed-spotify = import ../pkgs/sandboxed-spotify.nix { inherit pkgs; };
  sandboxed-steam = import ../pkgs/sandboxed-steam.nix { inherit pkgs; };

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
    fusuma
    libinput
    ripgrep
    tmux
    ydotool
    pciutils
    usbutils
    iw
    bolt
    v4l-utils
    libcamera

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

    # Entertainment - now handled by Flatpak
    sandboxed-spotify
    sandboxed-steam

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
    
    # WiFi menu script for waybar
    (pkgs.writeShellScriptBin "wifi-menu" ''
      wifi_list=$(nmcli -t -f "SIGNAL,SSID" device wifi list | sort -rn | head -10 | awk -F: '{print $2}')
      current=$(nmcli -t -f active,ssid dev wifi | grep '^yes:' | cut -d: -f2)
      if [ -n "$current" ]; then
          choice=$(echo -e "Disconnect from $current\n$wifi_list" | rofi -dmenu -p "WiFi")
          if [ "$choice" = "Disconnect from $current" ]; then
              nmcli connection down "$current"
          elif [ -n "$choice" ]; then
              nmcli device wifi connect "$choice"
          fi
      else
          choice=$(echo "$wifi_list" | rofi -dmenu -p "Connect to WiFi")
          if [ -n "$choice" ]; then
              nmcli device wifi connect "$choice"
          fi
      fi
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
