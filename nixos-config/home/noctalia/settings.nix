{
  theme = {
    mode = "dark";
    source = "custom";
    custom_palette = "Dracula";
  };

  wallpaper = {
    enabled = true;
    default.path = "/home/spring/.face";
  };

  shell = {
    font_family = "JetBrains Mono";
    launch_apps_as_systemd_services = true;
    animation.speed = 2.5;
    panel = {
      open_near_click_control_center = true;
      open_near_click_launcher = true;
      open_near_click_clipboard = true;
      open_near_click_wallpaper = true;
    };
  };

  bar.default.start = [ "workspaces" "media" ];

  bar.default.end = [ "tray" "notifications" "network" "bluetooth" "brightness" "volume" "battery" "session" ];

  bar.default.dead_zone.actions.right = "none";

  idle = {
    behavior = {
      "screen-off" = {
        timeout = 300;
        action = "screen_off";
        enabled = true;
      };
      suspend = {
        timeout = 420;
        action = "lock_and_suspend";
        enabled = true;
      };
    };
  };
}
