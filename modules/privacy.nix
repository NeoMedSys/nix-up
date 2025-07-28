{ config, pkgs, lib, ... }:
{
  # DNS Privacy with dnscrypt-proxy2
  services.dnscrypt-proxy2 = {
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
          via = [ "anon-cs-fr" "anon-cs-ireland" ];
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
      wifi.macAddress = "random";
      ethernet.macAddress = "random";
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

    # declare all your raw & filter rules in nftables DSL
    nftables.ruleset = ''
    table inet filter {
      # This chain handles all incoming traffic
      chain input {
        type filter hook input priority 0; policy drop;

        # Allow established and related connections (essential for return traffic)
        ct state established,related accept

        # Allow traffic on the loopback interface (localhost)
        iifname "lo" accept

        # Allow incoming WireGuard traffic from Mullvad
        udp dport 51820 accept

        # Drop invalid packets
        ct state invalid drop
      }

      # This chain handles all outgoing traffic
      chain output {
        # The typo is corrected here from 'input' to 'output'
        type filter hook output priority 0; policy accept;
      }
    }

    # This table sends non-root traffic to OpenSnitch for inspection
    table inet raw {
      chain output {
        type filter hook output priority -300; policy accept;
        # This will queue all outbound traffic from non-root users for OpenSnitch
        # If OpenSnitch isn't running, this can block traffic.
        meta skuid != 0 queue num 0 bypass
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
  
  # Privacy-focused browser settings (for when browsers are launched)
  programs.firefox = {
    enable = false;
    # If someone installs Firefox, these policies apply
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableFirefoxAccounts = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      DontCheckDefaultBrowser = true;
    };
  };
}
