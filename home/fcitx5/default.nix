{
  config,
  pkgs,
  ...
}@args:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  sweet-ime = args.sweet-ime.packages.${system}.default;
in
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    # fcitx5-mozc は mozc の bazel ビルドが qt6 uictool の
    # "Invalid class name" で落ちるため、回復するまで外す
    # fcitx5-mozc
    #
    # qt6Packages.fcitx5-configtool は KDE Frameworks → pyside6 → qtwebengine
    # (Chromium ビルド) を引いて重いため外し、設定は下の settings で宣言する
    #
    # Sweet IME (自作の Rust 製 IME)。設定は sweet-settings、
    # ~/.config/sweet-ime/ に保存される。AI 変換モデルは設定アプリから入れる
    fcitx5.addons = [ sweet-ime ];
    # Wayland の text-input-v3 を使うので GTK_IM_MODULE / QT_IM_MODULE を設定しない
    # (Fcitx5 の "Wayland Diagnose" 通知対策)
    fcitx5.waylandFrontend = true;
    # fcitx5-with-addons は既定で configtool を同梱するので明示的に外す
    fcitx5.fcitx5-with-addons = pkgs.qt6Packages.fcitx5-with-addons.override {
      withConfigtool = false;
    };

    fcitx5.settings = {
      # ~/.config/fcitx5/config
      globalOptions = {
        Hotkey = {
          ModifierOnlyKeyTimeout = 500;
        };
        # Windows サーバー (Deskflow) 側の MS-IME が Alt+` の ` を握りつぶし
        # Alt 単打しか届かないため Alt_L も切替キーにしている
        "Hotkey/TriggerKeys" = {
          "0" = "Alt+grave";
          "1" = "Control+space";
          "2" = "Alt_L";
        };
        "Hotkey/EnumerateBackwardKeys" = {
          "0" = "";
          "1" = "";
        };
      };

      # ~/.config/fcitx5/profile
      inputMethod = {
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = "us";
          DefaultIM = "sweetime";
        };
        "Groups/0/Items/0".Name = "keyboard-us";
        "Groups/0/Items/1".Name = "sweetime";
        GroupOrder."0" = "Default";
      };

      # ~/.config/fcitx5/conf/*.conf
      addons = {
        classicui.globalSection = {
          "Vertical Candidate List" = "True";
          WheelForPaging = "True";
          Font = ''"Sans 10"'';
          MenuFont = ''"Sans 10"'';
          TrayFont = ''"Sans Bold 10"'';
          TrayOutlineColor = "#000000";
          TrayTextColor = "#ffffff";
          PreferTextIcon = "False";
          ShowLayoutNameInIcon = "True";
          UseInputMethodLanguageToDisplayText = "True";
          Theme = "sweet-ime-dracula";
          DarkTheme = "sweet-ime-dracula";
          UseDarkTheme = "False";
          UseAccentColor = "True";
          PerScreenDPI = "False";
          ForceWaylandDPI = "0";
          EnableFractionalScale = "True";
        };
      };
    };
  };

  # スリープ復帰系の対処:
  # - fcitx5 本体が復帰時にクラッシュした場合の保険として Restart=on-failure。
  #   always だと二重起動時の正常終了 (exit 0) でも再起動し無限ループになる
  #   (dbus 名取得失敗で exit 0 → 2 秒毎に再起動を延々繰り返していた)。
  # - Sweet IME は fcitx5 内で完結する (外部サーバーなし) ので、hazkey 時代の
  #   lid-open での再起動フックは不要
  # fcitx5 パッケージ同梱の XDG autostart (org.fcitx.Fcitx5.desktop) を殺す。
  # 起動は HM の fcitx5-daemon.service が担うので、残すと systemd-xdg-autostart-generator 経由の
  # app-org.fcitx.Fcitx5@autostart と 2 つ同時に起動する。両方が Wayland の input-method を
  # bind してから負けた側が dbus 名を取れずに終了するため、どちらが勝つか・IME が生きるかが
  # 起動ごとに変わり、ターミナル等で文字が打てなくなることがあった (2026-11-16 実測)。
  # ユーザー側の同名 .desktop に Hidden=true を置くとシステム側のエントリは無視される
  xdg.configFile."autostart/org.fcitx.Fcitx5.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Fcitx 5
    Hidden=true
  '';

  systemd.user.services.fcitx5-daemon = {
    Service.Restart = "on-failure";
    Service.RestartSec = 2;
  };
}
