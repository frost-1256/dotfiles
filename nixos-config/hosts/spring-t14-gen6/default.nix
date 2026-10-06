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

  # Face or Fingerprint の OR 構成:
  # - ロック画面: Noctalia が指紋を D-Bus で常時待ち受け (指を置けば即解除)、
  #   Enter → PAM で顔 → パスワード。PAM 側の fprintd は外す
  #   (Noctalia が reader を握る設計で二重に要らない。外さないと Enter 後に
  #   「指を置け」と二度聞かれる)。
  # - sudo/su/polkit-1: PAM 内で顔 (最大12秒) → 指紋 → パスワードの順。
  #   前に座っていれば顔で即通る。
  # 注意: `login` から fprintd を外すと GDM・TTY ログインの指紋は消える
  # (顔・パスワードは残る)。戻す時はこの 1 行を消す。
  security.pam.services.login.fprintAuth = false;
  services.gaze = {
    enable = true;
    gui.enable = true;
    pam.defaultServices = [
      "sudo"
      "polkit-1"
      "login"
      "su"
    ];
    # keyring 受け渡しは gdm-face サービス経由でしか起きない (pam_gaze の仕様)。
    # GDM の greeter は GNOME Shell なので Niri でも extension 方式が使える。
    # enableForUsers=false で Niri 側ユーザセッションの dconf には触らない。
    gnome = {
      enable = true;
      enableForUsers = false;
      gdmFaceLogin = true;
    };
    settings = {
      # TPM で顔テンプレートを暗号化 (要 TPM 2.0。/dev/tpmrm0 あり)。
      storage.encrypt_templates = true;
      # GDM 顔ログイン後の GNOME Keyring 自動アンロック
      # (要 encrypt_templates + liveness。登録は `gaze keyring`)。
      storage.unlock_gnome_keyring = true;
      # 上の前提条件。既定 true だが明示する。
      liveness.enabled = true;
      # ハイブリッド判定は "or" (RGB・IR のどちらか通れば OK)。
      # 既定は両方必須 (RGB 暗所時のみ IR に委譲) だが、この個体の IR は
      # emitter 未制御で明暗が安定しないため、厳格側に倒すと誤拒否が増える。
      security.hybrid_policy = "or";
      # IR カメラ (Chicony 04f2:b840)。ランタイム側で PipeWire target に
      # 解決されていたのでその値を採用 (/dev/video2 指定からの変更)。
      # emitter は LED が自動点灯しない時だけ true にする
      # (b840 は上流 ir-profiles 未収録。doctor の報告で判断)。
      cameras.ir = "pipewiresrc target-object=v4l2_input.pci-0000_00_14.0-usb-0_4_1.2";
      # RGB・IR 同時キャプチャは "never" (逐次) に固定。
      # "auto" だと単一 UVC 機器なのに並列と誤判定してストリームが壊れ、
      # 検出が間欠的に空振りする (上流 troubleshooting の既知事項)。
      cameras.parallel_capture = "never";
      # 推論は Lunar Lake NPU。/usr/lib/gaze/runtimes/openvino/ 以下
      # (下の tmpfiles で用意) に vendor ORT + library-path が要る。
      # 検出空振りの真因は並列キャプチャ側だったため NPU に戻す。
      # 初期化失敗時は daemon が CPU にフォールバックする。
      inference.execution_provider = "auto";
      inference.device = "npu";
    };
  };

  # Gaze NPU ランタイム登録 (`/usr/lib` は不変なので tmpfiles で symlink)。
  # daemon は library-path を読んで LD_LIBRARY_PATH 付きで自己 re-exec し、
  # libonnxruntime.so を dlopen する。nixpkgs の onnxruntime は OpenVINO EP
  # 付き (libonnxruntime_providers_openvino.so 同梱) のため vendor ビルド不要。
  # /dev/accel/accel0 は world RW のため gazed の到達性に問題なし。
  systemd.tmpfiles.rules =
    let
      sdkLibDirs = [
        "${pkgs.onnxruntime}/lib"
        "${pkgs.openvino.lib}/lib"
        "${pkgs.intel-npu-driver}/lib"
        "${pkgs.level-zero}/lib"
      ];
    in
    [
      "d /usr/lib/gaze/runtimes/openvino 0755 root root -"
      "L+ /usr/lib/gaze/runtimes/openvino/libonnxruntime.so - - - - ${pkgs.onnxruntime}/lib/libonnxruntime.so.1"
      # EP の解決は vendor lib と同ディレクトリから行われるため providers も置く。
      "L+ /usr/lib/gaze/runtimes/openvino/libonnxruntime_providers_openvino.so - - - - ${pkgs.onnxruntime}/lib/libonnxruntime_providers_openvino.so"
      "L+ /usr/lib/gaze/runtimes/openvino/libonnxruntime_providers_shared.so - - - - ${pkgs.onnxruntime}/lib/libonnxruntime_providers_shared.so"
      "L+ /usr/lib/gaze/runtimes/openvino/library-path - - - - ${pkgs.writeText "gaze-openvino-library-path" (builtins.concatStringsSep ":" sdkLibDirs)}"
    ];

  system.stateVersion = "26.11"; # Did you read the comment?
}
