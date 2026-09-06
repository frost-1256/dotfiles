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

  nix.settings = {
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
