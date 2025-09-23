{ pkgs, lib, userConfig, config, ... }:

lib.mkIf userConfig.vpn {
  networking.wireguard.enable = true;

  # sops-nix will create this file for us using the decrypted secret.
  # We just need to grant it the right permissions.
  systemd.tmpfiles.rules = [
    "f /etc/wireguard/mullvad.conf 0600 root systemd-network - ${config.sops.secrets.mullvad-conf.path}"
  ];

  networking.wg-quick.interfaces.mullvad = {
    configFile = "/etc/wireguard/mullvad.conf";
  };

  # Ensure the wg-quick service doesn't start automatically on boot.
  systemd.services.wg-quick-mullvad.wantedBy = lib.mkForce [ ];

  # Install helper scripts for toggling and status checks.
  environment.systemPackages = with pkgs; [
    wireguard-tools
    (writeShellScriptBin "mullvad-toggle" ''
      if systemctl is-active --quiet wg-quick-mullvad; then
        sudo systemctl stop wg-quick-mullvad
        echo "VPN disconnected"
      else
        sudo systemctl start wg-quick-mullvad
        echo "VPN connected"
      fi
    '')
    (writeShellScriptBin "mullvad-status" ''
      if systemctl is-active --quiet wg-quick-mullvad; then
        echo "Connected"
      else
        echo "Disconnected"
      fi
    '')
  ];
}
