{ config, pkgs, userConfig, ... }:
{
  nixpkgs.config.allowUnfree = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    open = false;
    nvidiaSettings = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
  };

  hardware.nvidia.prime = {
    offload.enable = true;
    intelBusId = userConfig.intelBusId;
    nvidiaBusId = userConfig.nvidiaBusId;
  };

  environment = {
    systemPackages = with pkgs; [
      nvidia-vaapi-driver
      libpulseaudio
    ];
    variables = {
      NVD_BACKEND = "direct";
      LIBVA_DRIVER_NAME = "nvidia";
    };
  };

  hardware.nvidia-container-toolkit.enable = true;
}
