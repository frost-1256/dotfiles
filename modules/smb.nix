{ pkgs, ... }:
{
  # SMB クライアント支援。
  # - cifs-utils : mount.cifs によるマウント
  # - smb:// URL (Nautilus 等) は modules/gnome.nix の GVfs で既に扱える
  # smbclient (pkgs.samba、約 90MB) は使わないため外した (2026-11-15)。
  # CLI で共有一覧/転送したくなったら `nix shell nixpkgs#samba` で一時的に使う
  # cifs モジュールは mount.cifs 時にカーネルが自動ロードするので boot.kernelModules に入れない。
  # 入れると systemd-modules-load (sysinit.target の前) で毎起動 約0.5秒かかっていた (2026-11-15)

  environment.systemPackages = with pkgs; [
    cifs-utils
  ];
}
