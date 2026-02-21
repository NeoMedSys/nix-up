{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableBashCompletion = true; 
  };
  
  environment.pathsToLink = [ "/share/zsh" ];
}
