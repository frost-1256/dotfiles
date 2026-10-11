# modules/hypr/hypridle.nix
{ ... }: {
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        # avoid starting multiple hyprlock instances.
        lock_cmd = "pidof hyprlock || hyprlock";
        # lock before suspend.
        before_sleep_cmd = "loginctl lock-session";
        # to avoid having to press a key twice to turn on the display.
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        # dim the screen: set monitor backlight to minimum, avoid 0 on OLED.
        {
          timeout = 150;
          on-timeout = "brightnessctl -s set 10";
          on-resume = "brightnessctl -r";
        }
        # turn off keyboard backlight.
        {
          timeout = 150;
          on-timeout = "brightnessctl -sd tpacpi::kbd_backlight set 0";
          on-resume = "brightnessctl -rd rgb:kbd_backlight";
        }
        # lock screen when timeout has passed.
        {
          timeout = 300;
          on-timeout = "hyprlock";
        }
        # screen off when timeout has passed.
        {
          timeout = 330;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on && brightnessctl -r";
        }
        # suspend pc.
        {
          timeout = 1800;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
