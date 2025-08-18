{ pkgs, ... }:
let
  lidSwitchScript = pkgs.writeShellScript "lid-switch-handler" ''
    # Check for external displays using swaymsg
    external_displays=$(${pkgs.sway}/bin/swaymsg -t get_outputs 2>/dev/null | ${pkgs.jq}/bin/jq -r '.[] | select(.name != "eDP-1" and .active == true) | .name' | wc -l 2>/dev/null || echo "0")
    
    # Log for debugging (optional)
    echo "External displays detected: $external_displays" | ${pkgs.systemd}/bin/systemd-cat -t lid-handler
    
    # Suspend only if no external displays are connected
    if [ "$external_displays" -eq 0 ]; then
      echo "No external displays, suspending" | ${pkgs.systemd}/bin/systemd-cat -t lid-handler
      ${pkgs.systemd}/bin/systemctl suspend
    else
      echo "External displays connected, not suspending" | ${pkgs.systemd}/bin/systemd-cat -t lid-handler
    fi
  '';
in
{
  # Configure systemd-logind to handle lid switch properly
  services.logind = {
    # Completely ignore all lid events - let acpid handle them
    lidSwitch = "ignore";
    lidSwitchExternalPower = "ignore";
    lidSwitchDocked = "ignore";
    # Handle power button - ignore in logind, let WM handle it
    powerKey = "ignore";
    # Additional power management settings
    extraConfig = ''
      # Completely disable lid handling in logind
      HandleLidSwitch=ignore
      HandleLidSwitchExternalPower=ignore
      HandleLidSwitchDocked=ignore
      # Handle multiple lid close/open events gracefully
      HandleLidSwitchMultiSession=ignore
      # Delay before considering the lid "closed" (prevents accidental triggers)
      HoldoffTimeoutSec=30s
      # Idle action (optional - suspend after 30 min of inactivity)
      IdleAction=suspend
      IdleActionSec=30min
    '';
  };

  # Enable acpid and handle lid events directly
  services.acpid = {
    enable = true;
    lidEventCommands = ''
      # Find the user running sway
      SWAY_USER=$(pgrep -o sway | xargs -r ps -o user= -p 2>/dev/null | head -1)
      if [ -n "$SWAY_USER" ]; then
        # Run the display check as the sway user
        sudo -u "$SWAY_USER" ${lidSwitchScript}
      else
        # Fallback: suspend if no sway user found
        ${pkgs.systemd}/bin/systemctl suspend
      fi
    '';
  };

  # Minimal resume configuration - only restart NetworkManager if needed
  powerManagement = {
    enable = true;
    resumeCommands = ''
      # NetworkManager sometimes needs a kick after resume
      ${pkgs.systemd}/bin/systemctl restart NetworkManager || true
    '';
  };
}
