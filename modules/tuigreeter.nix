{ pkgs, userConfig, ... }:
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --asterisks --greeting 'Welcome to Perseus' --cmd sway";
        user = "greeter";
      };
    };
  };

  console = {
    earlySetup = true;
    colors = [
      "0a0a14"  # black (dark navy)
      "ff6b6b"  # red
      "4ecdc4"  # green  
      "45b7d1"  # yellow (blue-ish)
      "96ceb4"  # blue (mint)
      "feca57"  # magenta (warm yellow)
      "48dbfb"  # cyan (bright blue)
      "f8f8f2"  # white
      "44475a"  # bright black (darker navy)
      "ff7979"  # bright red
      "55efc4"  # bright green
      "74b9ff"  # bright yellow (blue)
      "a29bfe"  # bright blue (purple)
      "fd79a8"  # bright magenta (pink)
      "81ecec"  # bright cyan
      "ffffff"  # bright white
    ];
  };

  boot.kernelParams = [
    # "mem_sleep_default=deep"
    "console=tty1"
    "quiet"
    "loglevel=3"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "vt.global_cursor_default=0"
  ];

  environment.etc."motd".text = ''


    ██████╗ ███████╗██████╗ ███████╗███████╗██╗   ██╗███████╗
    ██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝██║   ██║██╔════╝
    ██████╔╝█████╗  ██████╔╝███████╗█████╗  ██║   ██║███████╗
    ██╔═══╝ ██╔══╝  ██╔══██╗╚════██║██╔══╝  ██║   ██║╚════██║
    ██║     ███████╗██║  ██║███████║███████╗╚██████╔╝███████║
    ╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚══════╝

              ᴘᴜʀᴘᴏsᴇ ʙᴜɪʟᴛ ғᴏʀ ᴘʀɪᴠᴀᴄʏ ᴀɴᴅ ᴅᴇᴠᴇʟᴏᴘᴍᴇɴᴛ

  '';

  systemd.services."getty@tty1" = {
    overrideStrategy = "asDropin";
    serviceConfig.ExecStart = [
      ""
      "@${pkgs.util-linux}/sbin/agetty agetty --noclear --keep-baud tty1 115200,38400,9600 $TERM"
    ];
  };
}
