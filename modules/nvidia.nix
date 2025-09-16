{ config, pkgs, userConfig, ... }:
{
  nixpkgs.config.allowUnfree = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    open = true;
    nvidiaSettings = true;
  };

  hardware.nvidia.prime = {
    offload.enable = true;
    intelBusId = userConfig.intelBusId;
    nvidiaBusId = userConfig.nvidiaBusId;
  };
}
