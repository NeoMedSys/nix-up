{ config, pkgs, lib, ... }:
{
  # Mullvad WireGuard VPN configuration
  networking.wg-quick.interfaces = {
    mullvad = {
      # You'll replace these after signing up for Mullvad
      privateKey = "9265403239803778";
      address = [ "10.64.0.1/32" "fc00:bbbb:bbbb:bb01::1/128" ];
      dns = [ "127.0.0.1" ];  # Keep using your dnscrypt-proxy2

      peers = [{
        # Example Mullvad server - replace with your preferred server
        publicKey = "MULLVAD_SERVER_PUBLIC_KEY_HERE";
        allowedIPs = [ "0.0.0.0/0" "::/0" ];
        endpoint = "mullvad-server.example.com:51820";
      }];

      # Auto-detect local subnet and preserve local access
      postUp = ''
        LOCAL_SUBNET=$(${pkgs.iproute2}/bin/ip route show | ${pkgs.gnugrep}/bin/grep -E "192\.168\.|10\.|172\." | ${pkgs.gawk}/bin/awk '{print $1}' | head -1)
        ${pkgs.iptables}/bin/iptables -I OUTPUT 1 -d $LOCAL_SUBNET -j ACCEPT
        ${pkgs.iptables}/bin/iptables -I OUTPUT 2 ! -o %i -m mark ! --mark $(${pkgs.wireguard-tools}/bin/wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT
      '';

      preDown = ''
        LOCAL_SUBNET=$(${pkgs.iproute2}/bin/ip route show | ${pkgs.gnugrep}/bin/grep -E "192\.168\.|10\.|172\." | ${pkgs.gawk}/bin/awk '{print $1}' | head -1)
        ${pkgs.iptables}/bin/iptables -D OUTPUT -d $LOCAL_SUBNET -j ACCEPT
        ${pkgs.iptables}/bin/iptables -D OUTPUT ! -o %i -m mark ! --mark $(${pkgs.wireguard-tools}/bin/wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT
      '';
    };
  };

  # Service doesn't auto-start (on-demand only)
  systemd.services.wg-quick-mullvad = {
    wantedBy = lib.mkForce [ ];
  };

  # Helper script for easy management
  environment.systemPackages = with pkgs; [
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
        SERVER=$(wg show mullvad endpoint 2>/dev/null | cut -d':' -f1)
        echo "Connected to $SERVER"
      else
        echo "Disconnected"
      fi
    '')
  ];
}
