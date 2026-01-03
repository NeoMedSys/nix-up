{ lib, inputs, userConfig, ... }:
{
  imports = [
    # Hardware and disk configuration
    "${inputs.self}/system/hardware-configuration.nix"

    # Core system modules - pass userConfig to modules that need it
    ({ ... }: {
      _module.args = { inherit userConfig; };
    })
    inputs.dms.nixosModules.default
    # Core system modules
    "${inputs.self}/modules/environment.nix"
    "${inputs.self}/modules/system-packages.nix"
    "${inputs.self}/modules/nixvim.nix"
    "${inputs.self}/modules/ssh-config.nix"
    "${inputs.self}/modules/sway.nix"
    "${inputs.self}/modules/niri.nix"
    "${inputs.self}/modules/dms.nix"
    "${inputs.self}/modules/thunderbolt-ethernet.nix"
    "${inputs.self}/modules/notify.nix"
    "${inputs.self}/modules/zsh.nix"
    "${inputs.self}/modules/thunderbird.nix"

    # clamshell action
    "${inputs.self}/modules/clammy.nix"

    # General programming languages
    "${inputs.self}/modules/gpl.nix"

    # Privacy matter
    "${inputs.self}/modules/privacy.nix"
    "${inputs.self}/modules/techoverlord_protection.nix"
    "${inputs.self}/modules/app-telemetry-deny.nix"
    "${inputs.self}/modules/greetd.nix"
    "${inputs.self}/modules/usb.nix"
    "${inputs.self}/modules/firejail.nix"

  # Conditionally import nvidia.nix based on the hasGPU flag
  ] ++ lib.optionals userConfig.hasGPU [
    "${inputs.self}/modules/nvidia.nix"
  ] ++ lib.optionals userConfig.vpn [
      "${inputs.self}/modules/vpn.nix"
      "${inputs.self}/modules/secrets.nix"
  ];

  # System identification
  networking.hostName = userConfig.hostname;

  networking.hosts = {
    "10.54.218.134" = [ "access.neomedsys.io" "neocoms.neomedsys.io" "auth.neomedsys.io"];
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs userConfig; };
    users = {
      "${userConfig.username}" = import ../home/default.nix;
    };
    backupFileExtension = "backup";
  };

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System state version - NEVER change this after initial install
  system.stateVersion = "25.05";
}
