# pkgs/librewolf-with-policies.nix
{ pkgs }:

pkgs.librewolf.overrideAttrs (oldAttrs: {
  # This hook runs at the end of the original build process.
  postInstall = (oldAttrs.postInstall or "") + ''
    # Create the necessary directory for the policy file
    mkdir -p $out/lib/librewolf/distribution
    # Copy the Emperor's decree directly into the package
    cp ${../configs/librewolf/policies.json} $out/lib/librewolf/distribution/policies.json
  '';
})
