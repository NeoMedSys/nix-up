{ pkgs, inputs, lib, ... }:
{
  programs.firefox = {
    enable = lib.mkForce true;
    package = pkgs.librewolf;
    
    policies = {
      HardwareAcceleration = {
        Enabled = true;
      };
      
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

  environment.etc."librewolf/defaults/pref/autoconfig.js".text = ''
    pref("general.config.filename", "librewolf.cfg");
    pref("general.config.obscure_value", 0);
    pref("general.config.sandbox_value", 0);
  '';

  environment.etc."librewolf/librewolf.cfg".text = ''
    // Any comment will do, the first line is ignored.
    // Enable userChrome.css customizations
    pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
  '';

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
