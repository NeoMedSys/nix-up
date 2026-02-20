{ config, pkgs, userConfig, ... }:
{
  nixpkgs.config.allowUnfree = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  # Force kernel parameters and early KMS for Wayland compatibility
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
  ];
  
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  hardware.nvidia = {
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    open = false;
    nvidiaSettings = true;

    # Enables native driver power management, resolving RmInitAdapter crashes
    powerManagement.enable = true;
    powerManagement.finegrained = true;
  };

  hardware.nvidia.prime = {
    # Keep offload enabled to satisfy Wayland requirements, but it will be overridden by WLR_DRM_DEVICES
    offload.enable = true;
    offload.enableOffloadCmd = true;
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
