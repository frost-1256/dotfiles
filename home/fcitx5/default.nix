{
  config,
  pkgs,
  ...
}@args:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  nix-hazkey = args.nix-hazkey;
in
{
  services.hazkey = {
    enable = true;
    server.package = nix-hazkey.packages.${system}.hazkey-server.override {
      enableVulkan = true;
    };
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    # fcitx5-mozc は mozc の bazel ビルドが qt6 uictool の
    # "Invalid class name" で落ちるため、回復するまで外す
    # fcitx5-mozc
    #
    # qt6Packages.fcitx5-configtool は KDE Frameworks → pyside6 → qtwebengine
    # (Chromium ビルド) を引いて重いため外し、設定は下の settings で宣言する
    fcitx5.addons = [ ];
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
          DefaultIM = "hazkey";
        };
        "Groups/0/Items/0".Name = "keyboard-us";
        "Groups/0/Items/1".Name = "hazkey";
        GroupOrder."0" = "Default";
      };

      # ~/.config/fcitx5/conf/*.conf
      addons = {
        classicui.globalSection = {
          "Vertical Candidate List" = "False";
          WheelForPaging = "True";
          Font = ''"Sans 10"'';
          MenuFont = ''"Sans 10"'';
          TrayFont = ''"Sans Bold 10"'';
          TrayOutlineColor = "#000000";
          TrayTextColor = "#ffffff";
          PreferTextIcon = "False";
          ShowLayoutNameInIcon = "True";
          UseInputMethodLanguageToDisplayText = "True";
          Theme = "default-dark";
          DarkTheme = "default-dark";
          UseDarkTheme = "False";
          UseAccentColor = "True";
          PerScreenDPI = "False";
          ForceWaylandDPI = "0";
          EnableFractionalScale = "True";
        };
        hazkey.globalSection = {
          showTabToSelect = "True";
        };
      };
    };
  };

  # スリープ復帰系の対処:
  # - 復帰後 fcitx5 内の hazkey-server コネクタは再接続に失敗して入力が死ぶため、
  #   niri の lid-open フックで hazkey-server と一緒に fcitx5 も再起動する
  # - fcitx5 本体が復帰時にクラッシュした場合の保険として Restart=on-failure。
  #   always だと二重起動時の正常終了 (exit 0) でも再起動し無限ループになる
  #   (dbus 名取得失敗で exit 0 → 2 秒毎に再起動を延々繰り返していた)。
  # - hazkey-server は GPU 再生成中数回クラッシュしうるので、起動回数制限を外し
  #   RestartSec を稼がせて自動復帰させる
  systemd.user.services.fcitx5-daemon = {
    Unit.After = [ "hazkey-server.service" ];
    Service.Restart = "on-failure";
    Service.RestartSec = 2;
  };
  systemd.user.services.hazkey-server = {
    Unit.StartLimitBurst = 0;
    Service.RestartSec = 2;
  };
}
