# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
{
  imports =
    [ 
      ./hardware-configuration.nix
      ./modules/boot.nix
      ./modules/networking.nix
      ./modules/locale.nix
      ./modules/desktop/x11.nix
      ./modules/desktop/gnome.nix
      ./modules/services/pipewire.nix
      ./modules/users
      ./modules/services/keyd.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Configure keymap in X11
  security.rtkit.enable = true;
  
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    font-awesome
    hicolor-icon-theme
  ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
  programs.nix-ld.enable = true;  
  # Install firefox.
  programs.firefox.enable = true;
  programs.zsh.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
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

   programs.sway = {
     enable = false;
     package = pkgs.swayfx;
   };
   programs.hyprland = {
     enable = true;
     xwayland.enable = true;
   }; 
   environment.sessionVariables.NIXOS_OZONE_WL = "1";
   programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
  };
   services.fprintd.enable = true;

   programs.steam = {
     enable = true;
     remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
     dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
     localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
   };
   
   services.logind.settings.Login.HandlePowerKey = "suspend";
   services.logind.settings.Login.HandleLidSwitch = "suspend";
   services.blueman.enable = true;
   services.power-profiles-daemon.enable = false;
   services.tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 60;
        #Optional helps save long term battery health
        START_CHARGE_THRESH_BAT0 = 75; # 40 and below it starts to charge
        STOP_CHARGE_THRESH_BAT0 = 85; # 80 and above it stops charging

      };
   };
   services.gnome.gnome-keyring.enable = true;
   security.pam.services.login.enableGnomeKeyring = true;
   services.fwupd.enable = true;


   # This value determines the NixOS release from which the default
   # settings for stateful data, like file locations and database versions
   # on your system were taken. It‘s perfectly fine and recommended to leave
   # this value at the release version of the first install of this system.
   # Before changing this value read the documentation for this option
   # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
   system.stateVersion = "24.11"; # Did you read the comment?

}
