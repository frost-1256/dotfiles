# home-manager/modules/niri/config.nix
{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
    xwayland-satellite-unstable
    nautilus
  ];

  programs.waybar.enable = lib.mkForce false;

  programs.niri.config =
    let
      inherit (inputs.niri.lib.kdl)
        node
        plain
        leaf
        flag
        ;

      # アニメーション用 spring (epsilon は全アニメ共通)
      spring =
        damping-ratio: stiffness:
        leaf "spring" {
          inherit damping-ratio stiffness;
          epsilon = 0.0001;
        };

      # Mod+1〜9 / Mod+Shift+1〜9 のように番号だけ違うバインドを生成する
      numberedBinds =
        prefix: action:
        builtins.genList (
          i:
          let
            n = i + 1;
          in
          plain "${prefix}${toString n}" [ (leaf action n) ]
        ) 9;
    in
    [
      (flag "prefer-no-csd")

      (plain "hotkey-overlay" [
        (flag "skip-at-startup")
      ])

      (plain "cursor" [
        (leaf "xcursor-theme" "Adwaita")
        (leaf "xcursor-size" 16)
      ])

      # 背景ブラー
      # passes は 1 で十分(3 pass は 1920x1200 で GPU 負荷が約 3 倍になり、
      # power-saver の PL1=10W 下でドラッグ中などにカクつく)。見た目の差は小さい。
      (plain "blur" [
        (leaf "passes" 1)
        (leaf "offset" 2.0)
        (leaf "noise" 0.02)
        (leaf "saturation" 1.2)
      ])

      (plain "window-rule" [
        (leaf "open-maximized" true)
      ])

      (plain "window-rule" [
        (leaf "geometry-corner-radius" 20)
        (leaf "clip-to-geometry" true)
        (leaf "draw-border-with-background" false)
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

      (plain "layer-rule" [
        (leaf "match" { namespace = "^noctalia-backdrop"; })
        (leaf "place-within-backdrop" true)
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
          # ポインタ感度を上げる (-1.0〜1.0、既定 0.0)。遅い/速いときはこの値を振る
          (leaf "accel-speed" 0.6)
        ])
      ])

      # output
      # spring-b550m-pro4 の外部ディスプレイ (IOD LCD-AD221X): EDID 最大 1680x1050、
      # DTD2 の 59.883Hz に固定 (59.954Hz の Standard Timing もあるが DTD 優先)。
      # コネクタ名 (HDMI-A-1) ではなく manufacturer + model + serial でマッチさせ、
      # この個体だけに適用する (コネクタ名マッチは記述マッチに勝つため両立させない)。
      (node "output" "I-O Data Device Inc LCD-AD221X   URJ20002954O" [
        (leaf "scale" 1.0)
        (leaf "transform" "normal")
        (leaf "mode" "1680x1050@59.883")
      ])

      (node "output" "eDP-1" [
        (leaf "scale" 1.0)
        (leaf "transform" "normal")
        (leaf "mode" "1920x1200@60")
        # パネル(AUO B140UAN02.7)が VRR 対応。フレーム提示が vblank 待ちから
        # 解放され、遅延とジャダーが減る(この niri では引数なし=常時有効)。
        (flag "variable-refresh-rate")
        (leaf "position" {
          x = 0;
          y = 0;
        })
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
          (leaf "offset" {
            x = 0;
            y = 5;
          })
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
      ])

      # animations
      (plain "animations" [
        (plain "workspace-switch" [ (spring 0.75 6000) ])
        (plain "horizontal-view-movement" [ (spring 0.75 5000) ])
        (plain "window-open" [ (spring 0.75 6000) ])

        # 以下は既定 (stiffness 800 / close は 150ms) のままだと上の 3 つより
        # 明らかに遅く見えるため揃える。移動・リサイズはオーバーシュートさせない
        # (damping 1.0) ことでレイアウト変化がブレずに速く収まる。
        (plain "window-close" [
          (leaf "duration-ms" 100)
          (leaf "curve" "ease-out-quad")
        ])

        (plain "window-movement" [ (spring 1.0 5000) ])
        (plain "window-resize" [ (spring 1.0 5000) ])
        (plain "overview-open-close" [ (spring 1.0 5000) ])
      ])

      # binds
      (plain "binds" (
        [
          (plain "Mod+Q" [
            (leaf "spawn" [ "wezterm" ])
          ])

          (plain "Mod+D" [
            (leaf "spawn-sh" "noctalia msg panel-toggle launcher")
          ])

          (plain "Mod+E" [
            (leaf "spawn" [ "nautilus" ])
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

          (plain "Mod+V" [
            (flag "toggle-window-floating")
          ])

          (plain "Mod+Shift+Space" [
            (flag "switch-focus-between-floating-and-tiling")
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

          (plain "Mod+Shift+F9" [
            (leaf "spawn-sh" "gsr-ui-cli toggle-record")
          ])

          (plain "Mod+Shift+F10" [
            (leaf "spawn-sh" "gsr-ui-cli toggle-show")
          ])
        ]
        # ワークスペース切替 / ウィンドウ移動 (Hyprland の Mod(+Shift)+1~9)
        ++ numberedBinds "Mod+" "focus-workspace"
        ++ numberedBinds "Mod+Shift+" "move-window-to-workspace"
      ))

      (plain "switch-events" [
        (plain "lid-close" [
          (leaf "spawn" [
            "noctalia"
            "msg"
            "session"
            "lock-and-suspend"
          ])
        ])
        (plain "lid-open" [
          # hazkey-server だけでは fcitx5 側のコネクタが張り付いたままなので
          # fcitx5 も一緒に再起動する (After 依存により起動順は保証される)
          (leaf "spawn" [
            "systemctl"
            "--user"
            "restart"
            "hazkey-server"
            "fcitx5-daemon.service"
          ])
        ])
      ])

      # 既定の Alt+Tab 系バインドを空にして Noctalia の window-switcher に譲る
      (plain "recent-windows" [
        (plain "binds" [ ])
      ])

      # ジェスチャー・ホットコーナー設定
      (plain "gestures" [
        (plain "hot-corners" [
          (flag "off")
        ])
      ])

      (plain "debug" [
        (flag "honor-xdg-activation-with-invalid-serial")
        # 復帰時に全出力を modeset し直してブランクにする。
        # サスペンド中にロック済みでも復帰直後にデスクトップが
        # 一瞬見える (session lock より先に描画される) 対策。
        (flag "force-disable-connectors-on-resume")
      ])
    ];
}
