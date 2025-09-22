{ pkgs, inputs, lib, ... }:
{
  programs.firefox = {
    enable = lib.mkForce true;
    package = pkgs.librewolf;
    
    # Just the policies - no package override
    policies = {
      HardwareAcceleration.Enabled = true;
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DefaultTheme = "firefox-compact-dark@mozilla.org";
      
      Preferences = {
        "browser.startup.homepage" = "about:blank";
        "gfx.webrender.all" = true;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = {
          Value = true;
          Status = "locked";
        };
        "browser.startup.homepage_override.mstone" = {
          Value = "ignore";
          Status = "locked";
        };
        "browser.rights.3.shown" = {
          Value = true;
          Status = "locked";
        };
      };
    };
  };

  # Simple userChrome.css setup - no autoconfig complexity
  system.userActivationScripts.librewolf-chrome = ''
    mkdir -p ~/.librewolf
    for profile_dir in ~/.librewolf/*; do
      if [ -d "$profile_dir" ]; then
        mkdir -p "$profile_dir/chrome"
        ln -sf ${inputs.self}/configs/librewolf/chrome/userChrome.css "$profile_dir/chrome/userChrome.css"
      fi
    done
  '';
}
