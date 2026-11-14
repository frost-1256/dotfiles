# デスクトップホスト (spring-t14-gen6 / spring-desktop) 共通のシステム設定。
# コンテナとも共有する最小部分は ./base.nix、ハードウェア固有は各 hosts/<host> に置く。
{
  pkgs,
  lib,
  username,
  ...
}:
{
  imports = [ ./base.nix ];

  # nixpkgs 内蔵の noctalia モジュールを無効化し、flake input 版
  # (flake.nix で noctalia.nixosModules.default を import) を使う。外さない。
  disabledModules = [ "programs/wayland/noctalia.nix" ];

  users.users.${username}.extraGroups = [
    "networkmanager"
    "wheel"
    "input"
  ];

  nix.settings = {
    # 置換 (binary cache からの取得) を並列化して rebuild の DL 時間を短縮。
    http-connections = 50;
    max-substitution-jobs = 16;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # cache.nixos.org と鍵は NixOS の既定値が提供するので書かない
    # (書くと既定と連結して重複するだけ。nyx / niri は各 flake モジュールが足す)。
    substituters = [
      "https://noctalia.cachix.org"
      "https://nixos-nothing-spacewar.cachix.org"
    ];
    trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "nixos-nothing-spacewar.cachix.org-1:TWmfQAaPB47M0zWUX6m2YgjKKu+WJYqwFtt9nR9pZDU="
    ];
    # nixConfig (extra-*) の信任確認と restricted 設定の上書きを許すユーザー。
    # 無いと flake 利用時に extra-substituters/extra-trusted-public-keys の
    # y/N プロンプトが毎回出て、trusted-public-keys は無視される。
    trusted-users = [ username ];
  };

  # --- ブート・カーネル ---
  # ブートメニュー待ちを短縮 (loader 5.7秒 → 約2秒。世代選択時は起動時に Space 長押し)。
  boot.loader.timeout = 1;
  # CachyOS kernel (chaotic-nyx の既定バリアント = 上流 parity の LTO+BORE)。
  # nyx-cache でバイナリが降ってくるので Hydra のビルド状況は気にしなくて良い。
  boot.kernelPackages = pkgs.linuxPackages_cachyos;
  # sched-ext (CachyOS カーネルで利用可)。LAVD は応答性と省電力のバランス型。
  # t14 の EPP 調整 (modules/perf-mode.nix) とは併用できる。
  services.scx-loader = {
    enable = true;
    config.default_sched = "scx_lavd";
  };
  # 負荷時のもたつき抑止。ルールは chaotic の CachyOS 由来を使う。
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos_git;
  };
  # SSD の TRIM を週次で実行 (timer のみで boot 時のコストは無い)。
  services.fstrim.enable = true;

  # --- ハードウェア共通 ---
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false;
  hardware.bluetooth.enable = true;
  # ドライバ側 (intel-media-driver / nvidia) は各ホストで足す。
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.gpu-screen-recorder = {
    enable = true;
    ui.enable = true;
  };

  fonts = {
    packages = with pkgs; [
      font-awesome
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      hackgen-nf-font
      ipafont
      nerd-fonts.symbols-only
      nerd-fonts.fira-code
      nerd-fonts.hack
    ];
    fontconfig.defaultFonts = {
      serif = [
        "Noto Serif"
        "IPAMincho"
        "Noto Color Emoji"
      ];
      sansSerif = [
        "Noto Sans"
        "IPAGothic"
        "Noto Color Emoji"
      ];
      monospace = [
        "HackGen Console NF"
        "IPAGothic"
        "Noto Color Emoji"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
  programs.dconf.enable = true;
  networking.firewall.enable = true;
  networking.enableIPv6 = false;
  # TCP 22 は modules/sshd.nix 側で開ける (t14 のみ)
  networking.firewall.allowedUDPPorts = [
    4242 # lan-mouse
  ];
  services.resolved = {
    enable = true;

    settings = {
      Resolve = {
        # IPv4 のみ (networking.enableIPv6 = false のため IPv6 サーバは書かない)
        DNS = [
          "45.90.28.0#982ac4.dns.nextdns.io"
          "45.90.30.0#982ac4.dns.nextdns.io"
        ];

        DNSOverTLS = true;
      };
    };
  };
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    # binary cache クライアント。nixos-nothing-spacewar への push と
    # 取得可否の確認 (cachix ls-store / cachix watch-store) に使う。
    cachix
    libimobiledevice
    ifuse
    gnome-firmware
    cloudflare-warp
    proton-vpn

    gst_all_1.gstreamer
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
  ];

  services.usbmuxd = {
    enable = true;
    package = pkgs.usbmuxd2;
  };
  services.cloudflare-warp.enable = true;

  services.pulseaudio.enable = false;

  # 画面読み上げ (speech-dispatcher + mbrola 音声で約 0.7GB)。
  # NixOS が graphical desktop 向けの既定 (mkDefault) で入れるが、
  # orca 不使用なら不要。無効化で closure から落ちる。
  services.speechd.enable = false;

  security.polkit.enable = true;
  # Firmware updates (LVFS) — daemon + GNOME Firmware GUI
  services.fwupd.enable = true;
  # fwupd の起動を display-manager より前に順序付けない (約6秒 GDM が待たされていた)。
  # fwupd は D-Bus activated でも動くため機能面の影響はない。
  systemd.services.fwupd.before = lib.mkForce [ ];
  # ジャーナル肥大化 (実測 3.9GB) を抑える。起動時の journal-flush と
  # /var/log/journal のディスク圧迫を軽減する。通常利用のデバッグには十分な量。
  services.journald.settings.Journal = {
    SystemMaxUse = "500M";
    RuntimeMaxUse = "100M";
  };

  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      jack.enable = true;
    };
  };

  programs.ssh.startAgent = true;
}
