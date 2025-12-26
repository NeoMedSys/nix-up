{ pkgs, userConfig, ... }:

{
  home-manager.users.${userConfig.username} = {
    home.file.".config/DankMaterialShell/settings.json".text = builtins.toJSON {
      blurredWallpaperLayer = false; 
      currentThemeName = "blue";
      use24HourClock = true;
      cornerRadius = 12;
      fontFamily = "Inter Variable";
      monoFontFamily = "Fira Code";
      barOpacity = 0;
      widgetOpacity = 54;
    };
  };
}
