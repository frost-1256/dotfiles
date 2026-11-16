# spring-desktop (GTX 1080 単GPU デスクトップ)。共通部分は modules/system.nix。
{ config, ... }:
{
  imports = [
    ../../modules/system.nix
    ../../modules/gnome.nix
    ../../modules/niri.nix
    ../../modules/podman.nix
    ../../modules/steam.nix
    ../../modules/tailscale.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "spring-desktop";

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    systemd-boot.enable = true;
  };

  # simpledrm (platform-simple-framebuffer) の無効化。
  # このマシンは GTX 1080 単GPUなのに simplefb が card0 として残り、
  # nvidia が card1 になる二重DRM構成になる。GDM (Mutter) は boot_vga を
  # 選ぶので無事だが、Niri が無出力側 (card0) に張り付いて真っ暗になる。
  # コンソールは nvidia-drm fbdev (=1、modprobe で有効) が担うので問題ない。
  # 組み込み・モジュールのどちらの simpledrm にも効くよう両方書く。
  boot.kernelParams = [
    "initcall_blacklist=simpledrm_platform_driver_init"
    # zswap 明示有効化 (backing は /swap/swapfile。CachyOS 既定も enabled だが宣言的に)。
    # shrinker はメモリ逼迫時の回収をカーネルに任せる (6.10+ の推奨)。
    "zswap.enabled=1"
    "zswap.compressor=zstd"
    "zswap.max_pool_percent=20"
    "zswap.shrinker_enabled=1"
  ];
  boot.blacklistedKernelModules = [ "simpledrm" ];

  # zram から zswap + disk swapfile へ切り替え。
  # zswap は backing swap デバイスへの書き込み前段キャッシュなので、受け皿の
  # disk swap が無いと働かない。zram との併用は二重圧縮になるため外す。
  zramSwap.enable = false;

  # zswap の受け皿。btrfs 上なので /swap を別 subvolume に切り、
  # 中の swapfile は `btrfs filesystem mkswapfile` で作成する (nocow + prealloc)。
  swapDevices = [ { device = "/swap/swapfile"; } ];

  # mesa-git はこのホストでは無効化する。有効化すると hardware.graphics 一式を
  # mkForce で上書きするため、nvidia モジュールの GL/EGL/GBM 配線まで消えて
  # /run/opengl-driver が Mesa のみになり、Niri が renderer を作れず無出力で
  # 真っ黒になる (2026-10-12 実測: driver (null) → no allocator)。
  # 最新 Mesa が要るのは Lunar Lake 機 (t14) だけで、GTX 1080 機は不要。
  chaotic.mesa-git.enable = false;

  # NVIDIA GTX 1080 (Pascal) 用ドライバ設定。
  # Pascal は最新ブランチ非対応のため legacy_580 を使う。
  # open モジュールは Turing 以降専用のため使わない。
  # GL/EGL/GBM は hardware.nvidia モジュールが hardware.graphics.extraPackages へ
  # 自動配線する (xserver 不要)。modesetting.enable が nvidia-drm.modeset=1 と fbdev=1 を有効化する。
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = false;
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };

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

  system.stateVersion = "26.11"; # Did you read the comment?
}
