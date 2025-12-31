{ lib, pkgs, inputs, ... }:
let
  blocklist_txt = pkgs.writeText "blocklist.txt" (builtins.readFile inputs.oisd);
  StateDirName = "dnscrypt-proxy";
  StatePath = "/var/lib/${StateDirName}";
in
{
  # DNS Privacy with dnscrypt-proxy (ODoH)
  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      listen_addresses = [ "127.0.0.1:53" "[::1]:53" ];

      # ODoH servers - relay sees IP but can't decrypt, resolver decrypts but only sees relay
      server_names = [ "odoh-cloudflare" "odoh-crypto-sx" ];
      odoh_servers = true;
      dnscrypt_servers = false;

      sources = {
        odoh-servers = {
          urls = [
            "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/odoh-servers.md"
            "https://download.dnscrypt.info/resolvers-list/v3/odoh-servers.md"
          ];
          cache_file = "${StatePath}/odoh-servers.md";
          minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };
        odoh-relays = {
          urls = [
            "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/odoh-relays.md"
            "https://download.dnscrypt.info/resolvers-list/v3/odoh-relays.md"
          ];
          cache_file = "${StatePath}/odoh-relays.md";
          minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };
      };

      anonymized_dns = {
        skip_incompatible = true;
        routes = [
          { server_name = "odoh-cloudflare"; via = [ "odohrelay-crypto-sx" ]; }
          { server_name = "odoh-crypto-sx"; via = [ "odohrelay-koki-ams" ]; }
        ];
      };

      # Blocklist - ads/trackers/malware
      blocked_names.blocked_names_file = "${blocklist_txt}";

      # Security
      require_dnssec = true;
      require_nolog = true;
      require_nofilter = false;
      timeout = 2500;
      keepalive = 30;

      ipv6_servers = true;
      block_ipv6 = false;
    };
  };

  systemd.services.dnscrypt-proxy2.serviceConfig.StateDirectory = StateDirName;

  # Configure NetworkManager to use dnscrypt-proxy
  networking = {
    nftables.enable = true;
    networkmanager = {
      insertNameservers = [ "127.0.0.1" "::1" ];
      dns = "none";

      # MAC address randomization
      wifi.macAddress = "stable";
      ethernet.macAddress = "stable";
      settings = {
        connection = {
          "wifi.cloned-mac-address" = "random";
          "ethernet.cloned-mac-address" = "random";
        };
        device = {
          "wifi.scan-rand-mac-address" = "yes";
        };
      };
    };

    firewall = {
      enable = false;
      allowPing = false;
      logReversePathDrops = true;
    };

    nftables.ruleset = ''
      table inet mangle {
        chain output {
          type route hook output priority mangle; policy accept;

          oifname "mullvad" accept
          udp dport { 51820, 443 } accept comment "Bypass: WireGuard Ports"
          meta mark 0xca6c accept comment "Bypass: WireGuard fwmark"
          oifname "lo" accept
          meta l4proto { icmp, icmpv6 } accept

          meta l4proto != tcp ct state related,new queue flags bypass to 0
          tcp flags & (fin | syn | rst | ack) == syn queue flags bypass to 0
        }
      }

      table inet filter {
        chain input {
          type filter hook input priority filter; policy accept;
          udp sport 53 queue flags bypass to 0
          ct state invalid drop
        }

        chain output {
          type filter hook output priority filter; policy accept;
          jump opensnitch
        }

        chain opensnitch {}
      }
    '';
  };

  # Fail2ban for intrusion prevention
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "24h";
    bantime-increment.enable = true;

    jails.sshd = lib.mkForce ''
      enabled = true
      port = 7889
      filter = sshd
      maxretry = 3
    '';
  };

  # Disable telemetry in various applications
  environment.variables = {
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    POWERSHELL_TELEMETRY_OPTOUT = "1";
    HOMEBREW_NO_ANALYTICS = "1";
    NEXT_TELEMETRY_DISABLED = "1";
    GATSBY_TELEMETRY_DISABLED = "1";
    FUNCTIONS_CORE_TOOLS_TELEMETRY_OPTOUT = "1";
    VSCODE_TELEMETRY_LEVEL = "off";
  };

  # Kernel hardening
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 0;
    "net.ipv6.conf.all.forwarding" = 0;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.icmp_echo_ignore_all" = 1;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.conf.all.rp_filter" = 2;
    "net.ipv4.conf.default.rp_filter" = 2;
  };

  # Disable unnecessary services
  services = {
    avahi.enable = false;
    geoclue2.enable = false;
    printing.browsing = false;
  };

  # AppArmor
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = true;
  };

  # No swap
  swapDevices = lib.mkForce [ ];
  zramSwap.enable = false;
}
