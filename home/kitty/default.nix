{ ... }: {
  programs.kitty = {
    enable = true;

    settings = {
      # Reload config automatically
      allow_remote_control = "yes";

      # Appearance
      background_opacity = "0.3";

      # Tabs
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      tab_bar_min_tabs = 2;

      # Colors
      foreground = "#ECE4CC";
      cursor = "#FAF6E9";
      cursor_text_color = "#222A18";

      selection_background = "#45522F";
      selection_foreground = "#ECE4CC";

      scrollbar_thumb = "#45522F";

      # ANSI
      color0 = "#2B3320";
      color1 = "#CC7059";
      color2 = "#A4BC7C";
      color3 = "#D8C070";
      color4 = "#88B8A0";
      color5 = "#C7A2A0";
      color6 = "#8FB8A4";
      color7 = "#ECE4CC";

      # Bright ANSI
      color8 = "#566440";
      color9 = "#D88A72";
      color10 = "#B6CA7A";
      color11 = "#E0CE8C";
      color12 = "#A0C8B4";
      color13 = "#D4B4C0";
      color14 = "#A8CEB8";
      color15 = "#FAF6E9";

      # Tab bar
      active_tab_background = "#A4BC7C";
      active_tab_foreground = "#222A18";

      inactive_tab_background = "#323C28";
      inactive_tab_foreground = "#B8C39A";

      inactive_tab_hover_background = "#45522F";
      inactive_tab_hover_foreground = "#ECE4CC";

      # Font
      # font_family = "JetBrains Mono";
      # font_size = 12;
    };
  };
}
