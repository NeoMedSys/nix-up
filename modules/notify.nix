{config, pkgs, lib, ...}
{
  # Battery low notification service
  systemd.user.services.battery-notify = {
    description = "Battery low notification";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "battery-check" ''
        battery_level=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "100")
        battery_status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "Unknown")
        
        if [ "$battery_level" -le 10 ] && [ "$battery_status" != "Charging" ]; then
          ${pkgs.libnotify}/bin/notify-send \
            --urgency=critical \
            --icon=battery-caution \
            "Battery Low" \
            "Battery level: $battery_level%"
        fi
      '';
    };
  };

  # Timer to check battery every 2 minutes
  systemd.user.timers.battery-notify = {
    description = "Check battery level periodically";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "2min";
      Persistent = true;
    };
  };

  systemd.user.services.battery-critical-suspend = {
    description = "Suspend laptop when battery critically low";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "battery-critical-check" ''
        battery_level=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "100")
        battery_status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "Unknown")
        
        # Suspend if battery <= 5% and not charging
        if [ "$battery_level" -le 5 ] && [ "$battery_status" != "Charging" ]; then
          ${pkgs.libnotify}/bin/notify-send \
            --urgency=critical \
            --icon=battery-caution \
            "Critical Battery" \
            "Battery at $battery_level%. Suspending to prevent data loss..."
          sleep 3
          systemctl suspend
        fi
      '';
    };
  };
}
