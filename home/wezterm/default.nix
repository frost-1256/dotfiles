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
      # 字形を細めに見せる。HackGen は Regular / Bold しか無いので weight では細くできず、
      # hinting を Light にしてステムの太らせ (グリッド合わせ) を弱める
      freetype_load_target = "Light";
      color_scheme = "Dracula (Official)";
      # Dracula の背景 #282a36 は青紫寄りで好みでないため、背景だけ無彩色の黒に差し替える
      # (文字色・ANSI 色は Dracula のまま)。タブバーの地も同じ黒に揃える
      colors = {
        background = "#101010";
        tab_bar = {
          background = "#101010";
          inactive_tab = {
            bg_color = "#101010";
            fg_color = "#f8f8f2";
          };
        };
      };
      # 0.3 だと明るい壁紙の上で紫・白の文字が埋もれて読みにくく、0.75 だと透け感が
      # 足りない (2026-11-15)。Niri の blur + xray と合わせた妥協点
      window_background_opacity = 0.5;
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
