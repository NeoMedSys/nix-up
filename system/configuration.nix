{ lib, inputs, userConfig, ... }:
{
  imports = [
    # Hardware and disk configuration
    "${inputs.self}/system/hardware-configuration.nix"
    # "${inputs.self}/system/disko-config.nix"

    # Core system modules - pass userConfig to modules that need it
    ({ ... }: {
      _module.args = { inherit userConfig; };
    })
    # Core system modules
    "${inputs.self}/modules/environment.nix"
    "${inputs.self}/modules/system-packages.nix"
    "${inputs.self}/modules/zsh.nix"
    "${inputs.self}/modules/nixvim.nix"
    "${inputs.self}/modules/ssh-config.nix"
    "${inputs.self}/modules/lid-close.nix"
    "${inputs.self}/modules/sway.nix"
    # "${inputs.self}/modules/lightdm.nix"

    # Desktop environment
    "${inputs.self}/modules/i3.nix"
    # "${inputs.self}/modules/redshift.nix"
    "${inputs.self}/modules/gammastep.nix"
    "${inputs.self}/modules/lightdm-transparent-theme.nix"

    # Gaming
    "${inputs.self}/modules/steam.nix"

    # General programming languages
    "${inputs.self}/modules/gpl.nix"

    # Privacy matter
    "${inputs.self}/modules/privacy.nix"
    "${inputs.self}/modules/techoverlord_protection.nix"
    "${inputs.self}/modules/app-telemetry-deny.nix"


  # Conditionally import nvidia.nix based on the hasGPU flag
  ] ++ lib.optionals userConfig.hasGPU [
    "${inputs.self}/modules/nvidia.nix"
  ] ++ lib.optionals userConfig.vpn [
      "${inputs.self}/modules/vpn.nix"
  ];

  # System identification
  networking.hostName = userConfig.hostname;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System state version - NEVER change this after initial install
  system.stateVersion = "25.05";
}
