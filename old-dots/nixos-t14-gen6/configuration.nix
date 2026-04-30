# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
{
  imports =
    [ 
      ./hardware-configuration.nix
      ./modules/boot.nix
      ./modules/nix-config.nix
      ./modules/networking.nix
      ./modules/locale.nix
      ./modules/desktop/x11.nix
      ./modules/desktop/gnome.nix
      ./modules/services/pipewire.nix
      ./modules/fonts.nix
      ./modules/users
      ./modules/security.nix
      ./modules/desktop/sway.nix
      ./modules/desktop/hyprland.nix
      ./modules/services/fprintd.nix
      ./modules/services/logind.nix
      ./modules/services/bluetooth.nix
      ./modules/services/tlp.nix
      ./modules/services/gnome-keyring.nix
      ./modules/services/fwupd.nix
      ./modules/services/keyd.nix
    ];

  # Configure keymap in X11
  
  # Install firefox.
  programs.firefox.enable = true;
  programs.zsh.enable = true;

  # Allow unfree packages
   # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    wezterm
    git
    fastfetch
    gh
    sheldon
    starship
    pure-prompt
    rofi
    slurp
    grim
    wl-clipboard
    waybar
    wlogout
    floorp-bin
    networkmanagerapplet
    vscode-fhs
    egl-wayland
    wireshark
    swww
    discord
    (discord.override {
      withOpenASAR = true; # can do this here too
      withVencord = true;
    })
    vesktop
    direnv
    usbutils
    gnome-firmware
    kitty
    hyprpolkitagent
    brightnessctl
    hypridle
    hyprlock
    rose-pine-hyprcursor
    intel-npu-driver
    unzip
    cliphist
    dunst
    wireplumber
    xdg-desktop-portal-hyprland
    lazygit
    jetbrains.webstorm
    jetbrains.idea
    android-tools
    android-studio
  ];
   programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
  };

   programs.steam = {
     enable = true;
     remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
     dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
     localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
   };

   # This value determines the NixOS release from which the default
   # settings for stateful data, like file locations and database versions
   # on your system were taken. It‘s perfectly fine and recommended to leave
   # this value at the release version of the first install of this system.
   # Before changing this value read the documentation for this option
   # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
   system.stateVersion = "24.11"; # Did you read the comment?

}
