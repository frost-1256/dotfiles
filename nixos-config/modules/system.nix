{
  pkgs,
  lib,
  username,
  ...
}: let
  ubuntuHostAddress = "10.203.0.1";
  ubuntuContainerAddress = "10.203.0.2";
  ubuntuPrefixLength = 24;

  ubuntuNspawnConfigureNetwork = pkgs.writeShellScriptBin "ubuntu-nspawn-configure-network" ''
    set -euo pipefail

    target="''${1:-/var/lib/machines/ubuntu}"
    systemd_unit_dir=""

    if [ "$(id -u)" -ne 0 ]; then
      echo "run as root: sudo ubuntu-nspawn-configure-network [target]" >&2
      exit 1
    fi

    if [ ! -d "$target" ]; then
      echo "container rootfs not found at $target" >&2
      exit 1
    fi

    if [ -d "$target/usr/lib/systemd/system" ]; then
      systemd_unit_dir="/usr/lib/systemd/system"
    elif [ -d "$target/lib/systemd/system" ]; then
      systemd_unit_dir="/lib/systemd/system"
    else
      echo "systemd unit directory not found in $target" >&2
      exit 1
    fi

    mkdir -p \
      "$target/etc/systemd/network" \
      "$target/etc/systemd/system/multi-user.target.wants"

    cat > "$target/etc/systemd/network/20-host0.network" <<EOF
[Match]
Name=host0

[Network]
Address=${ubuntuContainerAddress}/${toString ubuntuPrefixLength}
Gateway=${ubuntuHostAddress}
DNS=1.1.1.1
DNS=8.8.8.8
EOF

    ln -sf \
      "$systemd_unit_dir/systemd-networkd.service" \
      "$target/etc/systemd/system/multi-user.target.wants/systemd-networkd.service"
  '';

  ubuntuNspawnBootstrap = pkgs.writeShellScriptBin "ubuntu-nspawn-bootstrap" ''
    set -euo pipefail

    release="''${1:-noble}"
    target="''${2:-/var/lib/machines/ubuntu}"
    mirror="''${3:-http://archive.ubuntu.com/ubuntu}"

    if [ "$(id -u)" -ne 0 ]; then
      echo "run as root: sudo ubuntu-nspawn-bootstrap [release] [target] [mirror]" >&2
      exit 1
    fi

    mkdir -p "$(dirname "$target")"

    if [ -e "$target/etc/os-release" ]; then
      echo "container rootfs already exists at $target" >&2
      exit 0
    fi

    ${pkgs.debootstrap}/bin/debootstrap \
      --arch=amd64 \
      --include=systemd,dbus,iproute2,iputils-ping,curl,wget,sudo,ca-certificates,vim \
      "$release" \
      "$target" \
      "$mirror"

    ${ubuntuNspawnConfigureNetwork}/bin/ubuntu-nspawn-configure-network "$target"
  '';
in {
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = ["networkmanager" "wheel" "docker" "input"];
  };

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
  };

  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 7d";
  };

  nixpkgs.config.allowUnfree = true;

  boot.enableContainers = true;

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
      nerd-fonts.symbols-only 
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.hack
    ];
    fontconfig.defaultFonts = {
      serif = ["Noto Serif" "Noto Color Emoji"];
      sansSerif = ["Noto Sans" "Noto Color Emoji"];
      monospace = ["JetBrainsMono Nerd Font" "Noto Color Emoji"];
      emoji = ["Noto Color Emoji"];
    };
  };
  programs.dconf.enable = true;
  networking.firewall.enable = true;
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-ubuntu" ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    curl
    git
    gnome-keyring
    debootstrap
    systemd
    ubuntuNspawnConfigureNetwork
    ubuntuNspawnBootstrap
  ];

  systemd.tmpfiles.rules = [
    "d /var/lib/machines 0755 root root -"
  ];

  environment.etc."systemd/nspawn/ubuntu.nspawn".text = ''
    [Exec]
    Boot=yes
    PrivateUsers=pick
    ResolvConf=auto

    [Network]
    VirtualEthernet=yes
  '';

  systemd.services."systemd-nspawn@".serviceConfig = {
    ExecStartPre = [
      "-${pkgs.systemd}/bin/machinectl terminate %i"
      "-${pkgs.systemd}/bin/systemd-nspawn --cleanup --machine=%i"
      "-${pkgs.iproute2}/bin/ip link delete ve-%i"
      "-${pkgs.iproute2}/bin/ip link delete vb-%i"
    ];
    ExecStartPost = [
      "${pkgs.iproute2}/bin/ip link set ve-%i up"
      "${pkgs.iproute2}/bin/ip addr replace ${ubuntuHostAddress}/${toString ubuntuPrefixLength} dev ve-%i"
    ];
  };

  services.pulseaudio.enable = false;

  security.polkit.enable = true;
  services.fprintd.enable = true;

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
}
