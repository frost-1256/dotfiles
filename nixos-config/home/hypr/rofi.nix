# modules/hypr/rofi.nix
{ pkgs, ... }: {
  programs.rofi = {
    enable   = true;
    package  = pkgs.rofi;
    font     = "Fira Code 10";
    terminal = "wezterm";
    extraConfig = {
      modi       = "window,drun,ssh,combi";
      combi-modi = "window,drun,ssh";
    };
    theme = "kipfel";
  };

  # テーマファイルを直接配置
  xdg.configFile."rofi/themes/kipfel.rasi".text = ''
    /* きぷきぷ — Matcha Latte / Material 3 */
    * {
        font:             "FiraCode Nerd Font Medium 11";
        primary:          #A4BC7C;
        on-primary:       #283418;
        matcha-soft:      rgba(164, 188, 124, 0.22);
        surface:          rgba(40, 47, 33, 0.94);
        surface-high:     rgba(64, 73, 53, 0.94);
        on-surface:       #ECE4CC;
        on-surface-dim:   #C4CDA8;
        outline:          rgba(120, 134, 92, 0.45);
        background-color: transparent;
        text-color:       #ECE4CC;
        transparent:      rgba(0,0,0,0);
    }
    window {
        location:         center;
        anchor:           center;
        transparency:     "real";
        padding:          0px;
        border:           0px;
        border-radius:    28px;
        background-color: @transparent;
        spacing:          0;
        children:         [mainbox];
        width:            860px;
    }
    mainbox {
        spacing:          0;
        children:         [ inputbar, listview ];
        border-radius:    28px;
        background-color: @surface;
    }
    inputbar {
        children:         [ prompt, entry ];
        padding:          18px 22px;
        background-color: @surface-high;
        border-radius:    28px 28px 0px 0px;
        border:           0px;
        text-color:       @on-surface;
    }
    prompt {
        margin:           0px 12px 0px 0px;
        text-color:       @primary;
    }
    entry {
        font:             inherit;
        text-color:       @on-surface;
        placeholder:      "Search...";
        placeholder-color: @on-surface-dim;
    }
    listview {
        padding:          8px;
        border-radius:    0px 0px 28px 28px;
        background-color: transparent;
        dynamic:          false;
        lines:            8;
        scrollbar:        false;
        spacing:          2px;
    }
    element {
        padding:          10px 16px;
        vertical-align:   0.5;
        border-radius:    14px;
        background-color: transparent;
        text-color:       @on-surface;
        spacing:          12px;
    }
    element normal.normal {
        background-color: transparent;
        text-color:       @on-surface;
    }
    element alternate.normal {
        background-color: transparent;
        text-color:       @on-surface;
    }
    element normal.active {
        background-color: @matcha-soft;
        text-color:       @primary;
    }
    element selected.normal {
        background-color: @primary;
        text-color:       @on-primary;
    }
    element selected.active {
        background-color: @primary;
        text-color:       @on-primary;
    }
    element-text {
        background-color: inherit;
        text-color:       inherit;
        vertical-align:   0.5;
    }
    element-icon {
        background-color: inherit;
        size:             1.2em;
    }
    message {
        padding:          10px 16px;
        background-color: transparent;
        text-color:       @on-surface-dim;
    }
  '';
}
