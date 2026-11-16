# spring-b550m-pro4 (ASRock B550M Pro4 / Ryzen 5 5600X / DDR4-3800 32GB / RTX 3080 10GB の単GPUデスクトップ)。
# 共通部分は modules/system.nix。方針は「省電力は捨てて性能とレイテンシ最優先」。
{
  config,
  inputs,
  pkgs,
  lib,
  username,
  ...
}:
let
  # CachyOS LTO カーネルを Zen 3 (x86-64-v3 = AVX2/BMI2/FMA) 向けに再ビルドする。
  # chaotic のプリセットは znver4 (AVX-512 を使うので 5600X では SIGILL) しか無いため、
  # cachyOverride で _processor_opt だけ GENERIC_V3 に差し替える。他の設定
  # (BORE+EEVDF / HZ=1000 / full preempt / hugepage=always) は既定のまま。
  # nyx-cache にバイナリが無いので初回はローカルで LTO ビルドになる (時間がかかる)。
  # NATIVE は「ビルドしたマシンの CPU」向けになり T14 から評価・ビルドすると壊れるので使わない。
  ltoVars = builtins.fromJSON (
    builtins.readFile "${inputs.chaotic}/pkgs/linux-cachyos/config-vars/cachyos-lto.json"
  );
  zen3Kernel = pkgs.linuxPackages_cachyos.cachyOverride {
    cachyVars = ltoVars // {
      _processor_opt = "GENERIC_V3";
    };
  };
