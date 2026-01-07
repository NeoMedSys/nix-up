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

      # 2. Peripherals
      allow id 046d:c08b  # Logitech G502 Mouse

      # 3. Fail-safe Interface Classes
      allow with-interface equals { 09:*:* }
      allow with-interface equals { ff:*:* }
      allow with-interface equals { 03:*:* }
      allow with-interface equals { 11:*:* }
    '';
  };
}
