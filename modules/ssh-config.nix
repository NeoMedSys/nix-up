{ lib, userConfig ? null, pkgs, ... }:
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

  systemd.user.services.gpg-agent = {
    description = "GnuPG Agent with SSH support";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "forking";
      ExecStart = ''
        ${pkgs.gnupg}/bin/gpg-agent --daemon --enable-ssh-support --write-env-file ''${XDG_RUNTIME_DIR}/gpg-agent-info
      '';
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
  
  # SSH keys for the user - handle case where key might not exist
  users.users.${userConfig.username}.openssh.authorizedKeys.keys = 
    lib.optionals (sshKeys ? ${userConfig.username}) [ sshKeys.${userConfig.username} ];
}