in
{
  imports = [
    ../../modules/system.nix
    ../../modules/gnome.nix
    ../../modules/niri.nix
    ../../modules/podman.nix
    ../../modules/steam.nix
    ../../modules/tailscale.nix
    # VRChat (Quest + WiVRn) と Unity/ALCOM 制作環境 (nixos-vrchat input)
    ../../modules/vrchat.nix
    ../../modules/unity.nix
    # 普通の Linux 向けバイナリの直接実行 (nix-ld + envfs)
    ../../modules/nix-ld.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "spring-b550m-pro4";

  # fcitx5 の設定ディレクトリ (home/fcitx5 の i18n.inputMethod.fcitx5.settings が生成)。
  # HM 既定は ~/.config/fcitx5 を丸ごと store への symlink にするため fcitx5 が
  # 実行時に書く cached_layouts 等を書けず、終了時に config を書き戻すと symlink が
  # 実ファイルに化けて次の rebuild で clobber エラーになる。
  # - recursive: ディレクトリは実体のまま、宣言したファイル (config / profile / conf/*.conf)
  #   だけを個別にリンクする
  # - force: 書き戻されて実ファイルになったものも宣言値で上書きする
  home-manager.users.${username}.xdg.configFile.fcitx5 = {
    recursive = true;
    force = true;
  };

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
    # PCIe ASPM を性能優先に (リンク省電力の復帰遅延をなくす)
    "pcie_aspm.policy=performance"
    # Zen 3 は既定だと acpi-cpufreq/passive になりうる。active (CPPC + EPP) に固定して
    # governor=performance と合わせ、周波数遷移の遅れを最小化する。
    "amd_pstate=active"
    # zswap 明示有効化 (backing は /swap/swapfile。CachyOS 既定も enabled だが宣言的に)。
    # shrinker はメモリ逼迫時の回収をカーネルに任せる (6.10+ の推奨)。
    "zswap.enabled=1"
    "zswap.compressor=zstd"
    "zswap.max_pool_percent=20"
    "zswap.shrinker_enabled=1"
    # NMI watchdog の定期割り込みを止める (CachyOS-Settings と同じ)
    "nmi_watchdog=0"
  ];
  boot.blacklistedKernelModules = [
    "simpledrm"
    # ハードウェア watchdog (sp5100_tco は Ryzen のチップセット側)。CachyOS-Settings と同じ
    "sp5100_tco"
    "iTCO_wdt"
    "wdat_wdt"
  ];

  # 性能最優先 (省電力は無視。据え置きデスクトップなので電力は気にしない)。
  # - CPU governor を performance に固定 (AMD: amd-pstate は EPP も performance 側に寄る)。
  # - PCIe ASPM を performance にして、GPU / NVMe のリンク省電力による復帰遅延をなくす。
  # - nvidia-persistenced でドライバ常駐 (クライアント起動時の初期化遅延を消す)。
  # (pcie_aspm.policy=performance と amd_pstate=active は上の boot.kernelParams に入れている)
  powerManagement.cpuFreqGovernor = "performance";
  hardware.nvidia.nvidiaPersistenced = true;
  boot.kernelPackages = lib.mkForce zen3Kernel;

  # --- CachyOS-Settings 由来のチューニング (2026-11-16 時点の上流 9e6603a を読んで選別) ---
  # 採用しなかったもの: 71-nvidia.rules (GPU の runtime PM=auto。省電力側なので逆)、
  # NVreg_InitializeSystemMemoryAllocations=0 (GPU 用メモリのゼロ初期化を省く。
  # 他プロセスの残骸が読める情報漏えいリスクがあり効果も小さい)、zram 系 (zswap 構成のため)、
  # journald / timeout 系 (性能と無関係)。
  boot.kernel.sysctl = {
    # RAM 32GB で zswap の受け皿 (disk swap) は最終手段。匿名ページを粘って持つ
    # (CachyOS 既定の 100 は zram 前提の値)。
    "vm.swappiness" = 20;
    # zswap は 1 ページ単位で展開するので先読みしない (CachyOS も 0)。
    "vm.page-cluster" = 0;
    # dentry / inode キャッシュを捨てにくくする。
    "vm.vfs_cache_pressure" = 50;
    # dirty ページを溜め込みすぎず早めに書き出し、まとめ書きによる長い停止を防ぐ。
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 3;
    "net.core.netdev_max_backlog" = 4096;
    "fs.file-max" = 2097152;
    # コンソールへのカーネルメッセージを抑制。
    "kernel.printk" = "3 3 3 3";
    # 分岐の多いゲームで split lock 検出の強制ペナルティ (数 ms の停止) を避ける。
    "kernel.split_lock_mitigate" = 0;
  };
  # NMI watchdog / ハードウェア watchdog の停止は上の boot.kernelParams /
  # boot.blacklistedKernelModules に入れている。
  # NTSync (Wine/Proton の同期プリミティブをカーネルで処理。対応ゲームで CPU 負荷とスタッターが減る)。
  boot.kernelModules = [ "ntsync" ];
  # HDA の省電力オフ (復帰時のプチ音・遅延をなくす。CachyOS は AC 接続時に同じことをする)。
  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=0 power_save_controller=N
  '';
  # THP: defrag は defer+madvise (同期 compaction で止まらない)、ほぼ空の THP は分割して
  # always 運用のメモリ膨張を抑える (CachyOS カーネルは THP=always)。
  systemd.tmpfiles.rules = [
    "w! /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise"
    "w! /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none - - - - 409"
  ];
  services.udev.extraRules = ''
    # I/O スケジューラ (CachyOS と同じ割り当て): HDD=bfq / SATA SSD=mq-deadline / NVMe=kyber
    ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
    ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber"
    # SATA のリンク省電力 (ALPM) を切る
    ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_supported}=="1", ATTR{link_power_management_policy}="max_performance"
    # 遅いディスク (USB / removable / HDD) の dirty キャッシュ上限。コピーが一瞬で
    # 終わったように見えて sync / umount で長く固まるのを防ぐ
    ACTION=="add|change", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ATTR{removable}=="1", ATTR{bdi/strict_limit}="1", ATTR{bdi/max_bytes}="268435456"
    ACTION=="add|change", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{bdi/strict_limit}="1", ATTR{bdi/max_bytes}="268435456"
    ACTION=="add|change", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ENV{ID_BUS}=="usb", ATTR{bdi/strict_limit}="1", ATTR{bdi/max_bytes}="16777216"
  '';
  # PCI latency timer の調整 (サウンドカードを優先し音切れを防ぐ。CachyOS の pci-latency)。
  systemd.services.pci-latency = {
    description = "Adjust latency timers for PCI peripherals";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.pciutils}/bin/setpci -v -s '*:*' latency_timer=20
      ${pkgs.pciutils}/bin/setpci -v -s '0:0' latency_timer=0
      ${pkgs.pciutils}/bin/setpci -v -d '*:*:04xx' latency_timer=80
    '';
  };
  # ファイルディスクリプタ上限 (Wine/Proton の esync 等が大量に使う)。
  systemd.settings.Manager.DefaultLimitNOFILE = "2048:2097152";
  # sched-ext LAVD を Gaming モード (--performance) で起動。省電力寄りの判断をしない。
  services.scx-loader.config.default_mode = "Gaming";
  # ルート btrfs: atime 更新の書き込みをなくし、zstd:1 (最速レベル) で圧縮して I/O 量を減らす。
  fileSystems."/".options = [
    "noatime"
    "compress=zstd:1"
  ];

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

  # NVIDIA RTX 3080 (Ampere) 用ドライバ設定。
  # Ampere は最新ブランチ + open カーネルモジュール (Turing 以降対応) が使える。
  # open は新しいカーネル (CachyOS 7.x) への追従が軽く、suspend/resume も安定しやすい。
  # GL/EGL/GBM は hardware.nvidia モジュールが hardware.graphics.extraPackages へ
  # 自動配線する (xserver 不要)。modesetting.enable が nvidia-drm.modeset=1 と fbdev=1 を有効化する。
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
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
