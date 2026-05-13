{ ... }: {
  programs.wezterm = {
    enable = true;
    settings = {
      automatically_reload_config = true;
      color_scheme = "Everforest Dark Soft (Gogh)";
      window_background_opacity = 0.4;
      hide_tab_bar_if_only_one_tab = true;
      use_fancy_tab_bar = true;
      show_new_tab_button_in_tab_bar = false;
      show_close_tab_button_in_tabs = false;
      window_frame = {
        inactive_titlebar_bg = "none";
        active_titlebar_bg = "none";
      };
      colors = {
        tab_bar = {
          inactive_tab_edge = "none";
        };
      };
    };
  };
}
