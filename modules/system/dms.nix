{ pkgs, userConfig, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    cliphist
    wl-clipboard
  ];

  home-manager.users.${userConfig.username} = {
    imports = [ inputs.danksearch.homeModules.dsearch ];


    programs.dsearch.enable = true;
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
        "application/xhtml+xml" = "firefox.desktop";
        "application/pdf" = "firefox.desktop";
      };
    };
  };
}
