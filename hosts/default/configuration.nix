{ lib, inputs, userConfig, pkgs, ... }:
{
  imports = [
    "${inputs.self}/hosts/default/hardware-configuration.nix"
    ({ ... }: { _module.args = { inherit userConfig; }; })
    inputs.dms.nixosModules.default
    # ── Always loaded ──
    "${inputs.self}/modules/system/environment.nix"
    "${inputs.self}/modules/system/system-packages.nix"
    "${inputs.self}/modules/system/greetd.nix"
    "${inputs.self}/modules/system/niri.nix"
    "${inputs.self}/modules/system/dms.nix"
    "${inputs.self}/modules/system/zsh.nix"
    "${inputs.self}/modules/system/notify.nix"
    "${inputs.self}/modules/security/privacy.nix"
    "${inputs.self}/modules/security/techoverlord_protection.nix"
    "${inputs.self}/modules/security/app-telemetry-deny.nix"
    "${inputs.self}/modules/security/firejail.nix"
    "${inputs.self}/modules/security/ssh-config.nix"
    "${inputs.self}/modules/dev/nixvim.nix"
    "${inputs.self}/modules/dev/gpl.nix"
  # ── Conditional ──
  ] ++ lib.optionals (userConfig.isLaptop or false) [
    "${inputs.self}/modules/hardware/clammy.nix"
  ] ++ lib.optionals (userConfig.thunderbolt or false) [
    "${inputs.self}/modules/hardware/thunderbolt-ethernet.nix"
  ] ++ lib.optionals (userConfig.hasGPU or false) [
    "${inputs.self}/modules/hardware/nvidia.nix"
  ] ++ lib.optionals (userConfig.vpn or false) [
    "${inputs.self}/modules/security/vpn.nix"
    "${inputs.self}/modules/security/secrets.nix"
  ] ++ lib.optionals (userConfig.email or false) [
    "${inputs.self}/modules/apps/thunderbird.nix"
  ] ++ lib.optionals ((userConfig.flatpakApps or []) != []) [
    "${inputs.self}/modules/apps/flatpak.nix"
  ];

  networking.hostName = userConfig.hostname;
  networking.hosts = lib.mkIf (userConfig ? extraHosts) userConfig.extraHosts;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.05";
}
