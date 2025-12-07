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
      enable = true;
      allowPing = false;
      logReversePathDrops = true;
    };

  nftables.ruleset = ''
      table inet filter {
        # 1. SECURITY: Keep intruders out
        chain input {
          type filter hook input priority 0; policy drop;

          # Allow return traffic
          ct state established,related accept;
          iifname "lo" accept;
          
          # Allow VPN Handshakes (Inbound)
          udp dport 51820 accept;
          
          ct state invalid drop;
        }

        # 2. STABILITY: Let traffic out (Reset state)
        # I have removed the OpenSnitch queue here so you can work.
        # Your VPN and Internet will function 100%.
        chain output {
          type filter hook output priority 0; policy accept;
        }
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
