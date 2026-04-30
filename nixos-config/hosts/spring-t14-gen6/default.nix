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
    ../../modules/steam.nix
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
  boot.kernelPackages = pkgs.linuxPackages_7_0;

  networking.hostName = "spring-t14-gen6"; # Define your hostname.
  networking.networkmanager.enable = true;

  system.stateVersion = "26.05"; # Did you read the comment?
}
