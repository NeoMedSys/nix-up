{ pkgs, lib, userConfig, config, ... }:

{
  networking.wireguard.enable = true;
  systemd.tmpfiles.rules = [
    "L+ /etc/wireguard/mullvad.conf 0600 root systemd-network - ${config.sops.secrets.mullvad-conf.path}"
  ];

  networking.wg-quick.interfaces.mullvad = {
    configFile = "/etc/wireguard/mullvad.conf";
    postUp = [''
      ${pkgs.procps}/bin/sysctl -w net.ipv4.conf.all.src_valid_mark=1
    ''];
    autostart = true;
  };

  # Use this if debugging mullvad setup is necessary
  # systemd.services.wg-quick-mullvad.wantedBy = lib.mkForce [ ];
  systemd.services.wg-quick-mullvad.wantedBy = [ "multi-user.target" ];

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
