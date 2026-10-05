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

  # Unbind fingerprint sensor from hid-multitouch so TOD driver can use it via hidraw
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="hid", DRIVER=="hid-multitouch", ATTRS{modalias}=="hid:b0018g0004v000004F3p00003195", RUN+="${pkgs.bash}/bin/sh -c 'echo $kernel > /sys/bus/hid/drivers/hid-multitouch/unbind'"
  '';

  # Firmware updates (LVFS) — daemon + GNOME Firmware GUI
  services.fwupd.enable = true;

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
