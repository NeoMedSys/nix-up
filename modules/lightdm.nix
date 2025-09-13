{ pkgs, inputs, userConfig, ... }:
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

    # Add our transparency CSS from the configs directory
    echo "/* LightDM Transparency Customization from greeter.css */" >> $out/share/themes/Juno-Transparent/gtk-3.0/gtk.css
    cat ${inputs.self}/configs/lightdm-gtk/greeter.css >> $out/share/themes/Juno-Transparent/gtk-3.0/gtk.css
  '';
in
{
  # Make the custom theme available to the system
  environment.systemPackages = [ lightdm-transparent-theme ];

  services.xserver.displayManager.lightdm = {
    enable = true;
    greeters.gtk = {
      enable = true;
      # Set lightdm to use our custom transparent theme
      theme = {
        package = lightdm-transparent-theme;
        name = "Juno-Transparent";
      };
      iconTheme = {
        package = pkgs.papirus-icon-theme;
        name = "Papirus-Dark";
      };
      extraConfig = ''
        background = ${inputs.self}/${userConfig.wallpaperPath}
        font-name = MesloLGS NF 12
        indicators = ~host;~spacer;~clock;~spacer;~session;~power
        clock-format = %H:%M:%S | %A, %d %B %Y
        position = 50%,center 50%,center
      '';
    };
  };
}
