{ config, pkgs, lib, ... }:
{
	# Allow unfree packages for NVIDIA drivers
  nixpkgs.config.allowUnfree = true;
  
  # NVIDIA hardware configuration
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    open = false;
    prime = {
      offload.enable = true;
      sync.enable = false;
    };
  };
	
  # NVIDIA container support for Docker/Podman
  hardware.nvidia-container-toolkit.enable = true;
  
  # Boot configuration
  boot = {
          blacklistedKernelModules = [ "nouveau" "nvidiafb" ];
          extraModulePackages = with config.boot.kernelPackages; [
                  nvidiaPackages.stable
          ];
          initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
          kernelParams = [ "nvidia-drm.modeset=1" ];
  };
  
  # Xorg configuration
  services.xserver.videoDrivers = [ "nvidia" ];
  
  # Udev rules for NVIDIA
  services.udev.packages = [ config.boot.kernelPackages.nvidiaPackages.stable ];
  
  # System packages for NVIDIA support
  environment.systemPackages = with pkgs; [
          config.boot.kernelPackages.nvidiaPackages.stable
          nvidia-container-toolkit
          nvtopPackages.nvidia
  ];
}
