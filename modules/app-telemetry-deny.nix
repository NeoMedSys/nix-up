{ config, pkgs, lib, ... }:
{
  # App Telemetry Denial Module
  # Conservative approach - only block actual telemetry endpoints
  
  networking.hosts = {
    "0.0.0.0" = [
      # Slack telemetry (specific endpoints only)
      "crash-reports.slack.com"
      "stats.slack.com" 
      "telemetry.slack.com"
      "analytics.slack.com"
      
      # Microsoft Teams telemetry (specific endpoints only)
      "telemetry.teams.microsoft.com"
      "watson.telemetry.microsoft.com"
      "vortex.data.microsoft.com"
      "browser.events.data.microsoft.com"
      
      # Zoom telemetry (specific endpoints only)
      "logfiles.zoom.us"
      "events.zoom.us"
      "analytics.zoom.us"
      
      # Common analytics services (only tracking endpoints)
      "google-analytics.com"
      "googletagmanager.com"
      "api.segment.io"
      "api.mixpanel.com"
      
      # Crash reporting services
      "sentry.io"
      "bugsnag.com"
      
      # Microsoft telemetry (specific endpoints)
      "telemetry.microsoft.com"
      "watson.live.com"
      "sqm.telemetry.microsoft.com"
      
      # VS Code telemetry (specific endpoints)
      "vscode-update.azurewebsites.net"
    ];
  };

  # Environment variables to disable telemetry (safe, non-breaking)
  environment.variables = {
    # Communication Apps
    SLACK_DISABLE_TELEMETRY = "1";
    TEAMS_DISABLE_TELEMETRY = "1"; 
    ZOOM_DISABLE_ANALYTICS = "1";
    
    # Development Tools
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    VSCODE_TELEMETRY_LEVEL = "off";
    NEXT_TELEMETRY_DISABLED = "1";
    
    # System identifier spoofing (mild privacy boost)
    HOSTNAME = "research-workstation";
    
    # Safe application settings
    ELECTRON_DISABLE_CRASH_REPORTER = "1";
    NPM_CONFIG_DISABLE_UPDATE_NOTIFIER = "true";

    # Disable Zoom Telemetry
    ZOOM_DISABLE_TELEMETRY = "1";

    # Office applications privacy
    LO_JAVA_JFR = "false";
  };

  # Verification service (optional - can disable if not needed)
  systemd.services.verify-telemetry-blocks = {
    description = "Verify key telemetry domains are blocked";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "verify-blocks" ''
        echo "Telemetry blocking verification: $(date)" >> /var/log/telemetry-block.log
        for domain in "telemetry.slack.com" "analytics.slack.com" "telemetry.teams.microsoft.com"; do
          if ${pkgs.dnsutils}/bin/nslookup "$domain" 2>/dev/null | grep -q "0.0.0.0"; then
            echo "✓ $domain blocked" >> /var/log/telemetry-block.log
          fi
        done
      '';
    };
    # Don't auto-start - only run manually if needed
    # wantedBy = [ "multi-user.target" ];
  };
}
