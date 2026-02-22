{ lib, inputs, userConfig, pkgs, ... }:
{
  imports = [
    # Hardware
    "${inputs.self}/hosts/perseus/hardware-configuration.nix"

    # Pass userConfig to all modules
    ({ ... }: { _module.args = { inherit userConfig; }; })

    # Shell integration
    inputs.dms.nixosModules.default

    # ========================
    # SYSTEM
    # ========================
    "${inputs.self}/modules/system/environment.nix"
    "${inputs.self}/modules/system/system-packages.nix"
    "${inputs.self}/modules/system/greetd.nix"
    "${inputs.self}/modules/system/niri.nix"
    "${inputs.self}/modules/system/dms.nix"
    "${inputs.self}/modules/system/zsh.nix"
    "${inputs.self}/modules/system/notify.nix"

    # ========================
    # HARDWARE
    # ========================
    "${inputs.self}/modules/hardware/thunderbolt-ethernet.nix"
    "${inputs.self}/modules/hardware/clammy.nix"

    # ========================
    # SECURITY
    # ========================
    "${inputs.self}/modules/security/privacy.nix"
    "${inputs.self}/modules/security/techoverlord_protection.nix"
    "${inputs.self}/modules/security/app-telemetry-deny.nix"
    "${inputs.self}/modules/security/firejail.nix"
    "${inputs.self}/modules/security/ssh-config.nix"

    # ========================
    # APPS
    # ========================
    "${inputs.self}/modules/apps/thunderbird.nix"
    "${inputs.self}/modules/apps/flatpak.nix"

    # ========================
    # DEVELOPMENT
    # ========================
    "${inputs.self}/modules/dev/nixvim.nix"
    "${inputs.self}/modules/dev/gpl.nix"

  # Conditional: GPU
  ] ++ lib.optionals userConfig.hasGPU [
    "${inputs.self}/modules/hardware/nvidia.nix"

  # Conditional: VPN
  ] ++ lib.optionals userConfig.vpn [
    "${inputs.self}/modules/security/vpn.nix"
    "${inputs.self}/modules/security/secrets.nix"
  ];

  # System identification
  networking.hostName = userConfig.hostname;
  networking.hosts = {
    "10.54.218.134" = [ "access.neomedsys.io" "neocoms.neomedsys.io" "auth.neomedsys.io" ];
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # NEVER change after initial install
  system.stateVersion = "25.05";
}
