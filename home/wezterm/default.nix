{ pkgs, ... }:
let
  # 太字用フォント。HackGen の Bold は日本語部分 (源柔ゴシック Bold) が太すぎて、
  # 12.5pt では「鬱」「議」等の画数の多い漢字が塗りつぶされて潰れる (Claude Code の
  # **strong** 等で顕著。2026-11-16 スクショで比較)。
  # 対策: HackGen Regular のファミリ名だけ変えたコピー ("HackGen Console NF Synth") を
  # build 時に作り、太字はそれを weight=Bold で要求する。Bold 体が存在しないので
  # WezTerm が Regular から合成ボールド (輪郭を少しだけ太らせる) を作る。字形は地の文と
  # 同じまま、本物の Bold より細いので画数の多い漢字も潰れない。
  # 不採用: Noto Sans Mono CJK JP Bold (潰れはしないが地の文と書体がずれて浮く)、
  # Hack Nerd Font + scale=0.83 (字高が縮む)。
  hackgenSynth =
    pkgs.runCommand "hackgen-console-nf-synth"
      { nativeBuildInputs = [ pkgs.python3Packages.fonttools ]; }
      ''
        mkdir -p $out/share/fonts/truetype
        ttx -q -t name -o name.ttx ${pkgs.hackgen-nf-font}/share/fonts/hackgen-nf/HackGenConsoleNF-Regular.ttf
        # family / full name / PostScript 名をすべて別名にする (元フォントと衝突させない)
        sed -i 's/HackGen Console NF/HackGen Console NF Synth/g; s/HackGenConsoleNF/HackGenConsoleNFSynth/g' name.ttx
        ttx -q -m ${pkgs.hackgen-nf-font}/share/fonts/hackgen-nf/HackGenConsoleNF-Regular.ttf \
          -o $out/share/fonts/truetype/HackGenConsoleNFSynth-Regular.ttf name.ttx
      '';
  # 罠: 生テーブルなので各エントリに is_fallback / is_synthetic が必須
  boldFont = italic: {
    inherit italic;
    intensity = "Bold";
    font.font = [
      {
        family = "HackGen Console NF Synth";
        weight = "Bold";
        style = if italic then "Italic" else "Normal";
        is_fallback = false;
        is_synthetic = false;
      }
    ];
  };
in
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
      # 合成ボールド用フォントは fontconfig に登録せず WezTerm だけに見せる
      # (システムのフォント一覧を汚さない。portable 側でもそのまま動く)
      font_dirs = [ "${hackgenSynth}/share/fonts/truetype" ];
      font_rules = [
        (boldFont false)
        (boldFont true)
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
      # 背景を黒 (#101010) にしたので、紫背景の 0.3 より文字が埋もれにくい。
      # 0.5 は透け感が足りなかった (2026-11-15)。Niri の blur + xray と合わせて調整
      window_background_opacity = 0.35;
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
