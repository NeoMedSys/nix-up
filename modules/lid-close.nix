{ config, lib, pkgs, user ? "algol", ... }:
{
  # Configure systemd-logind to handle lid switch properly
  services.logind = {
    # Suspend when lid is closed (even on AC power)
    lidSwitch = "suspend";
    lidSwitchExternalPower = "suspend"; # Also suspend when plugged in
    lidSwitchDocked = "suspend"; # And when docked
    
    # Handle power button - ignore in logind, let i3 handle it
    powerKey = "ignore";
    
    # Additional power management settings
    extraConfig = ''
      # Handle multiple lid close/open events gracefully
      HandleLidSwitchMultiSession=suspend
      
      # Delay before considering the lid "closed" (prevents accidental triggers)
      HoldoffTimeoutSec=30s
      
      # Idle action (optional - suspend after 30 min of inactivity)
      IdleAction=suspend
      IdleActionSec=30min
    '';
  };

  # Minimal resume configuration - only restart NetworkManager (commonly needed)
  powerManagement = {
    enable = true;
    resumeCommands = ''
      # NetworkManager sometimes needs a kick after resume
      ${pkgs.systemd}/bin/systemctl restart NetworkManager || true
    '';
  };
}
