{ ... }:
{
  services.displayManager.defaultSession = "none+i3";
  services.xserver.displayManager.lightdm = {
    enable = true;
    greeters.gtk.enable = true;
  };
}
