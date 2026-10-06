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
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
    ];
  };
  # ユーザーシェルは zsh (旧 users/spring/nixos.nix から統合)。
  # home-manager 側で zsh を管理しても、NixOS 側でシェルを許可する必要がある。
  programs.zsh.enable = true;

  # /etc/zshrc は無条件に `autoload -U compinit && compinit`（-C なし）を実行するため、
  # 起動ごとに ~0.4 秒かかる。compinit は home/shell/default.nix の completionInit が
  # 唯一の呼び出し元になるよう、システム側は無効化する。
  programs.zsh.enableGlobalCompInit = false;

  nix.settings = {
    # store 内の同一ファイルを hardlink で重複排除する。
    # btrfs に自動 dedup は無く、現状 GC ログも
    # "note: hard linking is currently saving 0.0 KiB" になっている。
    auto-optimise-store = true;
    # 置換 (binary cache からの取得) を並列化して rebuild の DL 時間を短縮。
    # builders-use-substitutes はリモートビルダ時も cache を優先させる。
    builders-use-substitutes = true;
    http-connections = 50;
    max-substitution-jobs = 16;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [
      "https://cache.nixos.org/"
      "https://noctalia.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 7d";
  };

  # allowUnfree / permittedInsecurePackages は nixpkgs-config.nix で一元管理
  # (flake.nix の mkPkgs と同一設定を共有)。
  nixpkgs.config = import ../nixpkgs-config.nix;

  # --- rebuild / closure を軽くする削減 ---
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
  # system path から消えるため、rebuild の主経路 (sudo nixos-rebuild switch) が
  # 死ぬ。

  time.timeZone = "Asia/Tokyo";

  # Select internationalisation properties.
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

  fonts = {
    packages = with pkgs; [
      font-awesome
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      hackgen-font
      ipafont
      nerd-fonts.symbols-only
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
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
        "JetBrainsMono Nerd Font"
        "IPAGothic"
        "Noto Color Emoji"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
    fontconfig.localConf = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
      <fontconfig>
        <!-- Unity Editor: 同梱 Inter では日本語グリフが無いため、IPAGothic をフォールバックに挟む -->
        <match target="pattern">
          <test qual="any" name="family"><string>Inter</string></test>
          <edit name="family" mode="prepend" binding="strong"><string>IPAGothic</string></edit>
        </match>
        <match target="pattern">
          <test qual="any" name="family"><string>Liberation Sans</string></test>
          <edit name="family" mode="prepend" binding="strong"><string>IPAGothic</string></edit>
        </match>
      </fontconfig>
    '';
  };
  programs.dconf.enable = true;
  networking.firewall.enable = true;
  networking.firewall.allowedUDPPorts = [ 9999 ];
  services.resolved = {
    enable = true;

    settings = {
      Resolve = {
        DNS = [
          "45.90.28.0#982ac4.dns.nextdns.io"
          "2a07:a8c0::#982ac4.dns.nextdns.io"
          "45.90.30.0#982ac4.dns.nextdns.io"
          "2a07:a8c1::#982ac4.dns.nextdns.io"
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
    libimobiledevice
    ifuse
    gnome-firmware

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

  services.pulseaudio.enable = false;

  security.polkit.enable = true;
  security.pam.services.polkit-1.fprintAuth = true;

  services.fprintd = {
    enable = true;
    tod.enable = true;
    tod.driver = pkgs.libfprint-2-tod1-goodix;
  };
  # fprintd 自動復旧 (2026-10-06 実測)。
  # resume で USB デバイスが黙って切れ、fprintd は死んだ handle を握ったまま claim を保持する。
  # 以後 Claim は "Device was already claimed" で全滅し、さらに client の Release 時に
  # 「Error closing device after disconnect: transfer timed out」→ fprint_device_release で
  # SIGSEGV(core-dump)。SEGV 後の endpoint halt は fprintd の restart だけでは消えず
  # (Ignoring device ... endpoint stalled が出続ける)、USB の unbind/bind で再列挙させる
  # 必要がある。3 方向から同じ recover unit を叩く。
  systemd.services.fprintd.serviceConfig = {
    Restart = "on-failure";
    RestartSec = "2s";
  };
  systemd.services.fprintd-recover = {
    description = "Re-enumerate fingerprint sensor and restart fprintd";
    # ppd の EPP 書き戻しと同じく resume 直後はデバイスが落ち着いていないことがあるため、
    # suspend 系 target 群からは復帰後に active になるこちらのサービスで叩く
    # (power-tune-delayed と同じ pattern)。
    after = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    wantedBy = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "30s";
      ExecStart = "${pkgs.writeShellScript "fprintd-recover" ''
        set -u
        ctl=${pkgs.systemd}/bin/systemctl
        bus=${pkgs.systemd}/bin/busctl
        # fprintd が列挙している指紋デバイスの有無を見る。
        # stall 時は fprintd がデバイスを捨てるので空になる(empty = ao 0)。
        have_device() {
          out=$($bus --system call net.reactivated.Fprint /net/reactivated/Fprint/Manager \
            net.reactivated.Fprint.Manager GetDevices 2>/dev/null) || return 1
          case "$out" in
            *'ao 0'*) return 1 ;;
            *'/net/reactivated/Fprint/Device/'*) return 0 ;;
            *) return 1 ;;
          esac
        }
        $ctl restart fprintd.service
        # D-Bus activation 完了を最大 5 秒待つ (SEGV 直後の連打で起動中の場合に備える)。
        for _ in 1 2 3 4 5 6 7 8 9 10; do
          have_device && exit 0
          ${pkgs.coreutils}/bin/sleep 0.5
        done
        # デバイスが列挙されない = endpoint が halt している。
        # USB から外して挿し直す (実機検証済み: unbind で :1.0 消滅、bind で再列挙、
        # その後の fprintd-list 正常)。30 秒 idle で自死しないよう stop してから触る。
        found=0
        for d in /sys/bus/usb/devices/*; do
          [ -f "$d/idVendor" ] || continue
          [ "$(cat "$d/idVendor")" = 06cb ] || continue
          [ "$(cat "$d/idProduct")" = 00f9 ] || continue
          found=1
          dev=''${d##*/}
          echo "fprintd-recover: re-enumerating USB device $dev"
          $ctl stop fprintd.service
          echo "$dev" > /sys/bus/usb/drivers/usb/unbind
          ${pkgs.coreutils}/bin/sleep 1
          echo "$dev" > /sys/bus/usb/drivers/usb/bind
          ${pkgs.coreutils}/bin/sleep 1
          # udev の add rule が再適用されるはずだが、念のため明示的に常時給電へ。
          [ -w "$d/power/control" ] && echo on > "$d/power/control"
        done
        [ "$found" = 1 ] || { echo "fprintd-recover: sensor not found on USB"; exit 1; }
        $ctl start fprintd.service
        for _ in 1 2 3 4 5 6 7 8 9 10; do
          have_device && exit 0
          ${pkgs.coreutils}/bin/sleep 0.5
        done
        echo "fprintd-recover: device still missing after re-enumeration" >&2
        exit 1
      ''}";
    };
  };
  # ジャーナル監視: resume 契機以外 (起動中の自然切断 "device was disconnected" /
  # crash "code=dumped" / init 失敗 "Ignoring device") で死んだ handle・halt を検知。
  # guard 自体は passive (fprintd に触らない) で、復旧は recover に一本化する。
  systemd.services.fprintd-guard = {
    description = "Watch fprintd journal and trigger fprintd-recover on device loss";
    wantedBy = [ "multi-user.target" ];
    after = [ "fprintd.service" ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "5s";
      ExecStart = "${pkgs.writeShellScript "fprintd-guard" ''
        set -u
        delay=10
        ${pkgs.systemd}/bin/journalctl -f -n0 -o cat -u fprintd |
        while IFS= read -r line; do
          case "$line" in
            *'device was disconnected'*|*'transfer timed out'*|*'Ignoring device due to initialization error'*|*'code=dumped'*)
              if ${pkgs.systemd}/bin/systemctl start --wait fprintd-recover.service; then
                delay=10
              else
                delay=$((delay * 3)); [ "$delay" -gt 300 ] && delay=300
              fi
              ${pkgs.coreutils}/bin/sleep "$delay"
              ;;
          esac
        done
      ''}";
    };
  };

  # Unbind fingerprint sensor from hid-multitouch so TOD driver can use it via hidraw
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="hid", DRIVER=="hid-multitouch", ATTRS{modalias}=="hid:b0018g0004v000004F3p00003195", RUN+="${pkgs.bash}/bin/sh -c 'echo $kernel > /sys/bus/hid/drivers/hid-multitouch/unbind'"
    # 指紋センサ (Synaptics 06cb:00f9) の USB autosuspend を無効化。
    # resume 後に endpoint stalled で初期化失敗する一因になるため常時給電にする。
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="06cb", ATTR{idProduct}=="00f9", ATTR{power/control}="on"
  '';

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
