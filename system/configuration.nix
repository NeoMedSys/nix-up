{ config, lib, pkgs, inputs, isLaptop, hasGPU, user, userSpecifiedBrowsers, ... }:
{
  imports = [
    # Hardware and disk configuration
    "${inputs.self}/system/hardware-configuration.nix"
    # "${inputs.self}/system/disko-config.nix"

    # Core system modules
    "${inputs.self}/modules/environment.nix"
    "${inputs.self}/modules/system-packages.nix"
    "${inputs.self}/modules/zsh.nix"
    "${inputs.self}/modules/nixvim.nix"
    "${inputs.self}/modules/ssh-config.nix"

    # Desktop environment
    "${inputs.self}/modules/i3.nix"

    # Gaming
    "${inputs.self}/modules/steam.nix"

    # General programming languages
    "${inputs.self}/modules/gpl.nix"

    # Privacy matter
    "${inputs.self}/modules/privacy.nix"
    "${inputs.self}/modules/techoverlord_protection.nix"


  # Conditionally import nvidia.nix based on the hasGPU flag
  ] ++ lib.optionals hasGPU [
    "${inputs.self}/modules/nvidia.nix"
  ] ++ [
    # VPN (currently disabled)
    # "${inputs.self}/modules/expressvpn.nix"
  ];

  # System identification
  networking.hostName = "perseus";

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System state version - NEVER change this after initial install
  system.stateVersion = "25.05";
}
