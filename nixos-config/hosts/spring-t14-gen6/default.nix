# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
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
  boot.loader.timeout = 2;
  # SSD の TRIM を週次で実行 (timer のみで boot 時のコストは無い)。
  # 長期的な書き込み性能の劣化を防ぐ。
  services.fstrim.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

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

  hardware.bluetooth.enable = true;

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
