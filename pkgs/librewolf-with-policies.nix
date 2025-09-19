{ pkgs, inputs }:

pkgs.librewolf.overrideAttrs (oldAttrs: {
  postInstall = (oldAttrs.postInstall or "") + ''
    # --- Part 1: Enterprise Policies ---
    # Create the necessary directory for the policy file
    mkdir -p $out/lib/librewolf/distribution
    # Copy the policy file directly into the package
    cp ${inputs.self}/configs/librewolf/policies.json $out/lib/librewolf/distribution/policies.json

    # --- Part 2: Autoconfig to enable userChrome.css ---
    # Create directories for autoconfig
    mkdir -p $out/lib/librewolf/defaults/pref
    # Copy the autoconfig files
    cp ${inputs.self}/configs/librewolf/autoconfig.js $out/lib/librewolf/defaults/pref/autoconfig.js
    cp ${inputs.self}/configs/librewolf/librewolf.cfg $out/lib/librewolf/librewolf.cfg

    # --- Part 3 (NEW): Inject userChrome.css into the default profile ---
    # This ensures any *new* user profile automatically gets your custom theme.
    mkdir -p $out/lib/librewolf/defaults/profile/chrome
    cp ${inputs.self}/configs/librewolf/chrome/userChrome.css $out/lib/librewolf/defaults/profile/chrome/userChrome.css
  '';
})
