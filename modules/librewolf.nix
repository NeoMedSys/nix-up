{ pkgs, inputs, ... }:
{
  programs.firefox = {
    enable = true;
    package = pkgs.librewolf;
    policies = {
      # Your existing policies from configs/librewolf/policies.json go here
      Preferences = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = {
          Value = true;
          Status = "locked";
        };
      };
    };
  };

  # Symlink userChrome.css via userActivationScripts (like your other configs)
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
