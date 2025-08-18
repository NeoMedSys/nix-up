{ pkgs, inputs, ... }:
let
  # Create a custom theme package that inherits Juno + adds transparency
  lightdm-transparent-theme = pkgs.runCommand "juno-transparent-theme" {} ''
    # Create theme directory structure
    mkdir -p $out/share/themes/Juno-Transparent
    
    # Copy Juno theme contents
    cp -r ${pkgs.juno-theme}/share/themes/Juno/* $out/share/themes/Juno-Transparent/
    chmod -R u+w $out/share/themes/Juno-Transparent
    
    # Fix the index.theme file - keep internal names as Juno, only change display name
    sed -i 's/Name=Juno/Name=Juno-Transparent/g' $out/share/themes/Juno-Transparent/index.theme
    
    # Ensure gtk-3.0 directory exists
    mkdir -p $out/share/themes/Juno-Transparent/gtk-3.0
    
    # Create or append to gtk.css
    touch $out/share/themes/Juno-Transparent/gtk-3.0/gtk.css
    
    # Add our transparency CSS
    echo "" >> $out/share/themes/Juno-Transparent/gtk-3.0/gtk.css
    echo "/* LightDM Transparency Customization */" >> $out/share/themes/Juno-Transparent/gtk-3.0/gtk.css
    cat ${inputs.self}/configs/lightdm-gtk/greeter.css >> $out/share/themes/Juno-Transparent/gtk-3.0/gtk.css
  '';
in
{
  # Make the custom theme available
  environment.systemPackages = [ lightdm-transparent-theme ];
  
  # Set lightdm to use our transparent theme
  services.xserver.displayManager.lightdm.greeters.gtk.theme = {
    package = lightdm-transparent-theme;
    name = "Juno-Transparent";
  };
}
