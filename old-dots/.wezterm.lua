-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()
config.automatically_reload_config = true

config.color_scheme = 'Everforest Dark Soft (Gogh)'
config.window_background_opacity = 0.65
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true
config.show_new_tab_button_in_tab_bar = false
config.show_close_tab_button_in_tabs = false
config.window_frame = {
  inactive_titlebar_bg = "none",
  active_titlebar_bg = "none",
}
config.colors = {

  tab_bar = {

    inactive_tab_edge = "none",
  },
}
return config

