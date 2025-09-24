{ lib, userConfig, ... }:
{
  # Thunderbolt dock ethernet and general dock support
  # Adds kernel modules for common USB/Thunderbolt ethernet controllers + dock functionality
  
  # Thunderbolt service for dock authorization
  services.hardware.bolt.enable = true;
  
  boot.kernelModules = [
    # Thunderbolt support
    "thunderbolt"
    
    # USB ethernet base support
    "usbnet"
    # Realtek USB ethernet (very common in docks like Belkin)
    "r8152"
    # ASIX USB ethernet controllers
    "asix"
    # CDC ethernet (USB Communications Device Class)
    "cdc_ether"
    "cdc_ncm"
    # Additional USB ethernet drivers
    "ax88179_178a"  # ASIX AX88179/178A USB 3.0/2.0 to Gigabit Ethernet
    "smsc95xx"      # SMSC LAN95XX USB 2.0 Ethernet
    
    # USB HID support for dock peripherals
    "usbhid"
    "hid_generic"
    "hid_multitouch"
  ];
  
  # Ensure modules are available in initrd if needed
  boot.initrd.kernelModules = [
    "thunderbolt"
    "usbnet"
    "r8152"
  ];
  
  # Kernel parameters for better dock support
  boot.kernelParams = [
    "pcie_aspm=off"
    # Thunderbolt debugging and better support
    "thunderbolt.dyndbg=+p"
    # USB improvements for dock peripherals
    "usbcore.autosuspend=-1"
    # Better USB power management
    "usb-storage.delay_use=0"
  ] ++ lib.optionals userConfig.hasGPU [
   "nvidia_drm.modeset=1"
  ];
}
