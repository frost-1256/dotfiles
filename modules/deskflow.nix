{ pkgs, ... }:
let
  virtinput-portal = pkgs.callPackage ../pkgs/virtinput-portal.nix { };
in
{
  # Deskflow クライアント (Windows 側がサーバー、こちらが入力を受ける側)。
  # クライアントは RemoteDesktop portal の ConnectToEIS (libei) で入力を注入するが、
  # niri は RemoteDesktop を実装しておらず、既定ルーティング先の portal-gnome も
  # Mutter の RemoteDesktop D-Bus を要求するため niri 上では動かない。
  # そこで RemoteDesktop だけ virtinput-portal (自前パッケージ) に回す。
  # EIS サーバーを内蔵し、ポインタは zwlr_virtual_pointer、キーボードは
  # uinput (自前パッチ) で niri に流す。許可ダイアログは無い。
  # (luminous は ConnectToEIS のシグネチャ不一致で動かず不採用。2026-11-09)
  environment.systemPackages = [ pkgs.deskflow ];

  # extraPortals は portals/*.portal に加え dbus / systemd user unit も拾う。
  xdg.portal.extraPortals = [ virtinput-portal ];

  # /etc/xdg/xdg-desktop-portal/niri-portals.conf は niri パッケージ同梱の
  # share/.../niri-portals.conf より優先され、ファイル単位で置き換わる。
  # 同梱版の既定行 (gnome;gtk / Access・Notification=gtk / Secret=gnome-keyring)
  # を写した上で RemoteDesktop だけ差し替える。niri 側の同梱 conf が変わったら追従する。
  # ScreenCast は gnome (niri が Mutter ScreenCast を実装) のまま。
  xdg.portal.config.niri = {
    default = [
      "gnome"
      "gtk"
    ];
    "org.freedesktop.impl.portal.Access" = [ "gtk" ];
    "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
    "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
    "org.freedesktop.impl.portal.RemoteDesktop" = [ "virtinput" ];
  };

  # --- /dev/uinput を virtinput-portal 専用にする ---
  # hardware.uinput: uinput モジュール + uinput グループ + 0660/GROUP=uinput のルール。
  # spring は uinput グループに入れず、virtinput-portal だけ setgid ラッパーで
  # uinput グループ権限を得る。
  hardware.uinput.enable = true;
  security.wrappers.virtinput-portal = {
    source = "${virtinput-portal}/bin/virtinput-portal";
    owner = "root";
    group = "uinput";
    setgid = true;
  };
  # steam-hardware の 60-steam-input.rules が uinput に uaccess を付けて
  # セッションユーザー全プロセスに ACL で開放しているため、73-seat-late
  # (uaccess の適用) より前でタグを剥がす。代償として Steam Input の
  # コントローラ仮想化 (uinput 使用) は動かなくなる (2026-11-09 ユーザー判断)。
  # 既に付いた ACL はタグを剥がしても残るので、初回は `setfacl -b /dev/uinput` か再起動。
  services.udev.packages = [
    (pkgs.writeTextDir "lib/udev/rules.d/71-uinput-restrict.rules" ''
      KERNEL=="uinput", SUBSYSTEM=="misc", TAG-="uaccess", GROUP="uinput", MODE="0660"
    '')
  ];

  systemd.user.services.virtinput-portal.serviceConfig = {
    ExecStart = [
      ""
      "/run/wrappers/bin/virtinput-portal"
    ];
    # セッションを開けるのは Deskflow だけ (app_id は xdg-desktop-portal が判定)。
    Environment = [ "VIRTINPUT_ALLOWED_APP_IDS=org.deskflow.deskflow" ];
  };

  # クライアントはサーバー (TCP 24800) へ外向きに接続するだけなので受信ポートは不要。
}
