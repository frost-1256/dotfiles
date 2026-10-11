# aarch64 NixOS LXC コンテナ用ホスト (hosts/lxc-aarch64)。
# 投入先は Droidspaces (Android 上の LXC ランタイム)。
# 手順: https://www.droidspaces.org/docs/nix-nixos.html
#
# 既存ホスト (spring-t14-gen6) とは独立した最小構成。
# デスクトップ系モジュール (fprintd / pipewire / fwupd 等を含む
# modules/system.nix) はコンテナに不要なため import しない。
# ネットワーク・firewall・journald 等のコンテナ調整は
# droidspaces.nixosModules.working-droidspaces-rootfs-minimal
# (flake.nix 側で import) に任せ、ここでは競合する値を書かない。
# LXC 固有の調整が必要になったらこのファイルに足す。
#
# ビルド (tarball を Droidspaces に食わせる):
#   nix build .#lxc-aarch64.config.system.build.tarball
# 注意: 端末のカーネルが 5.4 以下の場合、systemd v260 以降は起動しない。
# その時は公式の minimal-with-systemd-v259 tarball を使うか相談すること。
{
  lib,
  pkgs,
  username,
  ...
}:
{
  # lxc-container.nix (droidspaces モジュール経由) も同じ値を書くが、
  # 単独 eval 時の意図明示のため残す (同値の二重定義はマージされる)。
  boot.isContainer = true;

  networking.hostName = "lxc-aarch64";
  # firewall は droidspaces モジュール側で無効化される
  # (Android カーネルに nftables が無いため iptables-legacy 前提)。
  # ここでは触らない。

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  # allowUnfree 等は全ホスト共通ファイルから (modules/system.nix と同一)。
  nixpkgs.config = import ../../nixpkgs-config.nix;

  time.timeZone = "Asia/Tokyo";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ja_JP.UTF-8";
    LC_IDENTIFICATION = "ja_JP.UTF-8";
    LC_MEASUREMENT = "ja_JP.UTF-8";
    LC_MONETARY = "ja_JP.UTF-8";
    LC_NAME = "ja_JP.UTF-8";
    LC_NUMERIC = "ja_JP.UTF-8";
    LC_PAPER = "ja_JP.UTF-8";
    LC_TELEPHONE = "ja_JP.UTF-8";
    LC_TIME = "ja_JP.UTF-8";
  };

  nix.settings = {
    auto-optimise-store = true;
    builders-use-substitutes = true;
    # experimental-features (nix-command / flakes) は
    # droidspaces モジュール側が設定するので書かない (二重定義防止)。
  };

  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 7d";
  };

  # HTML マニュアルと nixos-help を落とす (modules/system.nix と同一の削減)。
  documentation.doc.enable = false;

  environment.defaultPackages = with pkgs; [
    rsync
    strace
  ];

  environment.systemPackages = with pkgs; [
    curl
    git
    htop
    vim
    wget
  ];

  users.users.${username} = {
    isNormalUser = true;
    description = username;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
    # 初回はパスワード無し (コンソールから passwd で設定するか、
    # 下の openssh.authorizedKeys.keys に鍵を登録すること)。
    # openssh.authorizedKeys.keys = [ "ssh-ed25519 ..." ];
  };
  # パスワード未設定のまま sudo を使えるようにする
  # (コンソールに入れる時点で root 同等なのでコンテナ内では許容)。
  security.sudo.wheelNeedsPassword = false;

  # ユーザーシェルは zsh。/etc/zshrc 側の compinit は無効化し、
  # home/shell/default.nix の completionInit に一本化する
  # (modules/system.nix と同一理由)。
  programs.zsh.enable = true;
  programs.zsh.enableGlobalCompInit = false;

  # NAT モードで外から入る場合は Droidspaces 側で --port 22:22 を振ること。
  # 鍵認証に切り替えたら PasswordAuthentication は false にする。
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
    };
  };

  # droidspaces モジュールは 26.05 を書くが、このリポジトリの標準 (system/home)
  # に合わせて 26.11 に上げる (stateVersion は互換ゲートのみで強制上書きして良い)。
  system.stateVersion = lib.mkForce "26.11";
}
