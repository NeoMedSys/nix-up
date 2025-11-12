{ config, pkgs, lib, inputs, userConfig ? null, ... }:
let
  processedKing = pkgs.runCommand "king-processed.png" {
    buildInputs = [ pkgs.imagemagick ];
  } ''
    convert ${inputs.self}/${userConfig.avatarPath} \
      -gravity center -resize 96x96^ -extent 96x96 $out
  '';
  resolvConfForSandbox = pkgs.writeText "resolv.conf" ''
    nameserver 1.1.1.1
    nameserver 8.8.8.8
  '';
in
{
  # Inject the resolv into the Nix build sandbox env
  nix.settings.extra-sandbox-paths = [
    "/etc/resolv.conf=${resolvConfForSandbox}"
  ];
  # ========================
  # BOOT CONFIGURATION
  # ========================
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelParams = [
      "mem_sleep_default=deep"
    ];
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

    dbus.enable = true;

    # let clammy handle lid actions
    logind = {
      lidSwitch = "ignore";
      lidSwitchDocked = "ignore";
      lidSwitchExternalPower = "ignore";
      extraConfig = ''
      IdleAction = "ignore";
      '';
    };

    # Power Management
    tlp = {
      enable = true;
      settings = {
        RESTORE_DEVICE_STATE_ON_STARTUP = 1;
        DEVICES_TO_DISABLE_ON_STARTUP = "";
        TLP_LID_SWITCH_AC = "ignore";
        TLP_LID_SWITCH_BAT = "ignore";
      };
    };
    gnome.gnome-keyring.enable = true;
    # TLP is primary
    upower.enable = false;

    # Security
    opensnitch = {
      enable = true;
      settings = {
        LogLevel = 3;
      };
    };
    fprintd.enable = true;

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
    polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "net.reactivated.fprint.device.enroll" &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
        }
      });

      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.login1.suspend" &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
        }
      });
    '';
  };

  # ========================
  # NETWORKING
  # ========================
  networking = {
    networkmanager = {
      enable = true;
    };
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
      MOZ_ENABLE_WAYLAND = "1";
      XDG_CURRENT_DESKTOP = "sway";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "sway";
      XCURSOR_THEME = "Bibata-Modern-Amber";
      XCURSOR_SIZE = "24";
      GST_PLUGIN_PATH = "/run/current-system/sw/lib/gstreamer-1.0";
      PIPEWIRE_LATENCY = "256/48000";
    };
    etc = {
      "boltd.conf".text = ''
        [Daemon]
        AuthorizationMode = automatic
      '';
      # Fusuma gesture configuration (replacing libinput-gestures)
      "fusuma/config.yml".text = ''
        swipe:
          3:
            left:
              command: "swaymsg workspace next"
            right:
              command: "swaymsg workspace prev"
          4:
            up:
              command: "rofi -show drun"
            down:
              command: "swaymsg '[con_id=__focused__] scratchpad show' || swaymsg 'workspace back_and_forth'"
            left:
              command: "swaymsg workspace next"
            right:
              command: "swaymsg workspace prev"
        pinch:
          2:
            in:
              command: "swaymsg '[con_id=__focused__] fullscreen toggle'"
            out:
              command: "swaymsg '[con_id=__focused__] floating toggle'"
        hold:
          4:
            command: "rofi -show window"
        threshold:
          swipe: 0.4
          pinch: 0.4
        interval:
          swipe: 0.8
          pinch: 0.1
      '';
      # for ssh agent
      "gnupg/scdaemon.conf".text = ''
        disable-ccid
      '';
      # Global GTK Dark Theme Configuration
      "gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-application-prefer-dark-theme=1
        gtk-theme-name=Juno
        gtk-icon-theme-name=Papirus-Dark
        gtk-font-name=MesloLGS NF 11
        gtk-cursor-theme-name=Bibata-Modern-Amber
        gtk-cursor-theme-size=24
      '';
      "gtk-3.0/gtk.css".text = ''
        @import url("${inputs.self}/configs/gtk-theme/gtk.css");
      '';
      "gtk-4.0/settings.ini".text = ''
        [Settings]
        gtk-application-prefer-dark-theme=1
        gtk-theme-name=Juno
        gtk-icon-theme-name=Papirus-Dark
        gtk-font-name=MesloLGS NF 11
        gtk-cursor-theme-name=Bibata-Modern-Amber
      '';
      "gtk-4.0/gtk.css".text = ''
        @import url("${inputs.self}/configs/gtk-theme/gtk.css");
      '';
      # User avatars
      "user-avatars/king-${userConfig.username}.png".source = processedKing;
      # Desktop Environment Configs - Wayland only
      "dunst/dunstrc".source = "${inputs.self}/configs/dunst-config/dunstrc";
      "rofi/config.rasi".source = "${inputs.self}/configs/rofi-config/config.rasi";
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
    # Use NixOS's integrated IPU6 support - handles everything automatically
    ipu6 = {
      enable = true;
      platform = "ipu6epmtl";  # Meteor Lake platform for your hardware
    };
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
  # XDG PORTAL CONFIGURATION
  # ========================
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr ];
    config = {
      common = {
        # Don't set default here - let sway.nix handle it
        "org.freedesktop.impl.portal.Camera" = "gtk";
        "org.freedesktop.impl.portal.Screenshot" = "wlr";
        "org.freedesktop.impl.portal.ScreenCast" = "wlr";
      };
    };
  };
  # ========================
  # VIRTUALIZATION
  # ========================
  virtualisation.docker = {
    enable = true;
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

  programs.zsh.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  # ========================
  # SYSTEMD SERVICES
  # ========================
  systemd = {
    services.display-manager.serviceConfig = {
      Environment = [
        "XDG_DATA_DIRS=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
        "XDG_DATA_DIRS+=/run/current-system/sw/share"
        "GTK_DATA_PREFIX=/etc"
        "XDG_CONFIG_DIRS=/etc"
      ];
    };

    # this is for clamshell action with clammy..
    tmpfiles.rules = [
      # Disable lid switch as wakeup source to prevent suspend loops
      "w /proc/acpi/wakeup - - - - LID0"
    ];
    services."systemd-rfkill@".enable = false;
    sockets.systemd-rfkill.enable = false;
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
      rofi-configs = ''
        mkdir -p ~/.config/rofi
        ln -sf /etc/rofi/config.rasi ~/.config/rofi/config.rasi
      '';
      fusuma-config = ''
        mkdir -p ~/.config/fusuma
        ln -sf /etc/fusuma/config.yml ~/.config/fusuma/config.yml
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
}
