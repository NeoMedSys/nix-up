{ pkgs }:

pkgs.writeShellScriptBin "ntl-tray" ''
  #!/usr/bin/env bash
  
  LOG_DIR="/var/log/nastyTechLords"
  LATEST="$LOG_DIR/latest-summary.txt"
  
  # Check if ntl service is active
  if ! systemctl is-active --quiet nastyTechLords.timer; then
    echo '{"icon": "󰦞", "status": "inactive"}'
    exit 0
  fi
  
  # No report yet
  if [ ! -f "$LATEST" ]; then
    echo '{"icon": "󰔟", "status": "pending"}'
    exit 0
  fi
  
  # Parse latest report
  CRITICAL=$(grep -c "^\[CRITICAL\]" "$LATEST" 2>/dev/null || echo "0")
  WARNING=$(grep -c "^\[WARNING\]" "$LATEST" 2>/dev/null || echo "0")
  
  if [ "$CRITICAL" -gt 0 ]; then
    echo "{\"icon\": \"󰀦\", \"status\": \"critical\", \"critical\": $CRITICAL, \"warning\": $WARNING}"
  elif [ "$WARNING" -gt 0 ]; then
    echo "{\"icon\": \"󰀪\", \"status\": \"warning\", \"critical\": 0, \"warning\": $WARNING}"
  else
    echo '{"icon": "󰒘", "status": "ok", "critical": 0, "warning": 0}'
  fi
''
