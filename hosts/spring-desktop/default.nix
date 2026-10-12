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

  imports = [
    ../../modules/system.nix
    ../../modules/gnome.nix
    ../../modules/niri.nix
    ../../modules/podman.nix
    ../../modules/steam.nix
    ../../modules/unity.nix
    ../../modules/tailscale.nix
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
  # simpledrm (platform-simple-framebuffer) の無効化。
  # このマシンは GTX 1080 単GPUなのに simplefb が card0 として残り、
  # nvidia が card1 になる二重DRM構成になる。GDM (Mutter) は boot_vga を
  # 選ぶので無事だが、Niri が無出力側 (card0) に張り付いて真っ暗になる。
  # コンソールは nvidia-drm fbdev (=1、modprobe で有効) が担うので問題ない。
  # 組み込み・モジュールのどちらの simpledrm にも効くよう両方書く。
  boot.kernelParams = [
    "initcall_blacklist=simpledrm_platform_driver_init"
  ];
  boot.blacklistedKernelModules = [ "simpledrm" ];

  # フタ(Lid)の処理は Hyprland(bindl → lid-action)に一本化する。
  # logind 側で suspend してしまうと lid-toggle が効かないため ignore にする。
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  networking.hostName = "spring-desktop"; # Define your hostname.
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

  # NVIDIA GTX 1080 (Pascal) 用ドライバ設定。
  # Pascal は最新ブランチ非対応のため legacy_580 を使う。
  # open モジュールは Turing 以降専用のため使わない。
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = false;
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };

  # Wayland (Niri) 前提の追加設定。
  # modesetting.enable が nvidia-drm.modeset=1 と fbdev=1 を有効化する。
  # Niri 用の VRAM 解放プロファイル (上流 wiki の推奨値)。
  environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json".text =
    builtins.toJSON {
      rules = [
        {
          pattern = {
            feature = "procname";
            matches = "niri";
          };
          profile = "Limit Free Buffer Pool On Wayland Compositors";
        }
      ];
      profiles = [
        {
          name = "Limit Free Buffer Pool On Wayland Compositors";
          settings = [
            {
              key = "GLVidHeapReuseRatio";
              value = 0;
            }
          ];
        }
      ];
    };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [

    ];
  };

  programs.gpu-screen-recorder = {
    enable = true;
    ui.enable = true;
  };

  system.stateVersion = "26.11"; # Did you read the comment?
}
