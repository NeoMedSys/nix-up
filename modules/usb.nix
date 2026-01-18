{ ... }:
{
  services.usbguard = {
    enable = true;
    presentDevicePolicy = "keep";
    rules = ''
      # 1. Infrastructure - Explicit Dell/Realtek Whitelist
      allow id 0bda:5487
      allow id 0bda:5413
      allow id 0bda:0487
      allow id 0bda:0413
      allow id 0bda:8153
      allow id 413c:b06e
      allow id 413c:b06f

      allow id 1d6b:0002 serial "0000:05:00.0" name "xHCI Host Controller"
      allow id 1d6b:0003 serial "0000:05:00.0" name "xHCI Host Controller"

      # 2. Peripherals
      allow id 046d:c08b  # Logitech G502 Mouse
      allow with-connect-type "hardwired"

      # 3. Fail-safe Interface Classes
      allow with-interface equals { 09:*:* }
      allow with-interface equals { ff:*:* }
      allow with-interface equals { 03:*:* }
      allow with-interface equals { 11:*:* }
    '';
  };
}
