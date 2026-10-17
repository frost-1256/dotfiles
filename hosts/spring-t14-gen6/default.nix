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
    ../../modules/tailscale.nix
    ../../modules/smb.nix
    ./hardware-configuration.nix
  ];

  # Bootloader: Limine (wallpaper 付き TUI)。壁紙は ~/Pictures の VRChat スクショ
  # (2026-10-16 時点) を assets/boot-wallpaper.png にコピーしたもの。
  boot.loader.limine = {
    enable = true;
    style.wallpapers = [ ./assets/boot-wallpaper.png ];
    style.wallpaperStyle = "stretched"; # 1920x1080 ネイティブ解像度なので stretch で OK
  };
  # ブートメニュー待ちを短縮 (loader 5.7秒 → 約2秒。世代選択時は起動時に Space 長押し)。
  boot.loader.timeout = 1;
  # SSD の TRIM を週次で実行 (timer のみで boot 時のコストは無い)。
  # 長期的な書き込み性能の劣化を防ぐ。
  services.fstrim.enable = true;
  # CachyOS kernel (chaotic-nyx の既定バリアント = 上流 parity の LTO+BORE)。
  # nyx-cache でバイナリが降ってくるので Hydra のビルド状況は気にしなくて良い。
  boot.kernelPackages = pkgs.linuxPackages_cachyos;
  # PSR2 を使う (Panel Replay は明示無効)。復帰直後のデスクトップ透け対策の
  # 切り分けとして、パネル側フレーム保持 (Replay) を外して PSR2 に寄せる。
  # 新しめのカーネルでは VRR との共存に対応しているので Niri 側の VRR は残す。
  # 確認: sudo cat /sys/kernel/debug/dri/0/eDP-1/i915_psr_status
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  # nixbuild.net リモートビルダー (aarch64 カーネル/イメージ用)。
  # 公開鍵 (~/.ssh/id_ed25519.pub) を https://nixbuild.net/settings/ssh-keys に登録すること。
  programs.ssh.extraConfig = ''
    Host eu.nixbuild.net
      ServerAliveInterval 60
      IdentityFile /home/spring/.ssh/id_ed25519
  '';
  programs.ssh.knownHosts.nixbuild = {
    hostNames = [ "eu.nixbuild.net" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
  };
  nix = {
    distributedBuilds = true;
    settings.builders-use-substitutes = true;
    buildMachines = [
      {
        hostName = "eu.nixbuild.net";
        system = "aarch64-linux";
        maxJobs = 100;
        supportedFeatures = [
          "benchmark"
          "big-parallel"
        ];
      }
    ];
  };
  boot.kernelParams = [
    "xe.enable_psr=2"
    "xe.enable_panel_replay=0"
    # バッテリ運転時の低消費電力チューニング (performance を落とさない範囲のみ)。
    # - iwlmvm.power_scheme=3 (low power): 無線のアイドル消費を下げる。
    #   スループット影響は大容量転送時の末尾に出るだけでデスクトップ用途では無縁。
    # - nmi_watchdog=0: アイドル時にパッケージ C-state が深く入るのを阻害する
    #   要因の一つを除去 (障害時の NMI レポートは失われる)。
    "iwlmvm.power_scheme=3"
    "nmi_watchdog=0"
  ];

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
  # `login` では顔を pam_unix の後に回す。空 submit → unix が即失敗 →
  # 顔 → パスワード不要で解除。パスワード入力済み → unix が即成功し
  # 顔を待たない (顔→unix の順だと入力後も顔の最大5秒待ちが発生する)。
  # GDM の顔ログインは gdm-face 経由なので影響なし。sudo/su は顔優先の
  # まま (端末では空 submit の流れが無いため)。
  security.pam.services.login.gaze.order =
    config.security.pam.services.login.rules.auth.unix.order + 10;
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
      # ThinkPad の充電しきい値 (下の charge-thresholds service と同じ目的。
      # こちらは reboot 時に tmpfiles が、rebuild 直後は service が担当する)。
      "w /sys/class/power_supply/BAT0/charge_start_threshold - - - - 75"
      "w /sys/class/power_supply/BAT0/charge_stop_threshold - - - - 80"
    ];

  # バッテリ運転時の低消費電力チューニング (performance を落とさない範囲のみ)。
  # - dirty_writeback_centisecs=1500: 5秒→15秒。書き込みをまとめて 1 回にし、
  #   ディスク起動回数を減らす (停電・突然のリセット時の喪失幅は最大15秒に伸びる)。
  # - USB autosuspend は既定値のままで十分 (usbcore.autosuspend=2 が既に適用)。
  # - iwlmvm.power_scheme は上の boot.kernelParams で設定 (モジュールパラメータ)。

  boot.kernel.sysctl = {
    "vm.dirty_writeback_centisecs" = 1500;
  };

  # 充電しきい値 (ThinkPad 標準の charge threshold sysfs)。
  # 開始 75% / 停止 80% で Li-ion の劣化要因である高 SOC 保持を避ける。
  # nixpkgs に専用オプションは無いため tmpfiles (再起動時) + systemd service
  # (reboot 無しの反映・冪等) で書く。一時的に満充電したい時は:
  #   echo 100 | sudo tee /sys/class/power_supply/BAT0/charge_stop_threshold
  #   echo 60 | sudo tee /sys/class/power_supply/BAT0/charge_start_threshold
  systemd.services.charge-thresholds = {
    description = "Apply ThinkPad battery charge thresholds";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScriptBin "charge-thresholds" ''
        t=/sys/class/power_supply/BAT0/charge_start_threshold
        s=/sys/class/power_supply/BAT0/charge_stop_threshold
        [ "$(cat "$t")" = 75 ] || echo 75 > "$t"
        [ "$(cat "$s")" = 80 ] || echo 80 > "$s"
      ''}/bin/charge-thresholds";
    };
  };

  system.stateVersion = "26.11"; # Did you read the comment?
}
