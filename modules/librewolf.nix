{ pkgs, inputs, lib, ... }:
{
  programs.firefox = {
    enable = lib.mkForce true;
    
    # Override LibreWolf package to include autoconfig files
    package = pkgs.librewolf.overrideAttrs (oldAttrs: {
      postInstall = (oldAttrs.postInstall or "") + ''
        # Set up autoconfig.js
        mkdir -p $out/lib/librewolf/defaults/pref
        cat > $out/lib/librewolf/defaults/pref/autoconfig.js << 'EOF'
pref("general.config.filename", "librewolf.cfg");
pref("general.config.obscure_value", 0);
pref("general.config.sandbox_value", 0);
EOF

        # Set up librewolf.cfg
        cat > $out/lib/librewolf/librewolf.cfg << 'EOF'
// Any comment will do, the first line is ignored.
// Enable userChrome.css customizations
pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
EOF
      '';
    });
    
    # Merged policies from both configs/librewolf/policies.json and pkgs/librewolf-with-policies.nix
    policies = {
      # Hardware and performance
      HardwareAcceleration = {
        Enabled = true;
      };
      
      # Privacy settings
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      
      # UI preferences
      DefaultTheme = "firefox-compact-dark@mozilla.org";
      
      # Preferences from both sources merged
      Preferences = {
        # From configs/librewolf/policies.json
        "browser.startup.homepage" = "about:blank";
        "gfx.webrender.all" = true;
        
        # From pkgs/librewolf-with-policies.nix
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

  # Set up userChrome.css for any existing LibreWolf profiles
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
