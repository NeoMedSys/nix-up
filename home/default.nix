{ config, pkgs, lib, inputs, userConfig, ... }:

let
  # --- BROWSER LOGIC ---
  availableBrowsers = {
    firefox = pkgs.firefox;
    librewolf = pkgs.librewolf;
    brave = pkgs.brave;
  };

  browserPackages = map (browserName: availableBrowsers.${browserName}) userConfig.browsers;

in
{
  home.stateVersion = "25.05";

  home.username = userConfig.username;
  home.homeDirectory = "/home/${userConfig.username}";

  imports = [
  ] ++ lib.optionals (builtins.elem "firefox" userConfig.browsers) [
    ./firefox 
  ];

  home.packages = [
  ] ++ browserPackages;

  home.sessionVariables = {
    EDITOR = "nvim"; 
    VISUAL = "nvim";
  };
}
