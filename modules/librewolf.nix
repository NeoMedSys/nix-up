# ./modules/librewolf.nix
{ pkgs, userConfig, inputs, ... }:

let
  # Define your custom LibreWolf package with policies and configs baked in.
  # This is more robust than the user activation script.
  librewolf-with-emperor-decree = pkgs.librewolf.overrideAttrs (oldAttrs: {
    # This hook runs at the end of the original build process.
    postInstall = (oldAttrs.postInstall or "") + ''
      # Directory for enterprise policies
      mkdir -p $out/lib/librewolf/distribution
      # Copy the policy file directly into the package
      cp ${inputs.self}/configs/librewolf/policies.json $out/lib/librewolf/distribution/policies.json

      # Directories for autoconfig to enable userChrome.css
      mkdir -p $out/lib/librewolf/defaults/pref
      # Copy the autoconfig files
      cp ${inputs.self}/configs/librewolf/autoconfig.js $out/lib/librewolf/defaults/pref/autoconfig.js
      cp ${inputs.self}/configs/librewolf/librewolf.cfg $out/lib/librewolf/librewolf.cfg
    '';
  });
in
{
  # Use the programs.librewolf module for declarative configuration
  programs.librewolf = {
    enable = true;
    # Point to our custom package
    package = librewolf-with-emperor-decree;
    
    # Let NixOS manage the userChrome.css content directly
    userChrome = builtins.readFile "${inputs.self}/configs/librewolf/chrome/userChrome.css";

    # You can also manage preferences here, which is cleaner than using policies.json for everything
    settings = {
      "browser.startup.homepage" = "about:blank";
      "gfx.webrender.all" = true;
    };
  };

  # Also add the package to systemPackages so it appears in your launcher
  environment.systemPackages = [ librewolf-with-emperor-decree ];
}
