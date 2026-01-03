{ pkgs, ... }:
{
  # App Telemetry Denial Module
  # Conservative approach - only block actual telemetry endpoints
  networking.hosts = {
    "0.0.0.0" = [
      "ssl.google-analytics.com"
      "mobile.events.data.microsoft.com"
      "heapanalytics.com"
      "metrics.icloud.com"

      # Slack telemetry (specific endpoints only)
      "crash-reports.slack.com"
      "stats.slack.com"
      "telemetry.slack.com"
      "analytics.slack.com"
      "lb.slack-msgs.com"

      # Microsoft Teams / Office
      "telemetry.teams.microsoft.com"
      "watson.telemetry.microsoft.com"
      "vortex.data.microsoft.com"
      "browser.events.data.microsoft.com"

      # Zoom
      "logfiles.zoom.us"
      "events.zoom.us"
      "analytics.zoom.us"

      # Common analytics
      "google-analytics.com"
      "googletagmanager.com"
      "api.segment.io"
      "api.mixpanel.com"
      "heapanalytics.com" 

      # Crash reporting
      "sentry.io"
      "bugsnag.com"
      "hockeyapp.net"

      # Microsoft General
      "telemetry.microsoft.com"
      "watson.live.com"
      "sqm.telemetry.microsoft.com"
      "choice.microsoft.com"
      "choice.microsoft.com.nsatc.net"

      # VS Code
      "vscode-update.azurewebsites.net"
      "vortex.data.microsoft.com"
      
      # AI & Cloud
      "copilot-proxy.githubusercontent.com"
      "api.githubcopilot.com"
      "github.com/features/copilot"
      "cloud.tabnine.com"
      "api.tabnine.com"
      "server.codeium.com"
      "api.codeium.com"
      "api.cursor.sh"
      "cursor.sh"
      "codewhisperer.aws.amazon.com"
      "ai.jetbrains.com"
      "ai-assistant.jetbrains.com"

      # DoH/DoT bypass prevention - force apps to use system DNS
      "mozilla.cloudflare-dns.com"
      "dns.google"
      "dns.google.com"
      "cloudflare-dns.com"
      "one.one.one.one"
      "1dot1dot1dot1.cloudflare-dns.com"
      "dns.quad9.net"
      "dns9.quad9.net"
      "dns10.quad9.net"
      "dns11.quad9.net"
      "doh.opendns.com"
      "doh.cleanbrowsing.org"
      "dns.adguard.com"
      "dns.nextdns.io"
    ];
  };

  environment.variables = {
    SLACK_DISABLE_TELEMETRY = "1";
    TEAMS_DISABLE_TELEMETRY = "1";
    ZOOM_DISABLE_ANALYTICS = "1";
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    VSCODE_TELEMETRY_LEVEL = "off";
    NEXT_TELEMETRY_DISABLED = "1";
    HOSTNAME = "research-workstation";
    ELECTRON_DISABLE_CRASH_REPORTER = "1";
    NPM_CONFIG_DISABLE_UPDATE_NOTIFIER = "true";
    ZOOM_DISABLE_TELEMETRY = "1";
    LO_JAVA_JFR = "false";
    GITHUB_COPILOT_DISABLED = "1";
    TABNINE_DISABLE_TELEMETRY = "1";
    CODEIUM_DISABLE_TELEMETRY = "1";
    CURSOR_DISABLE_AI = "1";
    VSCODE_DISABLE_WORKSPACE_TRUST = "1";
    JETBRAINS_AI_DISABLED = "1";
    OPENAI_API_KEY = "";
    ANTHROPIC_API_KEY = "";
    DISABLE_OPENCOLLECTIVE = "1";
  };
}
