{ ... }:
{
  services.usbguard = {
    enable = true;
    presentDevicePolicy = "allow"; 
    rules = ''
      # Allow internal devices (adjust for your hardware)
      allow with-interface equals { 03:*:* }  # HID (keyboard/mouse)
      allow with-interface equals { 08:*:* }  # Mass storage
      allow with-interface equals { 09:*:* }  # Hub
      allow with-interface equals { 0e:*:* }  # Video
      
      # Block everything else by default
      reject
    '';
  };
}
