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

  # TLP RUNTIME_PM_DENYLIST moved to environment.nix to prevent module collisions

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="1", \
      RUN+="${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/sleep 3 && echo 1 > /sys/bus/pci/rescan'"

    ACTION=="change", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="1", \
      RUN+="${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/sleep 3 && echo 1 > /sys/bus/pci/rescan'"
  '';
}
