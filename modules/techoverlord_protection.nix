{ pkgs, userConfig, ... }:
let
  # The main audit script
  nastyTechLordsScript = pkgs.writeShellScriptBin "nastyTechLords" ''
    #!/usr/bin/env bash
    
    # Check for full-check flag
    FULL_CHECK=0
    if [ "$1" = "--full-check" ]; then
      FULL_CHECK=1
    fi
    
    # Colors for output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
    
    # Progress indicator
    TOTAL_STEPS=9  # All regular checks
    if [ "$FULL_CHECK" -eq 1 ]; then
      TOTAL_STEPS=9  # Same steps, but NixOS check is slower
    fi
    CURRENT_STEP=0
    
    show_progress() {
      CURRENT_STEP=$((CURRENT_STEP + 1))
      local PERCENT=$((CURRENT_STEP * 100 / TOTAL_STEPS))
      local FILLED=$((CURRENT_STEP * 20 / TOTAL_STEPS))
      local EMPTY=$((20 - FILLED))
      
      printf "\r[%s%s] %3d%% - %s" \
        "$(printf '▓%.0s' $(seq 1 $FILLED))" \
        "$(printf '░%.0s' $(seq 1 $EMPTY))" \
        "$PERCENT" \
        "$1"
      
      if [ "$CURRENT_STEP" -eq "$TOTAL_STEPS" ]; then
        echo ""  # New line after completion
      fi
    }
    
    # Log file locations
    REPORT_DIR="/var/log/nastyTechLords"
    REPORT_FILE="$REPORT_DIR/audit-$(date +%Y%m%d-%H%M%S).log"
    SUMMARY_FILE="$REPORT_DIR/latest-summary.txt"
    
    # Create report directory
    mkdir -p "$REPORT_DIR"
    
    # Start report
    echo "=== NastyTechLords Security Audit ===" > "$REPORT_FILE"
    echo "Date: $(date)" >> "$REPORT_FILE"
    echo "Hostname: $(hostname)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Initialize warning counter
    WARNINGS=0
    CRITICAL=0
    
    # Function to send desktop notification
    notify_user() {
      local urgency="$1"
      local title="$2"
      local message="$3"
      
      ${pkgs.libnotify}/bin/notify-send \
        --urgency="$urgency" \
        --icon=security-high \
        "NastyTechLords: $title" \
        "$message"
    }
    
    # Check for rootkits
    show_progress "Checking for rootkits..."
    echo "=== Rootkit Check ===" >> "$REPORT_FILE"
    if command -v chkrootkit >/dev/null 2>&1; then
      echo "Running chkrootkit..." >> "$REPORT_FILE"
      echo "Note: NixOS symlinks may show as false positives" >> "$REPORT_FILE"
      
      # Run chkrootkit and filter known false positives on NixOS
      ROOTKIT_OUTPUT=$(${pkgs.chkrootkit}/bin/chkrootkit 2>&1)
      
      # Filter out known NixOS false positives
      FILTERED_OUTPUT=$(echo "$ROOTKIT_OUTPUT" | grep -v "No such file or directory" | \
        grep -v "integer expression expected" | \
        grep -v "The tty of the following user process")
      
      echo "$FILTERED_OUTPUT" >> "$REPORT_FILE"
      
      # Check for real infections (exclude ALL common NixOS false positives)
      # Filter out standalone INFECTED lines that follow NixOS commands
      REAL_INFECTIONS=$(echo "$ROOTKIT_OUTPUT" | \
        awk '/Checking `(basename|date|dirname|echo|env)/ {getline; next} /INFECTED/ {print}')
      if [ -n "$REAL_INFECTIONS" ]; then
        ((CRITICAL++))
        notify_user critical "ROOTKIT DETECTED!" "Possible rootkit infection found!"
        echo "REAL INFECTIONS FOUND:" >> "$REPORT_FILE"
        echo "$REAL_INFECTIONS" >> "$REPORT_FILE"
      else
        echo "No real infections detected (NixOS false positives filtered)" >> "$REPORT_FILE"
      fi
    fi
    
    # Check for suspicious network connections
    show_progress "Scanning network connections..."
    echo -e "\n=== Suspicious Network Connections ===" >> "$REPORT_FILE"

    SUSPICIOUS_PORTS=$(${pkgs.nettools}/bin/netstat -tulpn 2>/dev/null | grep -E ':(6666|6667|31337|12345|4444|5555|9999)')

    if [ -n "$SUSPICIOUS_PORTS" ]; then
      echo "WARNING: Suspicious ports detected:" >> "$REPORT_FILE"
      echo "$SUSPICIOUS_PORTS" >> "$REPORT_FILE"
      ((WARNINGS++))
      notify_user normal "Suspicious Ports" "Unusual network ports detected"
    else
      echo "No suspicious ports detected" >> "$REPORT_FILE"
    fi
    
    # Check for unauthorized SSH keys
    show_progress "Auditing SSH keys..."
    echo -e "\n=== SSH Key Audit ===" >> "$REPORT_FILE"
    for user_home in /home/*; do
      if [ -f "$user_home/.ssh/authorized_keys" ]; then
        KEY_COUNT=$(wc -l < "$user_home/.ssh/authorized_keys")
        echo "User $(basename $user_home): $KEY_COUNT authorized keys" >> "$REPORT_FILE"
        # Check for suspicious key comments
        if grep -q -E "(hack|pwn|0wn|backdoor)" "$user_home/.ssh/authorized_keys" 2>/dev/null; then
          ((WARNINGS++))
          notify_user normal "Suspicious SSH Key" "Unusual SSH key comment detected"
        fi
      fi
    done
    
    # Check failed login attempts
    show_progress "Checking login attempts..."
    echo -e "\n=== Failed Login Attempts ===" >> "$REPORT_FILE"
    FAILED_LOGINS=$(journalctl -u sshd --since "24 hours ago" 2>/dev/null | grep -c "Failed password")
    echo "Failed SSH logins in last 24h: $FAILED_LOGINS" >> "$REPORT_FILE"
    if [ "$FAILED_LOGINS" -gt 50 ]; then
      ((WARNINGS++))
      notify_user normal "Brute Force Attempt?" "$FAILED_LOGINS failed SSH logins in 24h"
    fi
    
    # Check for suspicious processes
    show_progress "Scanning processes..."
    echo -e "\n=== Process Audit ===" >> "$REPORT_FILE"
    SUSPICIOUS_PROCS=$(ps aux | grep -E "(nc -l|/dev/tcp/|sh -i|bash -i)" | grep -v grep)
    if [ -n "$SUSPICIOUS_PROCS" ]; then
      echo "WARNING: Suspicious processes detected:" >> "$REPORT_FILE"
      echo "$SUSPICIOUS_PROCS" >> "$REPORT_FILE"
      ((WARNINGS++))
      notify_user normal "Suspicious Process" "Unusual process activity detected"
    else
      echo "No suspicious processes detected" >> "$REPORT_FILE"
    fi
    
    # Check for world-writable files in sensitive directories
    show_progress "Checking file permissions..."
    echo -e "\n=== File Permission Audit ===" >> "$REPORT_FILE"
    WRITABLE_FILES=$(find /etc /usr/bin /usr/sbin -type f -perm -002 2>/dev/null | head -20)
    if [ -n "$WRITABLE_FILES" ]; then
      echo "WARNING: World-writable files in system directories:" >> "$REPORT_FILE"
      echo "$WRITABLE_FILES" >> "$REPORT_FILE"
      ((WARNINGS++))
    else
      echo "No world-writable files in system directories" >> "$REPORT_FILE"
    fi
    
    # Run Lynis audit (if available)
    show_progress "Running Lynis security audit..."
    if command -v lynis >/dev/null 2>&1; then
      echo -e "\n=== Lynis Security Audit ===" >> "$REPORT_FILE"
      ${pkgs.lynis}/bin/lynis audit system --quiet --no-colors >> "$REPORT_FILE" 2>&1
      
      # Check Lynis warnings
      LYNIS_WARNINGS=$(grep -c "Warning" "$REPORT_FILE" || true)
      if [ "$LYNIS_WARNINGS" -gt 10 ]; then
        ((WARNINGS++))
      fi
    fi
    
    # NixOS-specific security checks
    if [ "$FULL_CHECK" -eq 1 ]; then
      show_progress "Running full NixOS checks (including store verification)..."
    else
      show_progress "Running NixOS-specific checks..."
    fi
    echo -e "\n=== NixOS Security Checks ===" >> "$REPORT_FILE"
    
    if [ "$FULL_CHECK" -eq 1 ]; then
      # Full store verification (slow)
      echo "Running full Nix store integrity check (this may take several minutes)..." >> "$REPORT_FILE"
      UNSIGNED_PATHS=$(nix-store --verify --check-contents 2>&1 | grep -c "lacks a signature" || true)
      if [ "$UNSIGNED_PATHS" -gt 0 ]; then
        echo "WARNING: $UNSIGNED_PATHS unsigned store paths found" >> "$REPORT_FILE"
        ((WARNINGS++))
      else
        echo "✓ All Nix store paths properly signed" >> "$REPORT_FILE"
      fi
    else
      # Skip store verification - too slow for regular checks
      echo "Note: Skipping full store verification (too slow)" >> "$REPORT_FILE"
      echo "Run 'ntl run --full-check' for complete verification" >> "$REPORT_FILE"
    fi
    
    # Check system profile generations (potential rollback points)
    echo "System generations available: $(ls -1 /nix/var/nix/profiles/system-*-link 2>/dev/null | wc -l)" >> "$REPORT_FILE"
    
    # NixOS-specific security checks
    echo -e "\n=== NixOS Security Checks ===" >> "$REPORT_FILE"
    
    # Check for unsigned Nix store paths
    echo "Checking Nix store integrity..." >> "$REPORT_FILE"
    UNSIGNED_PATHS=$(nix-store --verify --check-contents 2>&1 | grep -c "lacks a signature" || true)
    if [ "$UNSIGNED_PATHS" -gt 0 ]; then
      echo "WARNING: $UNSIGNED_PATHS unsigned store paths found" >> "$REPORT_FILE"
      ((WARNINGS++))
    else
      echo "✓ All Nix store paths properly signed" >> "$REPORT_FILE"
    fi
    
    # Check for impure derivations
    echo "Checking for impure derivations..." >> "$REPORT_FILE"
    if [ -d "/nix/var/nix/profiles" ]; then
      IMPURE_COUNT=$(find /nix/var/nix/profiles -name "*.drv" -exec grep -l "impure" {} \; 2>/dev/null | wc -l || true)
      if [ "$IMPURE_COUNT" -gt 0 ]; then
        echo "Note: $IMPURE_COUNT impure derivations found (this may be normal)" >> "$REPORT_FILE"
      fi
    fi
    
    # Check system profile generations (potential rollback points)
    echo "System generations available: $(ls -1 /nix/var/nix/profiles/system-*-link 2>/dev/null | wc -l)" >> "$REPORT_FILE"
    
    # Generate summary
    show_progress "Generating report..."
    echo "=== AUDIT SUMMARY ===" > "$SUMMARY_FILE"
    echo "Date: $(date)" >> "$SUMMARY_FILE"
    echo "Critical Issues: $CRITICAL" >> "$SUMMARY_FILE"
    echo "Warnings: $WARNINGS" >> "$SUMMARY_FILE"
    if [ "$CRITICAL" -gt 0 ] || [ "$WARNINGS" -gt 0 ]; then
      echo "" >> "$SUMMARY_FILE"
      echo "Note: chkrootkit shows false positives on NixOS for:" >> "$SUMMARY_FILE"
      echo "  - basename, date, dirname, echo, env (symlinks to Nix store)" >> "$SUMMARY_FILE"
      echo "  - Missing /usr/lib, /usr/share, /sbin directories (NixOS uses different layout)" >> "$SUMMARY_FILE"
      echo "These are NOT security issues, just NixOS differences." >> "$SUMMARY_FILE"
    fi
    echo "" >> "$SUMMARY_FILE"
    echo "Note: chkrootkit shows false positives on NixOS for:" >> "$SUMMARY_FILE"
    echo "  - basename, date, dirname, echo, env (symlinks to Nix store)" >> "$SUMMARY_FILE"
    echo "  - Missing /usr/lib, /usr/share, /sbin directories (NixOS uses different layout)" >> "$SUMMARY_FILE"
    echo "These are NOT security issues, just NixOS differences." >> "$SUMMARY_FILE"
    
    # Final notification
    if [ "$CRITICAL" -gt 0 ]; then
      notify_user critical "CRITICAL SECURITY ALERT" "$CRITICAL critical issues found! Check $REPORT_FILE"
    elif [ "$WARNINGS" -gt 3 ]; then
      notify_user normal "Security Warnings" "$WARNINGS security warnings detected"
    else
      # Only notify on clean scan once per day
      LAST_CLEAN="/tmp/nastyTechLords-last-clean"
      if [ ! -f "$LAST_CLEAN" ] || [ $(find "$LAST_CLEAN" -mtime +1 2>/dev/null | wc -l) -gt 0 ]; then
              notify_user low "Security Scan Complete" "No issues detected - Tech lords thwarted! 🛡️"
              touch "$LAST_CLEAN"
      fi
    fi
    
    echo -e "\n✓ Audit complete. Report saved to: $REPORT_FILE"
'';

# CLI wrapper for better user experience
ntlCli = pkgs.writeShellScriptBin "ntl" ''
    #!/usr/bin/env bash
    
    YELLOW='\033[1;33m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
    
    show_help() {
            echo -e "''${GREEN}NastyTechLords Security Monitor''${NC}"
            echo -e "Protection against the tech overlords! 🛡️\n"
            echo -e "''${YELLOW}Usage:''${NC} ntl [command]"
            echo ""
            echo -e "''${YELLOW}Commands:''${NC}"
            echo -e "  ''${BLUE}run''${NC}        Run security audit now"
            echo -e "  ''${BLUE}run --full-check''${NC}  Run with complete Nix verification (slow)"
            echo -e "  ''${BLUE}status''${NC}     Show daemon status and next run time"
            echo -e "  ''${BLUE}logs''${NC}       Follow live logs (shows past + new logs)"
            echo -e "  ''${BLUE}report''${NC}     View latest audit summary"
            echo -e "  ''${BLUE}full''${NC}       View full latest audit report"
            echo -e "  ''${BLUE}history''${NC}    List all audit reports"
            echo -e "  ''${BLUE}enable''${NC}     Enable automatic monitoring"
            echo -e "  ''${BLUE}disable''${NC}    Disable automatic monitoring"
            echo -e "  ''${BLUE}help''${NC}       Show this help message"
            echo ""
            echo -e "''${YELLOW}Examples:''${NC}"
            echo -e "  ntl run          # Run audit immediately"
            echo -e "  ntl run --full-check  # Run with Nix store verification (slow)"
            echo -e "  ntl status       # Check if monitoring is active"
            echo -e "  ntl report       # See latest findings"
    }
    
    case "$1" in
            run)
              if [ "$2" = "--full-check" ]; then
                echo -e "''${GREEN}🛡️  NastyTechLords Security Audit (FULL CHECK)''${NC}"
                echo -e "''${YELLOW}⚠️  This includes Nix store verification - may take several minutes''${NC}"
                echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
                sudo ${nastyTechLordsScript}/bin/nastyTechLords --full-check
              else
                echo -e "''${GREEN}🛡️  NastyTechLords Security Audit''${NC}"
                echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
                sudo ${nastyTechLordsScript}/bin/nastyTechLords
              fi
              echo -e "\n''${GREEN}✓ Audit complete!''${NC} View report with: ''${YELLOW}ntl report''${NC}"
              ;;
      status)
              echo -e "''${GREEN}NastyTechLords Daemon Status:''${NC}"
              sudo systemctl status nastyTechLords.timer --no-pager
              echo ""
              echo -e "''${GREEN}Next scheduled run:''${NC}"
              sudo systemctl list-timers nastyTechLords.timer --no-pager | grep nastyTechLords || echo "Timer not active"
              ;;
      logs)
              echo -e "''${GREEN}📋 NastyTechLords Service Logs''${NC}"
              echo -e "''${YELLOW}Shows past runs + follows new logs (Ctrl-C to exit)''${NC}"
              echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
              sudo journalctl -u nastyTechLords -f
              ;;
      report)
              if [ -f "/var/log/nastyTechLords/latest-summary.txt" ]; then
                echo -e "''${GREEN}Latest Security Audit Summary:''${NC}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                sudo cat /var/log/nastyTechLords/latest-summary.txt
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
              else
                echo -e "''${YELLOW}No audit reports found yet. Run 'ntl run' to generate one.''${NC}"
              fi
              ;;
      full)
              LATEST_REPORT=$(sudo ls -t /var/log/nastyTechLords/audit-*.log 2>/dev/null | head -1)
              if [ -n "$LATEST_REPORT" ]; then
                echo -e "''${GREEN}Full Security Audit Report:''${NC}"
                echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
                sudo less "$LATEST_REPORT"
              else
                echo -e "''${YELLOW}No audit reports found yet. Run 'ntl run' to generate one.''${NC}"
              fi
              ;;
      history)
              echo -e "''${GREEN}Audit Report History:''${NC}"
              if [ -d "/var/log/nastyTechLords" ]; then
                sudo ls -lth /var/log/nastyTechLords/audit-*.log 2>/dev/null | head -20 || echo "No reports found"
              else
                echo "No reports directory found"
              fi
              ;;
      enable)
              echo -e "''${GREEN}Enabling NastyTechLords monitoring...''${NC}"
              sudo systemctl enable --now nastyTechLords.timer
              echo "✓ Automatic monitoring enabled (runs every 6 hours)"
              ;;
      disable)
              echo -e "''${YELLOW}Disabling NastyTechLords monitoring...''${NC}"
              sudo systemctl disable --now nastyTechLords.timer
              echo "✓ Automatic monitoring disabled"
              ;;
      help|-h|--help)
              show_help
              ;;
      "")
              show_help
              ;;
      *)
              echo -e "''${YELLOW}Unknown command: $1''${NC}"
              echo ""
              show_help
              exit 1
              ;;
    esac
  '';
in
{
  # Install the scripts
  environment.systemPackages = [
          nastyTechLordsScript
          ntlCli
          pkgs.nettools
  ];
  
  # Create systemd service
  systemd.services.nastyTechLords = {
          description = "NastyTechLords Security Audit Daemon";
          serviceConfig = {
                  Type = "oneshot";
                  ExecStart = "${nastyTechLordsScript}/bin/nastyTechLords";
                  StandardOutput = "journal";
                  StandardError = "journal";
                  
                  # Security hardening for the service itself
                  PrivateTmp = true;
                  ProtectSystem = "strict";
                  ProtectHome = "read-only";
                  NoNewPrivileges = true;
                  ReadWritePaths = [ "/var/log/nastyTechLords" ];
                  
                  # Need root to run security scans
                  User = "root";
                  
                  # But send notifications to the user
                  Environment = [
                          "DISPLAY=:0"
                          "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
                  ];
          };
  };
  
  # Create timer to run every 6 hours
  systemd.timers.nastyTechLords = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
                  OnBootSec = "10min";  # First run 10 minutes after boot
                  OnUnitActiveSec = "6h";  # Then every 6 hours
                  RandomizedDelaySec = "30min";  # Randomize to avoid predictable patterns
                  Persistent = true;  # Run if system was off during scheduled time
          };
  };
  
  # Create log directory
  systemd.tmpfiles.rules = [
          "d /var/log/nastyTechLords 0750 root wheel -"
  ];
  
  # Add user to wheel group to read logs
  users.users.${userConfig.username}.extraGroups = [ "wheel" ];
}
