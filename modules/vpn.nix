{ pkgs, lib, userConfig, ... }:

lib.mkIf userConfig.vpn {
  networking.wireguard.enable = true;
  
  networking.wg-quick.interfaces.mullvad = {
    configFile = "/etc/wireguard/dk-cph-wg-001.conf";
  };

  systemd.services.wg-quick-mullvad.wantedBy = lib.mkForce [ ];

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
