# modules/usb.nix
{ ... }:
{
  services.usbguard = {
    enable = true;
    presentDevicePolicy = "keep";
    rules = ''
      # Infrastructure (Docks/Hubs)
      allow id 0bda:5487
      allow id 0bda:5413
      allow id 0bda:0487
      allow id 0bda:0413
      allow id 0bda:8153
      allow id 413c:b06e
      allow id 413c:b06f

      # DualSense - Explicitly allow all interfaces for these IDs
      allow id 054c:0ce6
      allow id 054c:0df2

      # Host Controllers (Root Hubs)
      # We allow these without hardcoded PCI serials because they change 
      # on Thunderbolt/PCIe hotplug events (e.g., shifting from 05:00.0 to 45:00.0)
      allow id 1d6b:0002
      allow id 1d6b:0003

      # Peripherals
      allow id 046d:c08b
      allow with-connect-type "hardwired"

      # Fail-safe Interface Classes
      allow with-interface equals { 09:*:* }
      allow with-interface equals { ff:*:* }
      allow with-interface equals { 03:*:* }
      allow with-interface equals { 01:*:* } # Audio interface for DualSense
      allow with-interface equals { 11:*:* }
    '';
  };
}
