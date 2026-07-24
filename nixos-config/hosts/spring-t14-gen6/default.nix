# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/system.nix
    ../../modules/perf-mode.nix
    ../../modules/gnome.nix
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

  system.stateVersion = "26.11"; # Did you read the comment?
}
