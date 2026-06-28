{ ... }: {
  programs.wezterm = {
    enable = true;
    settings = {
      automatically_reload_config = true;
      # fcitx5 を Wayland の text-input-v3 経由で使うには IME を有効化する必要がある
      use_ime = true;
      window_background_opacity = 0.3;
      hide_tab_bar_if_only_one_tab = true;
      use_fancy_tab_bar = true;
      show_new_tab_button_in_tab_bar = false;
      show_close_tab_button_in_tabs = false;
      window_frame = {
        inactive_titlebar_bg = "none";
        active_titlebar_bg = "none";
      };
      colors = {
        foreground = "#ECE4CC";
        cursor_bg = "#FAF6E9";
        cursor_fg = "#222A18";
        cursor_border = "#FAF6E9";
        selection_bg = "#45522F";
        selection_fg = "#ECE4CC";
        scrollbar_thumb = "#45522F";
        split = "#566440";
        ansi = [
          "#2B3320"
          "#CC7059"
          "#A4BC7C"
          "#D8C070"
          "#88B8A0"
          "#C7A2A0"
          "#8FB8A4"
          "#ECE4CC"
        ];
        brights = [
          "#566440"
          "#D88A72"
          "#B6CA7A"
          "#E0CE8C"
          "#A0C8B4"
          "#D4B4C0"
          "#A8CEB8"
          "#FAF6E9"
        ];
        tab_bar = {
          background = "#222A18";
          inactive_tab_edge = "none";
          active_tab = {
            bg_color = "#A4BC7C";
            fg_color = "#222A18";
          };
          inactive_tab = {
            bg_color = "#323C28";
            fg_color = "#B8C39A";
          };
          inactive_tab_hover = {
            bg_color = "#45522F";
            fg_color = "#ECE4CC";
          };
          new_tab = {
            bg_color = "#323C28";
            fg_color = "#B8C39A";
          };
          new_tab_hover = {
            bg_color = "#45522F";
            fg_color = "#ECE4CC";
          };
        };
      };
    };
  };
}
