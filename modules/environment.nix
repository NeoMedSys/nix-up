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
        greeters.gtk.enable = true;
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

      # Custom Nord Dark CSS for all GTK applications
      "gtk-3.0/gtk.css".text = ''
        /* Nord Dark Theme with Orange Highlights */
        
        /* Base colors */
        @define-color nord0 #2E3440;   /* Dark background */
        @define-color nord1 #3B4252;   /* Darker background */
        @define-color nord2 #434C5E;   /* Medium dark */
        @define-color nord3 #4C566A;   /* Medium */
        @define-color nord4 #D8DEE9;   /* Light text */
        @define-color nord12 #D08770;  /* Orange highlight */
        @define-color nord11 #BF616A;  /* Red accent */

        /* Main window background */
        window,
        .background {
          background-color: @nord0;
          color: @nord4;
        }

        /* Sidebar styling (fixes bold text issue) */
        .sidebar,
        .sidebar * {
          background-color: @nord1;
          color: @nord4;
          font-weight: normal; /* Remove bold */
        }

        .sidebar:selected,
        .sidebar *:selected {
          background-color: @nord12;
          color: @nord0;
        }

        /* File manager specific styling */
        .nemo-window .sidebar {
          background-color: @nord1;
          border-right: 1px solid @nord3;
        }

        .nemo-window .sidebar row {
          font-weight: normal;
          padding: 8px;
        }

        .nemo-window .sidebar row:selected {
          background-color: @nord12;
          color: @nord0;
        }

        /* Entry fields and search */
        entry {
          background-color: @nord2;
          color: @nord4;
          border: 1px solid @nord3;
        }

        entry:focus {
          border-color: @nord12;
          box-shadow: 0 0 3px @nord12;
        }

        /* Buttons */
        button {
          background-color: @nord2;
          color: @nord4;
          border: 1px solid @nord3;
        }

        button:hover {
          background-color: @nord12;
          color: @nord0;
        }

        /* Toolbar and headerbar */
        headerbar,
        toolbar {
          background-color: @nord1;
          color: @nord4;
          border-bottom: 1px solid @nord3;
        }

        /* Menu and context menus */
        menu,
        .menu {
          background-color: @nord1;
          color: @nord4;
          border: 1px solid @nord3;
        }

        menuitem:hover {
          background-color: @nord12;
          color: @nord0;
        }

        /* Selection highlighting */
        *:selected {
          background-color: @nord12;
          color: @nord0;
        }

        /* Scrollbars */
        scrollbar slider {
          background-color: @nord3;
        }

        scrollbar slider:hover {
          background-color: @nord12;
        }

        /* File icons in grid/list view */
        .view {
          background-color: @nord0;
          color: @nord4;
        }

        /* Path bar */
        .path-bar button {
          background-color: @nord2;
          color: @nord4;
        }

        .path-bar button:hover {
          background-color: @nord12;
          color: @nord0;
        }
      '';

      "gtk-4.0/settings.ini".text = ''
        [Settings]
        gtk-application-prefer-dark-theme=1
        gtk-theme-name=Juno
        gtk-icon-theme-name=Papirus-Dark
        gtk-font-name=MesloLGS NF 11
      '';

      # GTK 4.0 CSS (same styling)
      "gtk-4.0/gtk.css".text = ''
        /* Same Nord styling for GTK4 apps */
        
        @define-color nord0 #2E3440;
        @define-color nord1 #3B4252;
        @define-color nord2 #434C5E;
        @define-color nord3 #4C566A;
        @define-color nord4 #D8DEE9;
        @define-color nord12 #D08770;

        window {
          background-color: @nord0;
          color: @nord4;
        }

        .sidebar {
          background-color: @nord1;
          color: @nord4;
          font-weight: normal;
        }

        .sidebar:selected {
          background-color: @nord12;
          color: @nord0;
        }

        button:hover,
        *:selected {
          background-color: @nord12;
          color: @nord0;
        }
      '';

      "user-avatars/king-${userConfig.username}.png".source = processedKing;
      
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

      # LightDM Configuration with Juno Theme
      "lightdm/lightdm-gtk-greeter.conf".source = lib.mkForce (pkgs.writeText "lightdm-gtk-greeter.conf" ''
        [greeter]
        background=${inputs.self}/assets/wallpaper.png
        theme-name=Juno
        icon-theme-name=Papirus-Dark
        font-name=MesloLGS NF 11
        position=50%,center 50%,center
        gtk-application-prefer-dark-theme=true
      '');

      "lightdm-juno-theme-override" = {
        target = "gsettings/schemas/lightdm.gschema.override/99_juno-theme.gschema.override";
        source = pkgs.writeText "juno-theme.gschema.override" ''
          [org.gnome.desktop.interface]
          gtk-theme='Juno'
          icon-theme='Papirus-Dark'
          font-name='MesloLGS NF 11'
        '';
      };
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
        "XDG_DATA_DIRS=/etc/gsettings/schemas/lightdm.gschema.override"
        "XDG_DATA_DIRS+=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
        "XDG_DATA_DIRS+=${pkgs.juno-theme}/share"
        "XDG_DATA_DIRS+=${pkgs.papirus-icon-theme}/share"
        "XDG_DATA_DIRS+=/run/current-system/sw/share"
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
        ln -sf /etc/lightdm/lightdm-gtk-greeter.conf ~/.config/lightdm/lightdm-gtk-greeter.conf
      '';
    };

    activationScripts.compileGreeterGSettings = ''
      echo "Compiling GSettings schemas for LightDM Greeter..."
      ${pkgs.glib}/bin/glib-compile-schemas /etc/gsettings/schemas/lightdm.gschema.override/ &> /dev/null || true
    '';
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
