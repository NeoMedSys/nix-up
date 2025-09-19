{ pkgs }:

pkgs.librewolf.overrideAttrs (oldAttrs: {
  # This hook runs at the end of the original build process.
  postInstall = (oldAttrs.postInstall or "") + ''
    # Create the necessary directory for the policy file
    mkdir -p $out/lib/librewolf/distribution
    # Copy the Emperor's decree directly into the package
    cp ${../configs/librewolf/policies.json} $out/lib/librewolf/distribution/policies.json

    # Copy the entire chrome directory for styling
    cp -r ${../configs/librewolf/chrome} $out/lib/librewolf/distribution/

    # Create directories for autoconfig
    mkdir -p $out/lib/librewolf/defaults/pref

    # Copy the autoconfig files
    cp ${../configs/librewolf/autoconfig.js} $out/lib/librewolf/defaults/pref/autoconfig.js
    cp ${../configs/librewolf/librewolf.cfg} $out/lib/librewolf/librewolf.cfg
  '';
})
