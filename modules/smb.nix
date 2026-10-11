{ pkgs, ... }:
{
  # SMB クライアント支援。
  # - smbclient : CLI から共有一覧/転送 (smbclient //host/share)
  #   ※ 旧 pkgs.smbclient は削除され pkgs.samba (multi-output) に統合済み
  # - cifs-utils : mount.cifs によるマウント
  # - smb:// URL (Nautilus 等) は modules/gnome.nix の GVfs で既に扱える
  boot.kernelModules = [ "cifs" ];

  environment.systemPackages = with pkgs; [
    samba
    cifs-utils
  ];
}
