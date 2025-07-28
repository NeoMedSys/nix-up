{ config, lib, inputs, userConfig ? null, ... }:
let
  # Import SSH keys safely
  sshKeys = import ./ssh-keys.nix;
in
{
  # Enable the OpenSSH daemon
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
      Port = 7889;
    };
  };
  
  # SSH keys for the user - handle case where key might not exist
  users.users.${userConfig.username}.openssh.authorizedKeys.keys = 
    lib.optionals (sshKeys ? ${userConfig.username}) [ sshKeys.${userConfig.username} ];
}
