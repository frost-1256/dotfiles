{
  theme = {
    mode = "dark";
    source = "custom";
    custom_palette = "Dracula";
  };

  wallpaper = {
    enabled = true;
    default.path = "/home/spring/.face";
    allowCaching = true;
  };

  launch_apps_as_systemd_services = true;

  shell.animation.speed = 2.0;

  bar.default.start = [ "workspaces" "media" ];

  bar.default.end = [ "tray" "notifications" "network" "bluetooth" "brightness" "volume" "battery" "session" ];

  bar.default.dead_zone.right_command = "none";
}
