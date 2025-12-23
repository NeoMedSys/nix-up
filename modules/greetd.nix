{ pkgs, userConfig, inputs, ... }:

{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${inputs.dms.packages.${pkgs.system}.default}/bin/dms greeter";
        user = "greeter";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    niri
  ];
}
