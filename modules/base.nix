# 全ホスト共通の最小基盤 (デスクトップ 2 台 + lxc-aarch64)。
# デスクトップ固有のものは modules/system.nix、コンテナ固有は hosts/lxc-aarch64 に置く。
{
  pkgs,
  lib,
  username,
  ...
}:
{
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    shell = pkgs.zsh;
  };
  # ユーザーシェルは zsh。home-manager 側で zsh を管理しても、NixOS 側でシェルを許可する必要がある。
  programs.zsh.enable = true;
  # /etc/zshrc は無条件に `autoload -U compinit && compinit`（-C なし）を実行するため、
  # 起動ごとに ~0.4 秒かかる。compinit は home/shell/default.nix の completionInit が
  # 唯一の呼び出し元になるよう、システム側は無効化する。
  programs.zsh.enableGlobalCompInit = false;

  # allowUnfree / permittedInsecurePackages は nixpkgs-config.nix で一元管理
  # (flake.nix の mkPkgs と同一設定を共有)。
  nixpkgs.config = import ../nixpkgs-config.nix;

  nix.settings = {
    # store 内の同一ファイルを hardlink で重複排除する (btrfs に自動 dedup は無い)。
    auto-optimise-store = true;
    # リモートビルダ使用時も binary cache を優先させる。
    builders-use-substitutes = true;
  };

  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 7d";
  };

  # --- closure を軽くする削減 ---
  # HTML マニュアル (nixos-manual-html, 約 29MiB) と nixos-help を落とす。
  # man configuration.nix(5) は documentation.man 側なので残る。
  documentation.doc.enable = false;
  # 既定の perl / rsync / strace のうち perl を外す (closure が一番重い)。
  environment.defaultPackages = with pkgs; [
    rsync
    strace
  ];
  # 注意: system.disableInstallerTools は使わない。nixos-install /
  # nixos-generate-config / nixos-option だけでなく nixos-rebuild(-ng) 本体も
  # system path から消えるため、rebuild の主経路 (sudo nixos-rebuild switch) が死ぬ。

  time.timeZone = "Asia/Tokyo";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = lib.genAttrs [
    "LC_ADDRESS"
    "LC_IDENTIFICATION"
    "LC_MEASUREMENT"
    "LC_MONETARY"
    "LC_NAME"
    "LC_NUMERIC"
    "LC_PAPER"
    "LC_TELEPHONE"
    "LC_TIME"
  ] (_: "ja_JP.UTF-8");
}
