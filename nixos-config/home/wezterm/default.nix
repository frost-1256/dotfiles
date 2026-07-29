{ ... }: {
  programs.wezterm = {
    enable = true;
    settings = {
      automatically_reload_config = true;
      # fcitx5 を Wayland の text-input-v3 経由で使うには IME を有効化する必要がある
      use_ime = true;
      window_background_opacity = 0.3;
      hide_tab_bar_if_only_one_tab = true;
      use_fancy_tab_bar = false;
      mux_enable_ssh_agent = false;
      tab_bar_at_bottom = false;
      window_decorations = "NONE";
      show_new_tab_button_in_tab_bar = false;
      show_close_tab_button_in_tabs = false;
      window_frame = {
        inactive_titlebar_bg = "none";
        active_titlebar_bg = "none";
      };
      color_scheme = "Dracula (Official)";
    };
  };
}
