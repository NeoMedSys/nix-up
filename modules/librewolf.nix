{ pkgs, inputs, lib, ... }:
let
  librewolf-theme-linker = pkgs.writeShellScriptBin "librewolf-theme-linker" ''
    set -e
    PROFILE_ROOT="$HOME/.librewolf"

    mkdir -p "$PROFILE_ROOT"

    for profile_dir in "$PROFILE_ROOT"/*; do
      if [ -d "$profile_dir" ]; then
        echo "Found profile: $profile_dir"
        mkdir -p "$profile_dir/chrome"
        ln -snf "${inputs.catppuccin-firefox}/userChrome.css" "$profile_dir/chrome/userChrome.css"
        echo "Linked userChrome.css in $profile_dir/chrome"
      fi
    done
  '';
in
{
  programs.firefox = {
    enable = lib.mkForce true;
    package = pkgs.librewolf;

    policies = {
      HardwareAcceleration.Enabled = true;
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DefaultTheme = "firefox-compact-dark@mozilla.org";

      Extensions.Install = [
        "https://addons.mozilla.org/firefox/downloads/latest/clearurls/latest.xpi"
        "https://addons.mozilla.org/firefox/downloads/latest/spoof-timezone/latest.xpi"
      ];

      Preferences = {
        "privacy.resistFingerprinting" = {
          Value = false;
          Status = "locked";
        };
        "browser.startup.homepage" = {
          Value = "about:blank";
          Status = "locked";
        };
        "gfx.webrender.all" = {
          Value = true;
          Status = "locked";
        };

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

  systemd.user.services.librewolf-catppuccin-chrome = {
    description = "Link Catppuccin userChrome.css for LibreWolf";

    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = false;

      ExecStart = "${librewolf-theme-linker}/bin/librewolf-theme-linker";
    };
  };
}
