{ pkgs, userConfig, ... }:

{
  home-manager.users.${userConfig.username} = {
    home.file.".config/DankMaterialShell/settings.json".text = builtins.toJSON {
      blurredWallpaperLayer = true; 
      currentThemeName = "blue";
      use24HourClock = true;
      cornerRadius = 12;
      fontFamily = "Inter Variable";
      monoFontFamily = "Fira Code";
    };
  };
}
