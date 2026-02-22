{ pkgs, ... }:

{
  programs.firejail = {
    enable = true;
    wrappedBinaries = {
      firefox ={
        executable = "${pkgs.firefox}/bin/firefox";
        profile = "${pkgs.firejail}/etc/firejail/firefox.profile";
      };
    };
  };
}
