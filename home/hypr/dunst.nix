# modules/hypr/dunst.nix
{ ... }: {
  services.dunst = {
    enable = true;
    # NOTE: home-manager の dunst モジュールは iconTheme(既定 hicolor) から
    # global.icon_path を自動注入する。変換前も services.dunst.enable=true で
    # 同じ icon_path が効いていた（xdg.configFile.text の lines マージで連結）
    # ので、ここでは上書きせず既定のまま＝現行挙動を維持する。
    settings = {
      global = {
        monitor = 0;
        follow = "mouse";

        width = 320;
        height = "(0, 120)";
        origin = "top-right";
        offset = "(12, 48)";
        scale = 0;
        notification_limit = 5;

        padding = 14;
        horizontal_padding = 16;
        text_icon_padding = 12;
        frame_width = 0;
        gap_size = 8;
        separator_height = 0;
        sort = true;

        corner_radius = 16;
        frame_color = "#4E5A38B2";
        separator_color = "frame";
        background = "#2A3122E6";
        foreground = "#ECE4CC";

        font = "FiraCode Nerd Font 11";
        line_height = 2;
        markup = "full";
        format = "<b>%s</b>\\n%b";
        alignment = "left";
        vertical_alignment = "center";
        word_wrap = true;
        ellipsize = "middle";
        ignore_newline = false;
        stack_duplicates = true;
        hide_duplicate_count = false;
        show_indicators = true;

        icon_position = "left";
        min_icon_size = 32;
        max_icon_size = 48;

        sticky_history = true;
        history_length = 20;
        always_run_script = true;
        title = "Dunst";
        class = "Dunst";
        ignore_dbusclose = false;

        mouse_left_click = "close_current";
        mouse_middle_click = "do_action, close_current";
        mouse_right_click = "close_all";
      };

      experimental = {
        per_monitor_dpi = false;
      };

      urgency_low = {
        background = "#323A28CC";
        foreground = "#C4CDA8";
        frame_color = "#4A5638B2";
        timeout = 4;
      };

      urgency_normal = {
        background = "#2A3122E6";
        foreground = "#ECE4CC";
        frame_color = "#5A6840B2";
        timeout = 6;
      };

      urgency_critical = {
        background = "#4A2A1EF0";
        foreground = "#F0C8B0";
        frame_color = "#CC7059";
        highlight = "#CC7059";
        timeout = 0;
      };
    };
  };
}
