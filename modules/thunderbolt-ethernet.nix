{ ... }:
{
  # Thunderbolt dock ethernet support
  # Adds kernel modules for common USB/Thunderbolt ethernet controllers
  
  boot.kernelModules = [
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
  ];
  
  # Ensure modules are available in initrd if needed
  boot.initrd.kernelModules = [
    "usbnet"
    "r8152" 
  ];
  
  # Enable USB support (should already be enabled but ensure it)
  boot.kernelParams = [
    "usbcore.autosuspend=-1"  # Disable USB autosuspend for docks
  ];
}
