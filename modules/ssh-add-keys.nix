{ pkgs, userConfig, ... }:

{
  # This service runs once when your graphical session starts.
  systemd.user.services.ssh-add-keys = {
    description = "Load SSH keys into agent";
    wantedBy = [ "graphical-session.target" ];

    # This part is what actually runs.
    serviceConfig = {
      Type = "oneshot";
      # It uses the `ssh-add` command from the openssh package.
      ExecStart = ''
        ${pkgs.openssh}/bin/ssh-add /home/${userConfig.username}/.ssh/andromeda
        ${pkgs.openssh}/bin/ssh-add /home/${userConfig.username}/.ssh/id_ed25519
      '';
    };
  };
