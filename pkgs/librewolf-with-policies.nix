{ pkgs, inputs }:

pkgs.librewolf.overrideAttrs (oldAttrs: {
  postInstall = (oldAttrs.postInstall or "") + ''
    rm -f $out/lib/librewolf/distribution/policies.json
    cat > $out/lib/librewolf/distribution/policies.json << 'EOF'
{
  "policies": {
    "Preferences": {
      "toolkit.legacyUserProfileCustomizations.stylesheets": {
        "Value": true,
        "Status": "locked"
      },
      "browser.startup.homepage_override.mstone": {
        "Value": "ignore",
        "Status": "locked"
      },
      "browser.rights.3.shown": {
        "Value": true,
        "Status": "locked"
      }
    }
  }
}
EOF
  '';
})
