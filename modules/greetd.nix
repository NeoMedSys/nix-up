{ pkgs, userConfig, inputs, ... }:

{
  imports = [
    inputs.dms.nixosModules.greeter
  ];

  services.fprintd.enable = true;

  security.pam.services = {
    greetd.fprintAuth = true;
    login.fprintAuth = true;
    dms-greeter.fprintAuth = true;
    
    greetd.nodelay = true;
    login.nodelay = true;
    dms-greeter.nodelay = true;
  };

  programs.dankMaterialShell.greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/${userConfig.username}";
    logs = {
      save = true;
      path = "/tmp/dms-greeter.log";
    };
  };
}
