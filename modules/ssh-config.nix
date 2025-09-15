{ lib, userConfig ? null, pkgs, ... }:
let
  sshKeys = import ./ssh-keys.nix;
in
{
  # Enable OpenSSH daemon
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
      Port = 7889;
    };
  };

  programs.gnupg.agent = {
    enable = true;
  };

  users.users.${userConfig.username}.openssh.authorizedKeys.keys =
    lib.optionals (sshKeys ? ${userConfig.username}) [ sshKeys.${userConfig.username} ];
}
