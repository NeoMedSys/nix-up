{ pkgs, ... }:
{
  services.hardware.bolt.enable = true;

  boot.initrd.availableKernelModules = [ 
    "usbhid" 
    "hid_generic" 
    "hid_multitouch" 
    "xhci_pci"
    "hid_logitech_dj"
    "thunderbolt"
  ];

  boot.kernelParams = [
    "pci=realloc"
    "pci=assign-busses"
    "pcie_ports=native"
  ];

  # The udev rule you trust—keeping it exactly as it was.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="1", \
      RUN+="${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/sleep 3 && echo 1 > /sys/bus/pci/rescan'"
    
    ACTION=="change", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="1", \
      RUN+="${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/sleep 3 && echo 1 > /sys/bus/pci/rescan'"
  '';
}
