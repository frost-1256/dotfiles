# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  disabledModules = [ "programs/wayland/noctalia.nix" ];

  # btrfs 圧縮 (新規書き込み分から適用)。store はテキスト比率が高く zstd で
  # 1.5〜2 倍程度の削減が見込める。noatime は書き込み量を減らす。
  # 既存データは GC / 再ビルドで順次置き換わる (/nix の defragment は
  # reflink を壊すので実行しない)。
  fileSystems."/nix".options = [
    "compress=zstd"
    "noatime"
  ];
  fileSystems."/home".options = [
    "compress=zstd"
    "noatime"
  ];

  imports = [
    ../../modules/system.nix
    ../../modules/perf-mode.nix
    ../../modules/gnome.nix
    ../../modules/niri.nix
    ../../modules/virtualisation.nix
    ../../modules/podman.nix
    ../../modules/steam.nix
    ../../modules/unity.nix
    ../../modules/tailscale.nix
    ../../modules/smb.nix
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot"; # ← use the same mount point here.
    };
    systemd-boot.enable = true;
  };
  # ブートメニュー待ちを短縮 (loader 5.7秒 → 約2秒。世代選択時は起動時に Space 長押し)。
  boot.loader.timeout = 1;
  # SSD の TRIM を週次で実行 (timer のみで boot 時のコストは無い)。
  # 長期的な書き込み性能の劣化を防ぐ。
  services.fstrim.enable = true;
  # CachyOS kernel (chaotic-nyx の既定バリアント = 上流 parity の LTO+BORE)。
  # nyx-cache でバイナリが降ってくるので Hydra のビルド状況は気にしなくて良い。
  boot.kernelPackages = pkgs.linuxPackages_cachyos;
  # Panel Replay を明示有効 (既定は per-chip auto)。LNL 世代の省電力機能で、
  # 対応パネルなら PSR より深く DC 側を落とせる。非対応パネルでは何も起きない。
  # 新しめのカーネルでは VRR との共存に対応しているので Niri 側の VRR は残す。
  # 確認: sudo cat /sys/kernel/debug/dri/0/eDP-1/i915_psr_status
  boot.kernelParams = [ "xe.enable_panel_replay=1" ];

  # フタ(Lid)の処理は Hyprland(bindl → lid-action)に一本化する。
  # logind 側で suspend してしまうと lid-toggle が効かないため ignore にする。
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  networking.hostName = "spring-t14-gen6"; # Define your hostname.
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false;

  # メモリ圧時の SSD スワップ代替。zstd 圧縮 RAM 上なので遅くなく、
  # アイドルページ退避で実効メモリが増える。ノートの体感・消費電力両得。
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  hardware.bluetooth.enable = true;

  # 最新 Mesa (Lunar Lake の Xe2 iGPU 向け)。無効化時のフォールバック用に
  # hardware.graphics 側の intel-media-driver 残しはそのままにする。
  chaotic.mesa-git = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
    ];
  };

  # sched-ext (CachyOS カーネルで利用可)。LAVD は応答性と省電力のバランス型で
  # ノート向け。EPP 側の調整 (perf-mode) とは併用できる。
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
  };

  # 負荷時のもたつき抑止。ルールは chaotic の CachyOS 由来を使う。
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos_git;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      intel-media-driver
    ];
  };

  programs.gpu-screen-recorder = {
    enable = true;
    ui.enable = true;
  };

  system.stateVersion = "26.11"; # Did you read the comment?
}
