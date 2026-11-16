# 名前に反して GNOME 本体は有効化しない。GDM (ログイン画面) + gnome-keyring + GVfs のみ。
{ lib, config, ... }:
{
  # ── GDM をネットワーク待ちから外す (2026-11-15) ──
  # display-manager は systemd-user-sessions の後に並ぶが、上流の systemd-user-sessions は
  # After=network.target を持つため、NetworkManager の起動完了 (毎回 1.3〜2.7 秒) まで
  # ログイン画面が出なかった。drop-in では After= を消せないので、
  # - display-manager の after から systemd-user-sessions だけ外し、
  # - 代わりに /run/nologin (起動中ログイン禁止) を消すだけの早期ユニットを前に置く。
  # 上流 systemd-user-sessions はそのまま残る (後から走っても冪等。停止時の nologin 作成も維持)。
  # GDM 側の After を外すため、ネットワーク待ちの依存が戻っていないかは
  # `systemctl show display-manager -p After` で確認する
  # 自分自身の値は参照できない (無限再帰) ので、NixOS (display-managers / gdm) が
  # 入れる値から systemd-user-sessions を除いたものを写している。nixpkgs 更新で増えた分は
  # mkForce で消えるので、`nix eval ...display-manager.after` を時々見比べる
  systemd.services.display-manager.after = lib.mkForce [
    "rc-local.service"
    "systemd-machined.service"
    "plymouth-quit.service"
    "plymouth-start.service"
    "acpid.service"
    "systemd-logind.service"
    "autovt@tty1.service"
    "user-sessions-early.service"
  ];
  systemd.services.user-sessions-early = {
    description = "Permit user logins early (without waiting for network.target)";
    # 上流 systemd-user-sessions から network.target / remote-fs.target だけ抜いた順序
    after = [
      "home.mount"
      "nss-user-lookup.target"
      "systemd-tmpfiles-setup.service"
    ];
    before = [ "display-manager.service" ];
    wantedBy = [ "display-manager.service" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.systemd.package}/lib/systemd/systemd-user-sessions start";
    };
  };

  services = {
    displayManager.gdm.enable = true;
    # GVfs を起動して Nautilus で smb:// (SMB) を扱えるようにする
    gvfs.enable = true;
    gnome.gnome-keyring.enable = true;
    # gnome-keyring が gcr-ssh-agent を既定で有効化するが、
    # programs.ssh.startAgent と同時有効化できないため無効化
    gnome.gcr-ssh-agent.enable = false;
  };

  # GDM グリーターの背景画像。gdm-bg.nix が gnome-shell の
  # gnome-shell-theme.gresource を再パッケージして #lockDialogGroup に画像を敷く。
  # pkgs.gnome-shell を差し替え対象にするので、GDM モジュール内の参照も一緒に変わる。
  nixpkgs.overlays = [
    (final: prev: {
      gnome-shell = final.callPackage ../hosts/spring-t14-gen6/gdm-bg.nix {
        gnome-shell = prev.gnome-shell;
        boot-wallpaper = ../hosts/spring-t14-gen6/assets/boot-wallpaper.png;
      };
    })
  ];
}
