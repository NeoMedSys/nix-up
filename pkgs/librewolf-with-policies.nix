{ pkgs, inputs }:

pkgs.librewolf.overrideAttrs (oldAttrs: {
  postInstall = (oldAttrs.postInstall or "") + ''
    # --- Part 1: Enterprise Policies ---
    mkdir -p $out/lib/librewolf/distribution
    cp ${inputs.self}/configs/librewolf/policies.json $out/lib/librewolf/distribution/policies.json

    # --- Part 2: Autoconfig to enable userChrome.css ---
    mkdir -p $out/lib/librewolf/defaults/pref
    
    # Debug: Check if source files exist during build
    echo "Checking source files during build:"
    ls -la ${inputs.self}/configs/librewolf/
    
    # Copy autoconfig files
    cp ${inputs.self}/configs/librewolf/autoconfig.js $out/lib/librewolf/defaults/pref/autoconfig.js
    cp ${inputs.self}/configs/librewolf/librewolf.cfg $out/lib/librewolf/librewolf.cfg
    
    # Debug: Verify files were copied
    echo "Files after copy:"
    ls -la $out/lib/librewolf/librewolf.cfg
    ls -la $out/lib/librewolf/defaults/pref/autoconfig.js
  '';
})
