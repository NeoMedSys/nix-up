{ config, pkgs, lib, inputs, isLaptop ? true, hasGPU ? true, user ? "algol", userSpecifiedBrowsers ? [ "brave" ], ... }:

let
  processedKing = pkgs.runCommand "king-processed.png" {
    buildInputs = [ pkgs.imagemagick ];
  } ''
    convert ${inputs.self}/assets/king.png \
      -gravity center -resize 96x96^ -extent 96x96 $out
  '';
in
{
  # Bootloader
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Time and Localization
  time.timeZone = "Europe/Amsterdam";

  i18n = {
    supportedLocales = [ "en_US.UTF-8/UTF-8" "nb_NO.UTF-8/UTF-8" ];
    defaultLocale = "en_US.UTF-8";
  };

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  # Services
  # Services
  services = {
    # X-Server and Window Manager
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        options = "eurosign:e,caps:escape";
      };
      windowManager.i3.enable = true;

      displayManager = {
        lightdm = {
          enable = true;
          greeters.gtk.enable = true;
        };
      };
    };

    displayManager = {
      defaultSession = "none+i3";
    };

    # Audio
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
  # User Accounts and Permissions
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "docker" ];
    shell = pkgs.zsh;
    packages = with pkgs; [ tree ];
    homeMode = "0751";
  };

  security = {
    sudo.extraRules = [{
      users = [ user ];
      commands = [{
        command = "ALL";
        options = [ "NOPASSWD" "NOSETENV" ];
      }];
    }];
    rtkit.enable = true;
  };

  # Networking
  networking = {
    networkmanager.enable = true;
    nameservers = [ "1.1.1.1" "1.0.0.1" "8.8.8.8" "8.8.4.4" ];
    firewall.allowedTCPPorts = [ 7775 ];
  };

  # System Environment
  environment = {
    systemPackages = with pkgs; [
      stremio
    ] ++ map (browser: pkgs.${browser}) userSpecifiedBrowsers;
    
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    etc."user-avatars/king-${user}.png".source = processedKing;
  };

  # Nix and Nixpkgs Configuration
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

  # Hardware and Power Management
  powerManagement = lib.mkIf isLaptop {
    enable = true;
    cpuFreqGovernor = "powersave";
  };

  hardware = {
    bluetooth.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  # Virtualisation
  virtualisation.docker = {
    enable = true;
    enableNvidia = hasGPU;
  };

  # System Scripts
  system.userActivationScripts.king = ''
    cp ${config.environment.etc."user-avatars/king-${user}.png".source} /home/${user}/.face
    chmod 644 /home/${user}/.face
  '';

  systemd.services.display-manager.serviceConfig = {
    Environment = [
    "XDG_DATA_DIRS=/etc/gsettings/schemas/lightdm.gschema.override"
    "XDG_DATA_DIRS+=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
    "XDG_DATA_DIRS+=${pkgs.arc-theme}/share"
    "XDG_DATA_DIRS+=${pkgs.arc-icon-theme}/share"
    "XDG_DATA_DIRS+=/run/current-system/sw/share"
    ];
  };

  system.activationScripts.compileGreeterGSettings = ''
    echo "Compiling GSettings schemas for LightDM Greeter..."
    ${pkgs.glib}/bin/glib-compile-schemas /etc/gsettings/schemas/lightdm.gschema.override/ &> /dev/null || true
  '';
}
