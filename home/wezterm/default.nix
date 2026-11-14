{ ... }:
{
  programs.wezterm = {
    enable = true;
    settings = {
      automatically_reload_config = true;
      # fcitx5 を Wayland の text-input-v3 経由で使うには IME を有効化する必要がある
      use_ime = true;

      # --- 描画レイテンシ ---
      # WebGpu (Vulkan, Intel Xe) は OpenGL より入力→描画が短い
      front_end = "WebGpu";
      webgpu_power_preference = "LowPower";
      # パネルは 60Hz (VRR 40-60Hz) なので max_fps は既定 60 のまま
      # カーソル点滅のイーズ等のアニメ用再描画を止める (点滅自体は残る)
      animation_fps = 1;
      cursor_blink_ease_in = "Constant";
      cursor_blink_ease_out = "Constant";
      scrollback_lines = 10000;

      # --- 見た目 ---
      # 罠: wezterm.font() を通さない生テーブルでは is_fallback / is_synthetic が
      # 必須フィールド (省略すると Config::from_dynamic で missing field エラー)
      font.font = [
        {
          family = "HackGen Console NF";
          is_fallback = false;
          is_synthetic = false;
        }
      ];
      font_size = 12.5;
      color_scheme = "Dracula (Official)";
      window_background_opacity = 0.3;
      # 装飾なし (Niri 側で prefer-no-csd)。fancy tab bar 不使用なので window_frame は不要
      window_decorations = "NONE";
      hide_tab_bar_if_only_one_tab = true;
      use_fancy_tab_bar = false;
      show_new_tab_button_in_tab_bar = false;
      show_close_tab_button_in_tabs = false;

      mux_enable_ssh_agent = false;
    };
  };
}
