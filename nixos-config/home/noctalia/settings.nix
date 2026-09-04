{
  theme = {
    mode = "dark";
    source = "custom";
    custom_palette = "Dracula";
    builtin = "Kanagawa";
    wallpaper_scheme = "m3-tonal-spot";
  };

  wallpaper = {
    enabled = true;
    directory = "/home/spring/Pictures";
    default.path = "/home/spring/Pictures/vrchat-01.jpg";
  };

  backdrop = {
    enabled = true;
    blur_intensity = 0.5;
    tint_intensity = 0.3;
  };

  shell = {
    font_family = "JetBrains Mono";
    launch_apps_as_systemd_services = true;
    niri_overview_type_to_launch_enabled = true;
    polkit_agent = true;
    screen_time_enabled = true;
    animation.speed = 2.5;
    shadow.direction = "center";
    panel = {
      open_near_click_control_center = true;
      open_near_click_launcher = true;
      open_near_click_clipboard = true;
      open_near_click_wallpaper = true;
      session_position = "center";
    };
  };

  bar.default.start = [ "workspaces" "media" ];

  bar.default.end = [ "tray" "notifications" "network" "bluetooth" "brightness" "volume" "cat" "battery" "session" ];

  bar.default.background_opacity = 0.5;

  bar.default.dead_zone.actions.right = "none";

  battery.warning_threshold = 20;

  control_center.shortcuts = [
    { type = "wifi"; }
    { type = "bluetooth"; }
    { type = "nightlight"; }
    { type = "wallpaper"; }
    { type = "notification"; }
    { type = "power_profile"; }
  ];

  location.auto_locate = true;

  idle = {
    behavior_order = [ "screen-off" "suspend" ];
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

  lockscreen_widgets = {
    enabled = true;
    schema_version = 2;
    widget_order = [ "lockscreen-login-box@eDP-1" "lockscreen-widget-0000000000000001" ];
    grid = {
      cell_size = 16;
      major_interval = 4;
      visible = true;
    };
    widget."lockscreen-login-box@eDP-1" = {
      box_height = 229.0;
      box_width = 810.0;
      cx = 960.0;
      cy = 1061.5;
      output = "eDP-1";
      rotation = 0.0;
      type = "login_box";
      settings = {
        background_color = "surface_variant";
        background_opacity = 0.3;
        background_radius = 12.0;
        center_password_text = false;
        input_opacity = 1.0;
        input_radius = 6.0;
        layout = "regular";
        show_caps_lock = true;
        show_keyboard_layout = true;
        show_login_button = true;
        show_media = true;
        show_session_buttons = true;
        show_weather = true;
      };
    };
    widget."lockscreen-widget-0000000000000001" = {
      box_height = 96.0;
      box_width = 368.0;
      cx = 960.0;
      cy = 72.0;
      output = "eDP-1";
      rotation = 0.0;
      type = "clock";
      settings = {
        background_opacity = 0.3;
        center_text = true;
        clock_style = "digital";
        shadow = false;
        timezone = "Asia/Tokyo";
      };
    };
  };

  plugins = {
    enabled = [ "dotnetrob/cat" ];
    source = [
      {
        kind = "git";
        location = "https://github.com/noctalia-dev/official-plugins";
        name = "official";
      }
      {
        kind = "git";
        location = "https://github.com/noctalia-dev/community-plugins";
        name = "community";
      }
      {
        kind = "git";
        location = "https://github.com/OHMCFXG/noctalia-plugins.git";
        name = "personal";
      }
    ];
  };

  widget.cat = {
    cat_color = "on_surface";
    cat_color_mode = "custom";
    cat_size = 28;
    type = "dotnetrob/cat:cat";
  };
}
