# In modules/dunst.nix
{ ... }:
{
  services.dunst = {
    enable = true;
    settings = {
      global = {
        # Use the same Nerd Font
        font = "MesloLGS NF 10";
        format = "%s %b";
        follow = "mouse";
        # Nord theme colors
        frame_color = "#4C566A";
        separator_color = "#4C566A";
      };
      urgency_low = {
        background = "#2E3440";
        foreground = "#D8DEE9";
        timeout = 10;
      };
      urgency_normal = {
        background = "#2E3440";
        foreground = "#D8DEE9";
        timeout = 10;
      };
      urgency_critical = {
        background = "#BF616A";
        foreground = "#ECEFF4";
        timeout = 0;
      };
    };
  };
}
