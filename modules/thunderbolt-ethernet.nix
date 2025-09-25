{ lib, userConfig, pkgs, ... }:
{
  services.hardware.bolt.enable = true;

  boot.kernelModules = [
    "thunderbolt"
    "usbnet"
    "r8152"
    "asix"
    "cdc_ether"
    "cdc_ncm"
    "ax88179_178a"
    "smsc95xx"
    "usbhid"
    "hid_generic"
    "hid_multitouch"
  ];
  boot.initrd.kernelModules = [
    "thunderbolt"
    "usbnet"
    "r8152"
  ];
  boot.kernelParams = [
    "usbcore.autosuspend=-1"
    "pcie_aspm=off"
    "thunderbolt.dyndbg=+p"
    "usb-storage.delay_use=0"
    # Dell WD19TB specific fixes
    "pci=realloc"
    "pcie_ports=native"
  ] ++ lib.optionals userConfig.hasGPU [
   "nvidia_drm.modeset=1"
  ];

  # Enhanced udev rules for Dell WD19TB dock
  services.udev.extraRules = ''
    # Handle Thunderbolt dock reconnection with better timing
    ACTION=="change", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="1", RUN+="/bin/sh -c 'sleep 2 && echo 1 > /sys/bus/pci/rescan'"
    
    # Force PCI device enumeration for dock devices
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x15*", RUN+="/bin/sh -c 'echo 1 > /sys/bus/pci/rescan'"
    
    # Handle USB hub reconnection specifically for Dell dock
    # ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0413", ATTR{idProduct}=="81*", RUN+="/bin/sh -c 'sleep 1 && echo 1 > /sys/bus/usb/usb*/authorized'"
    
    # Reset USB ports on dock reconnect
    # ACTION=="add", SUBSYSTEM=="usb", ATTR{bDeviceClass}=="09", RUN+="/run/current-system/sw/bin/thunderbolt-dock-reset"
  '';
}

