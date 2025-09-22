{ pkgs, lib, inputs, userConfig, ... }:

lib.mkIf userConfig.vpn {
  networking.wireguard.enable = true;

  # Use environment.etc to manage the config file declaratively
  environment.etc."wireguard/mullvad.conf" = {
    #source = /home/${userConfig.username}/perseus/configs/mullvad-config/dk-cph-wg-001.conf;
    source = "${inputs.self}/configs/mullvad-config/dk-cph-wg-001.conf";
    mode = "0600";
  };

  networking.wg-quick.interfaces.mullvad = {
    configFile = "/etc/wireguard/mullvad.conf";
  };

  systemd.services.wg-quick-mullvad.wantedBy = lib.mkForce [ ];

  # OpenSnitch compatibility: Exempt WireGuard traffic from inspection
  systemd.services.mullvad-opensnitch-exempt = {
    description = "Exempt Mullvad VPN from OpenSnitch inspection";
    after = [ "wg-quick-mullvad.service" ];
    partOf = [ "wg-quick-mullvad.service" ];
    requires = [ "wg-quick-mullvad.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "add-mullvad-exemption" ''
        # Add rules to exempt Mullvad traffic from OpenSnitch queuing
        # These must be inserted BEFORE the OpenSnitch queue rule
        ${pkgs.nftables}/bin/nft insert rule inet raw output ip daddr 45.129.56.67 udp dport 51820 accept
        ${pkgs.nftables}/bin/nft insert rule inet raw output ip saddr 45.129.56.67 udp sport 51820 accept
        echo "Added OpenSnitch exemption rules for Mullvad VPN"
      '';
      ExecStop = pkgs.writeShellScript "remove-mullvad-exemption" ''
        # Remove the exemption rules when VPN stops
        ${pkgs.nftables}/bin/nft delete rule inet raw output ip daddr 45.129.56.67 udp dport 51820 accept 2>/dev/null || true
        ${pkgs.nftables}/bin/nft delete rule inet raw output ip saddr 45.129.56.67 udp sport 51820 accept 2>/dev/null || true
        echo "Removed OpenSnitch exemption rules for Mullvad VPN"
      '';
    };
  };

  environment.systemPackages = with pkgs; [
    wireguard-tools
    (writeShellScriptBin "mullvad-toggle" ''
      if systemctl is-active --quiet wg-quick-mullvad; then
        sudo systemctl stop wg-quick-mullvad
        echo "VPN disconnected"
      else
        sudo systemctl start wg-quick-mullvad
        # Start the OpenSnitch exemption service
        sudo systemctl start mullvad-opensnitch-exempt
        echo "VPN connected"
      fi
    '')
    (writeShellScriptBin "mullvad-status" ''
      if systemctl is-active --quiet wg-quick-mullvad; then
        echo "Connected"
        # Show if OpenSnitch exemption is active
        if systemctl is-active --quiet mullvad-opensnitch-exempt; then
          echo "OpenSnitch exemption: Active"
        else
          echo "OpenSnitch exemption: Inactive"
        fi
      else
        echo "Disconnected"
      fi
    '')
  ];
}
