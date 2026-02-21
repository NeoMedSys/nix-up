{ lib, userConfig ? null, pkgs, ... }:
let
  sshKeys = import ./ssh-keys.nix;
  userKeys = lib.optionals (sshKeys ? ${userConfig.username}) [ sshKeys.${userConfig.username} ];
  hasKeys = userKeys != [];
in
{
  services.openssh = {
    enable = hasKeys;
    ports = [ 7889 ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
    };
  };

  programs.gnupg.agent = {
    enable = true;
  };

  users.users.${userConfig.username}.openssh.authorizedKeys.keys = userKeys;
}
