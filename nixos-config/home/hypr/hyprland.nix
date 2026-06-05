# modules/hypr/hyprland.nix
{ pkgs, ... }: {
  wayland.windowManager.hyprland = {
    enable = true;
    # stateVersion 26.11 だと configType 既定が "lua"(hyprland.lua) になるが、
    # 変換前は hyprlang(hyprland.conf) なので明示する。
    configType = "hyprlang";
    # パッケージ/ポータルは変換前と同様 home.packages 側で管理する。
    # ここでは設定ファイル(hyprland.conf)の生成だけをモジュールに任せる。
    package = null;
    portalPackage = null;
    # 変換前は systemd 連携なし。enable=true だと exec-once に
    # dbus-update-activation-environment が注入されてしまうため無効化する。
    systemd.enable = false;

    settings = {
      ### variables ###
      "$terminal" = "wezterm";
      "$fileManager" = "nautilus";
      "$menu" = "rofi -show drun";
      "$runMenu" = "rofi -show run";
      "$mainMod" = "SUPER";

      ### Monitor ###
      monitor = ",preferred,auto,1";

      ### Autostart ###
      exec-once = [
        "nm-applet & blueman-applet"
        "waybar"
        "awww-daemon"
        "fcitx5"
        "hypridle"
        "wl-paste --watch cliphist store"
        "dunst"
        "vesktop"
        "systemctl --user start hazkey-server"
      ];

      ### Environment variables ###
      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        "HYPRCURSOR_THEME,rose-pine-hyprcursor"
        "STEAM_EXTRA_COMPAT_TOOLS_PATHS,$HOME/.steam/root/compatibilitytools.d"
      ];

      ### Window decorations ###
      general = {
        gaps_in = 6;
        gaps_out = 14;
        border_size = 1;
        "col.active_border" = "rgba(a4bc7ccc) rgba(88a860cc) 45deg";
        "col.inactive_border" = "rgba(2c342240)";
        resize_on_border = true;
        allow_tearing = false;
        layout = "dwindle";
      };

      decoration = {
        rounding = 16;
        rounding_power = 2;
        active_opacity = 1.0;
        inactive_opacity = 1.0;
        shadow = {
          enabled = true;
          range = 24;
          render_power = 2;
          color = "rgba(0d0a0766)";
          offset = "0 4";
        };
        blur = {
          enabled = true;
          size = 8;
          passes = 3;
          vibrancy = 0.2;
          new_optimizations = true;
        };
      };

      animations = {
        enabled = "yes, please :)";
        #        NAME,           X0,   Y0,   X1,   Y1
        bezier = [
          "easeOutQuint, 0.23, 1, 0.32, 1"
          "easeInOutCubic, 0.65, 0.05, 0.36, 1"
          "linear, 0, 0, 1, 1"
          "almostLinear, 0.5, 0.5, 0.75, 1"
          "quick, 0.15, 0, 0.1, 1"
        ];
        #           NAME,          ONOFF, SPEED, CURVE,        [STYLE]
        animation = [
          "global, 1, 5, default"
          "border, 1, 5.39, easeOutQuint"
          "windows, 1, 1.5, easeOutQuint"
          "windowsIn, 1, 1.5, easeOutQuint, popin 87%"
          "windowsOut, 1, 1.49, linear, popin 87%"
          "fadeIn, 1, 1.5, almostLinear"
          "fadeOut, 1, 1.5, almostLinear"
          "fade, 1, 1.5, quick"
          "layers, 1, 3.81, easeOutQuint"
          "layersIn, 1, 4, easeOutQuint, fade"
          "layersOut, 1, 1.5, linear, fade"
          "fadeLayersIn, 1, 1.79, almostLinear"
          "fadeLayersOut, 1, 1.39, almostLinear"
          "workspaces, 1, 1.94, almostLinear, fade"
          "workspacesIn, 1, 1.21, almostLinear, fade"
          "workspacesOut, 1, 1.94, almostLinear, fade"
          "zoomFactor, 1, 7, quick"
        ];
      };

      ### INPUT ###
      input = {
        kb_layout = "us";
        kb_variant = "";
        kb_model = "";
        kb_options = "ctrl:nocaps";
        kb_rules = "";

        follow_mouse = 1;
        force_no_accel = false;
        accel_profile = "flat";
        sensitivity = 0.5;
        touchpad = {
          natural_scroll = true;
          scroll_factor = 1;
        };
      };

      device = {
        name = "tpps/2-elan-trackpoint";
        sensitivity = 0.6;
      };

      ### KEYBINDINGS ###
      ## Application ##
      bind = [
        "$mainMod, Q, exec, $terminal"
        "$mainMod SHIFT, Q, killactive,"
        "$mainMod, P, exec, wlogout"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, V, togglefloating,"
        "$mainMod, D, exec, $menu"
        "$mainMod SHIFT, D, exec, $runMenu"
        "$mainMod SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"
        "$mainMod SHIFT, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"

        ## Window management ##
        "$mainMod, J, layoutmsg, togglesplit"
        "$mainMod, h, movefocus, l"
        "$mainMod, j, movefocus, r"
        "$mainMod, k, movefocus, u"
        "$mainMod, l, movefocus, d"

        "$mainMod SHIFT, h, movewindow, l"
        "$mainMod SHIFT, j, movewindow, d"
        "$mainMod SHIFT, k, movewindow, u"
        "$mainMod SHIFT, l, movewindow, r"

        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      ## Hardware keys ##
      bindel = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ",XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
        ",XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
      ];

      ## Sensors ##
      bindl = [
        ", switch:Lid Switch, exec, hyprlock;systemd suspend"
      ];

      ### Windows and workspaces ###
      windowrule = [
        {
          name = "suppress-maximize-events";
          "match:class" = ".*";
          suppress_event = "maximize";
        }
        {
          name = "fix-xwayland-drags";
          "match:class" = "^$";
          "match:title" = "^$";
          "match:xwayland" = true;
          "match:float" = true;
          "match:fullscreen" = false;
          "match:pin" = false;
          no_focus = true;
        }
        {
          name = "move-hyprland-run";
          "match:class" = "hyprland-run";
          move = "20 monitor_h-120";
          float = true;
        }
      ];

      ### Other settings ###
      "ecosystem:no_update_news" = true;
    };
  };

  home.packages = with pkgs; [
    # Hyprland
    hyprland

    # Terminal & Apps
    wezterm
    nautilus

    # Bar & Notifications
    waybar
    dunst

    # Wallpaper
    awww

    # Launcher & Menus
    rofi

    # Lock & Idle
    hypridle
    hyprlock

    # Network & Bluetooth
    networkmanagerapplet
    blueman

    # Clipboard
    cliphist
    wl-clipboard

    # Screenshot
    grim
    slurp

    # Logout
    wlogout

    # Cursor theme
    rose-pine-hyprcursor

    # Audio & Brightness (CLIツール)
    wireplumber      # wpctl
    brightnessctl

    # Chat
    vesktop
  ];

  home.sessionVariables.NIXOS_OZONE_WL = "1";
}
