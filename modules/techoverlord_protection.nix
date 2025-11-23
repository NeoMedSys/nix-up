{ pkgs, userConfig, config, ... }:
let
  nastyTechLords = pkgs.callPackage ../pkgs/ntl.nix {};

  ntlCli = pkgs.writeShellScriptBin "ntl" ''
    #!/usr/bin/env bash
    
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'

    BINARY="${nastyTechLords}/bin/nasty-tech-lords"
    LOG_DIR="/var/log/nastyTechLords"

    show_help() {
        echo -e "''${GREEN}NastyTechLords Security Monitor (Rust Edition)''${NC}"
        echo -e "Protection against the tech overlords! 🛡️\n"
        echo -e "''${YELLOW}Usage:''${NC} ntl [command]"
        echo ""
        echo -e "''${YELLOW}Commands:''${NC}"
        echo -e "  ''${BLUE}run''${NC}              Run security audit now"
        echo -e "  ''${BLUE}run --full''${NC}       Run with deep inspection (Nix store)"
        echo -e "  ''${BLUE}status''${NC}           Show daemon status"
        echo -e "  ''${BLUE}report''${NC}           View latest audit summary"
        echo -e "  ''${BLUE}logs''${NC}             Follow live system logs"
        echo ""
    }

    case "$1" in
        run)
            echo -e "''${GREEN}🛡️  Starting NastyTechLords Audit...''${NC}"
            if [ "$2" = "--full" ]; then
                sudo $BINARY --full --verbose
            else
                sudo $BINARY --verbose
            fi
            ;;
        status)
            echo -e "''${GREEN}Daemon Status:''${NC}"
            sudo systemctl status nastyTechLords.timer --no-pager
            ;;
        report)
            if [ -f "$LOG_DIR/latest-summary.txt" ]; then
                cat "$LOG_DIR/latest-summary.txt"
            else
                # Fallback to finding the newest log
                LATEST=$(ls -t $LOG_DIR/audit-*.log 2>/dev/null | head -1)
                if [ -n "$LATEST" ]; then
                    cat "$LATEST"
                else
                    echo "No reports found."
                fi
            fi
            ;;
        logs)
            sudo journalctl -u nastyTechLords -f
            ;;
        *)
            show_help
            ;;
    esac
  '';
  
  uid = toString config.users.users.${userConfig.username}.uid;
in
{
  environment.systemPackages = [
    nastyTechLords
    ntlCli
  ];

  systemd.services.nastyTechLords = {
    description = "NastyTechLords Security Audit Daemon";
    serviceConfig = {
        Type = "oneshot";
        ExecStart = "${nastyTechLords}/bin/nasty-tech-lords";
        
        StandardOutput = "journal";
        StandardError = "journal";

        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        User = "root"; 

        ReadWritePaths = [ "/var/log/nastyTechLords" ];
        Environment = [
             "DISPLAY=:0"
             "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${uid}/bus"
        ];
    };
  };

  systemd.timers.nastyTechLords = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
        OnBootSec = "10min";
        OnUnitActiveSec = "6h";
        RandomizedDelaySec = "30min";
        Persistent = true;
    };
  };

  systemd.tmpfiles.rules = [
      "d /var/log/nastyTechLords 0750 root wheel -"
  ];

  users.users.${userConfig.username}.extraGroups = [ "wheel" ];
}
