{ pkgs, lib, ... }:
let
  # Find the Mullvad config file (expects exactly 1 .conf file)
  mullvadConfigDir = ../configs/mullvad-config;
  configFiles = builtins.attrNames (builtins.readDir mullvadConfigDir);
  confFiles = builtins.filter (name: lib.hasSuffix ".conf" name) configFiles;
  hasConfig = confFiles != [];
  
  configFile = if hasConfig then builtins.head confFiles else "";
  configPath = if hasConfig then mullvadConfigDir + "/${configFile}" else null;
  configContent = if hasConfig then builtins.readFile configPath else "";

  # Parse WireGuard config
  extractValue = regex: content:
    let match = builtins.match regex content;
    in if match != null then builtins.head match else null;

  privateKey = extractValue ".*PrivateKey = ([^\n]+).*" configContent;
  addresses = lib.splitString "," (extractValue ".*Address = ([^\n]+).*" configContent);
  publicKey = extractValue ".*PublicKey = ([^\n]+).*" configContent;
  endpoint = extractValue ".*Endpoint = ([^\n]+).*" configContent;
in
lib.mkIf hasConfig {
  # Mullvad WireGuard VPN configuration
  networking.wg-quick.interfaces = {
    mullvad = {
      privateKey = privateKey;
      address = addresses;
      dns = [ "127.0.0.1" ];  # Keep using your dnscrypt-proxy2

      peers = [{
        publicKey = publicKey;
        allowedIPs = [ "0.0.0.0/0" "::/0" ];
        endpoint = endpoint;
        persistentKeepalive = 25;
      }];
    };
  };

  # Service doesn't auto-start (on-demand only)
  systemd.services.wg-quick-mullvad = {
    wantedBy = lib.mkForce [ ];
  };

  # Helper scripts for easy management
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
        echo "Connected"
      else
        echo "Disconnected"
      fi
    '')
  ];
}
