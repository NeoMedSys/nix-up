{ pkgs, ... }:

{
  programs.librewolf = {
    enable = true;
    policies = {
      "policies" = {
        # This policy works universally. It tells the browser to use whatever
        # GPU the system provides, whether integrated or discrete.
        "HardwareAcceleration" = {
          "Enabled" = true;
        };
        
        # Disable unwanted features
        "DisableTelemetry" = true;
        "DisableFirefoxStudies" = true;
        "DisablePocket" = true;
        
        # Enforce other good performance settings
        "Preferences" = {
          "browser.startup.homepage" = "about:blank";
          "gfx.webrender.all" = true; # A more modern way to ensure WebRender is on
        };
      };
    };
  };
}
