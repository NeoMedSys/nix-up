{ lib, ... }:
{
  # DNS Privacy with dnscrypt-proxy
  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      # Use multiple resolvers for redundancy
      server_names = [ "cloudflare" "quad9-dnscrypt-ip4-nofilter-pri" ];
      
      # Listen on localhost
      listen_addresses = [ "127.0.0.1:53" "[::1]:53" ];
      
      # Privacy settings
      require_dnssec = true;
      require_nolog = true;
      require_nofilter = false;  # We want filtering
      timeout = 2500;
      keepalive = 30;
      
      # Block lists for ads/trackers/malware
      sources.public-resolvers = {
        urls = [ "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md" ];
        cache_file = "public-resolvers.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
      };
      
      # Additional privacy features
      anonymized_dns.routes = [
        {
          server_name = "cloudflare";
          via = [ "anon-cs-fr" "anon-cs-ireland" "anon-cs-germany" "anon-cs-nl" "anon-cs-se" ];
        }
      ];
    };
  };
  
  # Configure NetworkManager to use dnscrypt-proxy2
  networking = {
    nftables.enable = true;  # for opensnitch
    networkmanager = {
      insertNameservers = [ "127.0.0.1" "::1" ];
      dns = "none";  # Don't let NetworkManager override DNS
      
      # Enable MAC address randomization
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
    
    # Additional firewall hardening
    firewall = {
      enable = false;
      allowPing = false;
      logReversePathDrops = true;
    };

    nftables.ruleset = ''
      # --- TABLE 1: MANGLE (Traffic Control & OpenSnitch) ---
      table inet mangle {
        chain output {
          type route hook output priority mangle; policy accept;

          # [A] CRITICAL BYPASS: VPN INTERFACE
          # Allow applications to talk to the VPN interface locally.
          # Without this, OpenSnitch deadlocks the tunnel.
          oifname "mullvad" accept

          # [B] CRITICAL BYPASS: ENCRYPTED TRANSPORT
          # Allow the encrypted "envelope" to leave your physical card.
          # We allow both standard port (51820) and fallback (443).
          ip daddr 45.129.56.67 accept comment "Bypass: VPN Endpoint IP"
          udp dport { 51820, 443 } accept comment "Bypass: WireGuard Ports"
          meta mark 0xca6c accept comment "Bypass: WireGuard fwmark"

          # [C] SYSTEM ALLOWLIST
          oifname "lo" accept
          meta l4proto { icmp, icmpv6 } accept

          # [D] OPENSNITCH QUEUE
          # Everything else is queued for user approval.
          meta l4proto != tcp ct state related,new queue flags bypass to 0
          tcp flags & (fin | syn | rst | ack) == syn queue flags bypass to 0
        }
      }

      # --- TABLE 2: FILTER (Security & Blocking) ---
      table inet filter {
        chain input {
          type filter hook input priority filter; policy drop;

          # 1. TRUSTED TRAFFIC
          ct state established,related accept
          iifname "lo" accept
          iifname "mullvad" accept

          # 2. VPN RETURN TRAFFIC
          # Accept responses from the VPN server on both likely ports.
          udp sport { 51820, 443 } accept
          ip saddr 45.129.56.67 accept

          # 3. LAN / DHCP
          udp dport { 67, 68 } accept
          ip6 daddr fe80::/64 udp dport 546 accept
          
          # 4. SSH / HTTPS / LOCAL DEV (Your open ports)
          tcp dport { 7889, 443, 7775 } accept
        }

        chain output {
          type filter hook output priority filter; policy accept;

          ct state established,related accept
          # [NEW] BLOCK DIRECT DNS LEAKS - force all DNS through localhost
          udp dport 53 ip daddr != 127.0.0.1 drop comment "Block DNS leak: IPv4"
          tcp dport 53 ip daddr != 127.0.0.1 drop comment "Block DNS leak: IPv4 TCP"
          udp dport 53 ip6 daddr != ::1 drop comment "Block DNS leak: IPv6"
          tcp dport 53 ip6 daddr != ::1 drop comment "Block DNS leak: IPv6 TCP"

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
    # Disable .NET telemetry
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    
    # Disable PowerShell telemetry
    POWERSHELL_TELEMETRY_OPTOUT = "1";
    
    # Disable Homebrew analytics
    HOMEBREW_NO_ANALYTICS = "1";
    
    # Disable Next.js telemetry
    NEXT_TELEMETRY_DISABLED = "1";
    
    # Disable Gatsby telemetry
    GATSBY_TELEMETRY_DISABLED = "1";
    
    # Disable Azure Functions Core Tools telemetry
    FUNCTIONS_CORE_TOOLS_TELEMETRY_OPTOUT = "1";
    
    # Disable VS Code telemetry
    VSCODE_TELEMETRY_LEVEL = "off";
  };
  
  # Kernel hardening
  boot.kernel.sysctl = {
    # Disable IP forwarding
    "net.ipv4.ip_forward" = 0;
    "net.ipv6.conf.all.forwarding" = 0;
    
    # Ignore ICMP redirects
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    
    # Ignore send redirects
    "net.ipv4.conf.all.send_redirects" = 0;
    
    # Disable source packet routing
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    
    # Log Martians
    "net.ipv4.conf.all.log_martians" = 1;
    
    # Ignore ICMP ping requests
    "net.ipv4.icmp_echo_ignore_all" = 1;
    
    # Protection against SYN flood attacks
    "net.ipv4.tcp_syncookies" = 1;

    # # Disable Strict Reverse Path Filtering.
    # Essential for WireGuard to receive handshake packets on physical interface
    "net.ipv4.conf.all.rp_filter" = 2;
    "net.ipv4.conf.default.rp_filter" = 2;
    
    # Disable IPv6 if not needed
    # "net.ipv6.conf.all.disable_ipv6" = 1;
    # "net.ipv6.conf.default.disable_ipv6" = 1;
  };
  
  # Disable unnecessary services that could leak data
  services = {
    # Disable Avahi daemon (mDNS)
    avahi.enable = false;
    
    # Disable location services
    geoclue2.enable = false;
    
    # Disable CUPS browsing
    printing.browsing = false;
  };
  
  # AppArmor for additional application sandboxing
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = true;
  };
  
  # Ensure no swap file/partition is created
  swapDevices = lib.mkForce [ ];

  # Disable swap entirely
  zramSwap.enable = false;
}
