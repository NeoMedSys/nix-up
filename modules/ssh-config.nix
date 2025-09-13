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

  # Modern gpg-agent with SSH support (systemd managed)
  services.gpg-agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gtk2;
    defaultCacheTtl = 3600;
    defaultCacheTtlSsh = 3600;
  };

  # SSH client config
  programs.ssh = {
    enable = true;
    extraConfig = ''
      AddKeysToAgent yes
      IdentityAgent ~/.gnupg/S.gpg-agent.ssh
    '';
  };

  # User SSH keys (if they exist)
  users.users.${userConfig.username}.openssh.authorizedKeys.keys =
    lib.optionals (sshKeys ? ${userConfig.username}) [ sshKeys.${userConfig.username} ];
}
