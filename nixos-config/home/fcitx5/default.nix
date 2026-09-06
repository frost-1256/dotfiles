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
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      qt6Packages.fcitx5-configtool
    ];
  };

  # スリープ復帰系の対処:
  # - 復帰後 fcitx5 内の hazkey-server コネクタは再接続に失敗して入力が死ぶため、
  #   niri の lid-open フックで hazkey-server と一緒に fcitx5 も再起動する
  # - fcitx5 本体が復帰時にクラッシュした場合の保険として Restart=always
  # - hazkey-server は GPU 再生成中数回クラッシュしうるので、起動回数制限を外し
  #   RestartSec を稼がせて自動復帰させる
  systemd.user.services.fcitx5-daemon = {
    Unit.After = [ "hazkey-server.service" ];
    Service.Restart = "always";
    Service.RestartSec = 2;
  };
  systemd.user.services.hazkey-server = {
    Unit.StartLimitBurst = 0;
    Service.RestartSec = 2;
  };
}
