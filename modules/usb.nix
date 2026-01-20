# modules/usb.nix
{ ... }:
{
  services.usbguard = {
    enable = true;
    presentDevicePolicy = "keep";
    rules = ''
      # Infrastructure
      allow id 0bda:5487
      allow id 0bda:5413
      allow id 0bda:0487
      allow id 0bda:0413
      allow id 0bda:8153
      allow id 413c:b06e
      allow id 413c:b06f
      
      # Realtek Hubs inside Dell Docks
      allow id 0bda:5411
      allow id 0bda:0411

      # DualSense - Explicitly allow all interfaces for these IDs
      allow id 054c:0ce6
      allow id 054c:0df2

      # Host Controllers
      # We allow the generic Linux Foundation root hubs without hardcoded PCI serials.
      # This is critical because your Thunderbolt bus re-enumerates from 05:00.0
      # to 45:00.0 depending on plug order.
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
