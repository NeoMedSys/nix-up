{ pkgs, userConfig, inputs, ... }:

{
  imports = [
    inputs.dms.nixosModules.greeter
  ];

  services.fprintd.enable = true;

  security.pam.services = {
    greetd = {
      fprintAuth = false;
      nodelay = true;
      enableGnomeKeyring = false;
    };
    login = {
      fprintAuth = true;
      nodelay = true;
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/cache/greeter 0755 greeter greeter -"
  ];

  programs.dankMaterialShell.greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/${userConfig.username}";
    
    compositor.customConfig = ''
      environment {
        XDG_CACHE_HOME "/var/cache/greeter"
      }
    '';
    
    logs = {
      save = true;
      path = "/tmp/dms-greeter.log";
    };
  };
}
