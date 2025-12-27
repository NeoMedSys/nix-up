{ pkgs, userConfig, ... }:

{
  environment.systemPackages = with pkgs; [
    cliphist
    wl-clipboard
  ];

  home-manager.users.${userConfig.username} = {
    # DMS settings - these will be written to settings.json
    # Note: DMS reads this file at startup. If you change settings via UI,
    # they will be saved here and override these defaults on next login.
    home.file.".config/DankMaterialShell/settings.json".text = builtins.toJSON {
      # Appearance
      barOpacity = 0;
      widgetOpacity = 54;
      cornerRadius = 12; 
      blurredWallpaperLayer = false;

      currentThemeName = "blue";

      fontFamily = "Inter Variable";
      monoFontFamily = "Fira Code";

      use24HourClock = true;
    };

    home.activation.createDmsConfigDir = {
      after = [ "writeBoundary" ];
      before = [ ];
      data = ''
        mkdir -p $HOME/.config/DankMaterialShell
      '';
    };
  };
}
