{ config, pkgs, lib, inputs, userConfig ? null, ... }:
let
  processedKing = pkgs.runCommand "king-processed.png" {
    buildInputs = [ pkgs.imagemagick ];
  } ''
    convert ${inputs.self}/${userConfig.avatarPath} \
      -gravity center -resize 96x96^ -extent 96x96 $out
  '';
in
{
  # ========================
  # BOOT CONFIGURATION
  # ========================
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # ========================
  # LOCALIZATION & TIME
  # ========================
  time.timeZone = userConfig.timezone;

  i18n = {
    supportedLocales = [ "en_US.UTF-8/UTF-8" "nb_NO.UTF-8/UTF-8" ];
    defaultLocale = "en_US.UTF-8";
  };

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  # ========================
  # SERVICES
  # ========================
  services = {
    # Power Management
    tlp = {
      enable = true;
      settings = {
        RESTORE_DEVICE_STATE_ON_STARTUP = 1;
        DEVICES_TO_DISABLE_ON_STARTUP = "";
      };
    };

    # Security
    opensnitch.enable = true;
    fprintd.enable = true;

    # Display & Window Management
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        options = "eurosign:e,caps:escape";
      };
      windowManager.i3.enable = true;

      displayManager.lightdm = {
        enable = true;
        greeters.gtk = {
          enable = true;
            #theme = {
            #  package = pkgs.juno-theme;
            #  name = "Juno";
            #};
          iconTheme = {
            package = pkgs.papirus-icon-theme;
            name = "Papirus-Dark";
          };
          extraConfig = ''
            background = ${inputs.self}/${userConfig.wallpaperPath}
            font-name = MesloLGS NF 12
            indicators = ~host;~spacer;~clock;~spacer;~session;~power
            clock-format = %H:%M:%S | %A, %d %B %Y
            position = 50%,center 50%,center
          '';
        };
      };
    };

    displayManager.defaultSession = "none+i3";

    # Audio
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      wireplumber.enable = true;
    };

    # Bluetooth
    blueman.enable = true;
  };

  # ========================
  # USERS & SECURITY
  # ========================
  users.users.${userConfig.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "docker" "input" ];
    shell = pkgs.zsh;
    packages = with pkgs; [ tree ];
    homeMode = "0751";
  };

  security = {
    sudo.extraRules = [{
      users = [ userConfig.username ];
      commands = [{
        command = "ALL";
        options = [ "NOPASSWD" "NOSETENV" ];
      }];
    }];
    rtkit.enable = true;
    pam.services.lightdm = {
      text = ''
        auth      sufficient  pam_fprintd.so
        auth      substack    login
        account   include     login
        password  substack    login
        session   include     login
      '';
    };
  };

  # ========================
  # NETWORKING
  # ========================
  networking = {
    networkmanager.enable = true;
    nameservers = [ "1.1.1.1" "1.0.0.1" "8.8.8.8" "8.8.4.4" ];
    firewall = {
      allowedTCPPorts = [ 7775 443 ];
      allowedUDPPorts = [ 53 ];
    };
  };

  # ========================
  # ENVIRONMENT & VARIABLES
  # ========================
  environment = {
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      GTK_THEME = "Juno:dark";
      XDG_CURRENT_DESKTOP = "sway";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "sway";
    };
    etc = {
      # Global GTK Dark Theme Configuration  
      "gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-application-prefer-dark-theme=1
        gtk-theme-name=Juno
        gtk-icon-theme-name=Papirus-Dark
        gtk-font-name=MesloLGS NF 11
        gtk-cursor-theme-name=Adwaita
        gtk-cursor-theme-size=24
      '';

      "gtk-3.0/gtk.css".text = ''
        @import url("file:///etc/lightdm/gtk-greeter.css");
        @import url("${inputs.self}/configs/gtk-theme/gtk.css");
      '';

      "gtk-4.0/settings.ini".text = ''
        [Settings]
        gtk-application-prefer-dark-theme=1
        gtk-theme-name=Juno
        gtk-icon-theme-name=Papirus-Dark
        gtk-font-name=MesloLGS NF 11
      '';

      "gtk-4.0/gtk.css".text = ''
        @import url("file:///etc/lightdm/gtk-greeter.css");
        @import url("${inputs.self}/configs/gtk-theme/gtk.css");
      '';

      # User avatars and LightDM assets
      "user-avatars/king-${userConfig.username}.png".source = processedKing;
      "lightdm/avatar.png".source = processedKing;
      "lightdm/wallpaper.png".source = "${inputs.self}/${userConfig.wallpaperPath}";

      # LightDM GTK Greeter custom CSS - reference external file
      "lightdm/gtk-greeter.css".source = "${inputs.self}/configs/lightdm-gtk/greeter.css";
      
      # i3 Configuration Files
      "i3/config".source = "${inputs.self}/configs/i3-config/config";
      "i3status-rust/config.toml".source = "${inputs.self}/configs/i3status-rust-config/config.toml";
      "polybar/config.ini".source = "${inputs.self}/configs/polybar-config/config.ini";
      "polybar/launch.sh" = {
        source = "${inputs.self}/configs/polybar-config/launch.sh";
        mode = "0755";
      };
      
      # Desktop Environment Configs
      "dunst/dunstrc".source = "${inputs.self}/configs/dunst-config/dunstrc";
      "rofi/config.rasi".source = "${inputs.self}/configs/rofi-config/config.rasi";
      "picom.conf".source = "${inputs.self}/configs/picom-config/picom.conf";
      "alacritty/alacritty.toml".source = "${inputs.self}/configs/alacritty-config/alacritty.toml";
    };
  };

  # ========================
  # NIX CONFIGURATION
  # ========================
  nixpkgs.config.allowUnfree = true;

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    settings = {
      auto-optimise-store = true;
      max-jobs = "auto";
      cores = 0;
    };
  };

  # ========================
  # HARDWARE
  # ========================
  powerManagement = lib.mkIf userConfig.isLaptop {
    enable = true;
  };

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experiment = true;
        };
      };
    };
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  # ========================
  # VIRTUALIZATION
  # ========================
  virtualisation.docker = {
    enable = true;
    enableNvidia = userConfig.hasGPU;
  };

  # ========================
  # PROGRAMS
  # ========================
  programs.git = {
    enable = true;
    config = {
      user.name = userConfig.gitName;
      user.email = userConfig.gitEmail;
    };
  };

  # ========================
  # SYSTEMD SERVICES
  # ========================
  systemd = {
    user.services = {
      mpris-proxy.enable = true;
      libinput-gestures = {
        enable = true;
        description = "Libinput gestures";
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.libinput-gestures}/bin/libinput-gestures";
          Restart = "always";
        };
      };
    };

    services.display-manager.serviceConfig = {
      Environment = [
        "XDG_DATA_DIRS=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
        "XDG_DATA_DIRS+=/run/current-system/sw/share"
        "GTK_DATA_PREFIX=/etc"
        "XDG_CONFIG_DIRS=/etc"
      ];
    };
  };

  # ========================
  # SYSTEM SCRIPTS
  # ========================
  system = {
    userActivationScripts = {
      king = ''
        cp ${config.environment.etc."user-avatars/king-${userConfig.username}.png".source} /home/${userConfig.username}/.face
        chmod 644 /home/${userConfig.username}/.face
      '';

      i3-configs = ''
        mkdir -p ~/.config/{i3,i3status-rust,dunst,polybar,rofi,alacritty,picom,lightdm}
        ln -sf /etc/i3/config ~/.config/i3/config
        ln -sf /etc/i3status-rust/config.toml ~/.config/i3status-rust/config.toml
        ln -sf /etc/polybar/config.ini ~/.config/polybar/config.ini
        ln -sf /etc/polybar/launch.sh ~/.config/polybar/launch.sh
        ln -sf /etc/dunst/dunstrc ~/.config/dunst/dunstrc
        ln -sf /etc/rofi/config.rasi ~/.config/rofi/config.rasi
        ln -sf /etc/picom.conf ~/.config/picom.conf
        ln -sf /etc/alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml
      '';
    };
  };

  # ========================
  # XDG & FILE ASSOCIATIONS
  # ========================
  xdg.mime.defaultApplications = {
    # Nemo as default file manager
    "inode/directory" = "nemo.desktop";
    "application/x-gnome-saved-search" = "nemo.desktop";
    
    # OnlyOffice for all office formats
    "application/vnd.oasis.opendocument.text" = "onlyoffice-desktopeditors.desktop";
    "application/vnd.oasis.opendocument.spreadsheet" = "onlyoffice-desktopeditors.desktop";
    "application/vnd.oasis.opendocument.presentation" = "onlyoffice-desktopeditors.desktop";

    # OnlyOffice for MS Office formats
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "onlyoffice-desktopeditors.desktop";
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "onlyoffice-desktopeditors.desktop";
    "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "onlyoffice-desktopeditors.desktop";

    # Legacy MS Office formats
    "application/msword" = "onlyoffice-desktopeditors.desktop";
    "application/vnd.ms-excel" = "onlyoffice-desktopeditors.desktop";
    "application/vnd.ms-powerpoint" = "onlyoffice-desktopeditors.desktop";

    # PDF documents
    "application/pdf" = "org.pwmt.zathura.desktop";
  };


  # ========================
  # MISC CONFIGURATIONS
  # ========================
  environment.etc."libinput-gestures.conf".text = ''
    gesture swipe right 3 ydotool key alt+Left
    gesture swipe left 3 ydotool key alt+Right
  '';
}
