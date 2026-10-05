{
  # Dracula カスタムパレットを使う
  theme = {
    mode = "dark";
    source = "custom";
    custom_palette = "Dracula";
    builtin = "Dracula";
    community_palette = "Catppuccin Mocha Lavender";
    wallpaper_scheme = "m3-monochrome";
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
    avatar_path = "/home/spring/Pictures/images.jpg";
    password_style = "random";
    animation.speed = 2.5;
    shadow.direction = "center";
    launcher = {
      compact = true;
      show_app_actions = true;
    };
    panel = {
      open_near_click_control_center = true;
      open_near_click_launcher = false;
      open_near_click_clipboard = true;
      open_near_click_wallpaper = true;
      session_position = "auto";
    };
    window_switcher.style = "compact";
  };

  bar.default.start = [
    "workspaces"
    "media"
  ];

  bar.default.end = [
    "tray"
    "notifications"
    "network"
    "bluetooth"
    "brightness"
    "volume"
    "cat"
    "battery"
    "session"
  ];

  bar.default.background_opacity = 0.5;

  bar.default.contact_shadow = true;

  bar.default.dead_zone.actions.right = "none";

  battery.warning_threshold = 20;

  brightness.minimum_brightness = 0.1;

  calendar = {
    enabled = true;
    account.personal_google = {
      name = "Google Calender";
      type = "google";
    };
  };

  control_center.shortcuts = [
    { type = "wifi"; }
    { type = "bluetooth"; }
    { type = "nightlight"; }
    { type = "wallpaper"; }
    { type = "notification"; }
    { type = "power_profile"; }
  ];

  control_center.calendar.show_events_card = false;

  location.auto_locate = true;

  osd = {
    background_opacity = 0.5;
    border = false;
  };

  idle = {
    behavior_order = [
      "screen-off"
      "suspend"
    ];
    behavior = {
      "screen-off" = {
        timeout = 300;
        action = "screen_off";
        enabled = false;
      };
      suspend = {
        timeout = 420;
        action = "lock_and_suspend";
        enabled = false;
      };
    };
  };

  lockscreen_widgets = {
    enabled = true;
    schema_version = 2;
    widget_order = [
      "lockscreen-login-box@eDP-1"
      "lockscreen-widget-0000000000000001"
    ];
    grid = {
      cell_size = 16;
      major_interval = 4;
      visible = true;
    };
    widget."lockscreen-login-box@eDP-1" = {
      box_height = 196.0;
      box_width = 810.0;
      cx = 960.0;
      cy = 1061.5;
      output = "eDP-1";
      placement_height = 1200.0;
      placement_width = 1920.0;
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
        show_unlock_hint = true;
        show_weather = true;
      };
    };
    widget."lockscreen-widget-0000000000000001" = {
      box_height = 96.0;
      box_width = 368.0;
      cx = 960.0;
      cy = 72.0;
      output = "eDP-1";
      placement_height = 1200.0;
      placement_width = 1920.0;
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
