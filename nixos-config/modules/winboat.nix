# Winboat: Linux 上で Windows アプリをシームレスに動かす(dockur/windows + FreeRDP)。
# winboat パッケージ自体が freerdp / docker-compose を PATH に内蔵しているため、
# ホスト側では Docker デーモンと KVM へのアクセスだけ用意すればよい。
{
  pkgs,
  username,
  ...
}: {
  # Windows コンテナを動かす Docker デーモン本体。
  virtualisation.docker.enable = true;

  # winboat は docker compose と /dev/kvm を使う。
  # docker: ソケットへ非 root でアクセス, kvm: 仮想化デバイスへアクセス。
  users.users.${username}.extraGroups = ["docker" "kvm"];

  # KVM(Intel) を明示的に有効化(既定でロードされるが宣言的に固定)。
  boot.kernelModules = ["kvm-intel"];

  environment.systemPackages = [pkgs.winboat];
}
