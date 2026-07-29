# home-manager/modules/niri/config.nix
{ inputs, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
  ];

  programs.waybar.enable = lib.mkForce false;

  programs.niri.config = let
    inherit (inputs.niri.lib.kdl) node plain leaf flag;
  in [
    (leaf "prefer-no-csd" true)

    (plain "hotkey-overlay" [
      (flag "skip-at-startup")
    ])

    (plain "cursor" [
      (leaf "xcursor-theme" "Adwaita")
      (leaf "xcursor-size" 16)
    ])

    # 背景ブラー
    (plain "blur" [
      (leaf "passes" 3)
      (leaf "offset" 2.0)
      (leaf "noise" 0.02)
      (leaf "saturation" 1.2)
    ])

    (plain "window-rule" [
      (leaf "open-maximized" true)
    ])

    (plain "window-rule" [
      (leaf "clip-to-geometry" true)
      (leaf "draw-border-with-background" false)
    ])

    (plain "window-rule" [
      (leaf "geometry-corner-radius" 20)
      (leaf "clip-to-geometry" true)
    ])

    (plain "window-rule" [
      (leaf "match" { app-id = "dev.noctalia.Noctalia"; })
      (leaf "open-floating" true)
      (plain "default-column-width" [
        (leaf "fixed" 1080)
      ])
      (plain "default-window-height" [
        (leaf "fixed" 920)
      ])
    ])

    (plain "window-rule" [
      (leaf "match" { app-id = "^org.wezfurlong.wezterm$"; })
      (plain "background-effect" [
        (leaf "blur" true)
        (leaf "xray" true)
      ])
    ])

    # input
    (plain "input" [
      (plain "keyboard" [
        (plain "xkb" [
          (leaf "options" "ctrl:nocaps")
        ])
      ])

      (leaf "focus-follows-mouse" { max-scroll-amount = "0%"; })

      (plain "mouse" [
        (leaf "accel-profile" "flat")
      ])

      (plain "touchpad" [
        (flag "tap")
        (flag "natural-scroll")
      ])
    ])

    # output
    (node "output" "eDP-1" [
      (leaf "scale" 1.0)
      (leaf "transform" "normal")
      (leaf "mode" "1920x1200@60")
      (leaf "position" { x = 0; y = 0; })
    ])

    # layout
    (plain "layout" [
      # Dracula: focus-ring active=Purple, inactive=Surface Alt
      (plain "focus-ring" [
        (leaf "width" 2)
        (leaf "active-color" "#BD93F9")
        (leaf "inactive-color" "#44475A")
      ])

      (plain "border" [
        (flag "off")
      ])

      (plain "shadow" [
        (flag "on")
        (leaf "softness" 30)
        (leaf "spread" 5)
        (leaf "offset" { x = 0; y = 5; })
        # Dracula: shadow color with transparency
        (leaf "color" "#0007")
      ])

      (plain "preset-column-widths" [
        (leaf "proportion" (1.0 / 3.0))
        (leaf "proportion" (1.0 / 2.0))
        (leaf "proportion" (2.0 / 3.0))
      ])

      (plain "default-column-width" [
        (leaf "proportion" 0.5)
      ])

      (leaf "gaps" 16)

      (plain "struts" [])

      (leaf "center-focused-column" "never")
    ])

    # animations
    (plain "animations" [
      (plain "workspace-switch" [
        (leaf "spring" {
          damping-ratio = 1.0;
          stiffness = 1800;
          epsilon = 0.0001;
        })
      ])

      (plain "horizontal-view-movement" [
        (leaf "spring" {
          damping-ratio = 1.0;
          stiffness = 1600;
          epsilon = 0.0001;
        })
      ])

      (plain "window-open" [
        (leaf "spring" {
          damping-ratio = 1.0;
          stiffness = 1800;
          epsilon = 0.0001;
        })
      ])
    ])

    # binds
    (plain "binds" [
      (plain "Mod+Q" [
        (leaf "spawn" [ "wezterm" ])
      ])

      (plain "Mod+D" [
        (leaf "spawn-sh" "noctalia msg panel-toggle launcher")
      ])

      (plain "Mod+S" [
        (leaf "spawn-sh" "noctalia msg panel-toggle control-center")
      ])

      (plain "Alt+Tab" [
        (leaf "spawn-sh" "noctalia msg window-switcher")
      ])

      # Win+Tab で Overview 表示 (左上ホットコーナー廃止の代替)
      (plain "Super+Tab" [
        (flag "toggle-overview")
      ])

      (plain "Mod+Shift+Q" [
        (flag "close-window")
      ])

      # ウィンドウフォーカス移動 (Hyprland の Mod+HJKL)
      (plain "Mod+H" [
        (flag "focus-column-left")
      ])

      (plain "Mod+J" [
        (flag "focus-window-down")
      ])

      (plain "Mod+K" [
        (flag "focus-window-up")
      ])

      (plain "Mod+L" [
        (flag "focus-column-right")
      ])

      # ウィンドウ/カラム移動
      # ウィンドウ/カラム移動
      (plain "Mod+Shift+H" [
        (flag "move-column-left")
      ])

      (plain "Mod+Shift+J" [
        (flag "move-window-down")
      ])

      (plain "Mod+Shift+K" [
        (flag "move-window-up")
      ])

      (plain "Mod+Shift+L" [
        (flag "move-column-right")
      ])

      (plain "Mod+F" [
        (flag "maximize-window-to-edges")
      ])

      (plain "Mod+M" [
        (flag "maximize-column")
      ])

      (plain "Mod+U" [
        (flag "focus-workspace-up")
      ])

      (plain "Mod+I" [
        (flag "focus-workspace-down")
      ])

      (plain "Mod+Shift+F" [
        (flag "fullscreen-window")
      ])

      # ワークスペース切替 (Hyprland の Mod+1~9)
      (plain "Mod+1" [ (leaf "focus-workspace" 1) ])
      (plain "Mod+2" [ (leaf "focus-workspace" 2) ])
      (plain "Mod+3" [ (leaf "focus-workspace" 3) ])
      (plain "Mod+4" [ (leaf "focus-workspace" 4) ])
      (plain "Mod+5" [ (leaf "focus-workspace" 5) ])
      (plain "Mod+6" [ (leaf "focus-workspace" 6) ])
      (plain "Mod+7" [ (leaf "focus-workspace" 7) ])
      (plain "Mod+8" [ (leaf "focus-workspace" 8) ])
      (plain "Mod+9" [ (leaf "focus-workspace" 9) ])

      # ウィンドウをワークスペースへ移動 (Hyprland の Mod+Shift+1~9)
      (plain "Mod+Shift+1" [ (leaf "move-window-to-workspace" 1) ])
      (plain "Mod+Shift+2" [ (leaf "move-window-to-workspace" 2) ])
      (plain "Mod+Shift+3" [ (leaf "move-window-to-workspace" 3) ])
      (plain "Mod+Shift+4" [ (leaf "move-window-to-workspace" 4) ])
      (plain "Mod+Shift+5" [ (leaf "move-window-to-workspace" 5) ])
      (plain "Mod+Shift+6" [ (leaf "move-window-to-workspace" 6) ])
      (plain "Mod+Shift+7" [ (leaf "move-window-to-workspace" 7) ])
      (plain "Mod+Shift+8" [ (leaf "move-window-to-workspace" 8) ])
      (plain "Mod+Shift+9" [ (leaf "move-window-to-workspace" 9) ])

      # Win+Shift+S 選択領域スクリーンショット (クリップボードへ)
      (plain "Mod+Shift+S" [
        (leaf "spawn-sh" "grim -g \"$(slurp)\" - | wl-copy")
      ])

      # Win+Shift+V Noctalia クリップボードパネル
      (plain "Mod+Shift+V" [
        (leaf "spawn-sh" "noctalia msg panel-toggle clipboard")
      ])

      (plain "XF86AudioRaiseVolume" [
        (leaf "spawn-sh" "noctalia msg volume-up")
      ])

      (plain "XF86AudioLowerVolume" [
        (leaf "spawn-sh" "noctalia msg volume-down")
      ])

      (plain "XF86AudioMute" [
        (leaf "spawn-sh" "noctalia msg volume-mute")
      ])

      (plain "XF86MonBrightnessUp" [
        (leaf "spawn-sh" "noctalia msg brightness-up")
      ])

      (plain "XF86MonBrightnessDown" [
        (leaf "spawn-sh" "noctalia msg brightness-down")
      ])
    ])

    (plain "recent-windows" [
      (plain "binds" [])
    ])

    # ジェスチャー・ホットコーナー設定
    (plain "gestures" [
      (plain "hot-corners" [
        (flag "off")
      ])
    ])

    (plain "debug" [
      (flag "honor-xdg-activation-with-invalid-serial")
    ])
  ];
}
