{ pkgs, ... }: {
  xdg.configFile."hypr/hyprland.conf".source = ./config/hypr/hyprland.conf;

  home.packages = with pkgs; [
    # Hyprland
    hyprland

    # Terminal & Apps
    wezterm
    nautilus

    # Bar & Notifications
    waybar
    dunst

    # Wallpaper
    awww

    # Launcher & Menus
    rofi

    # Lock & Idle
    hypridle
    hyprlock

    # Network & Bluetooth
    networkmanagerapplet
    blueman

    # Clipboard
    cliphist
    wl-clipboard

    # Screenshot
    grim
    slurp

    # Logout
    wlogout

    # Cursor theme
    rose-pine-hyprcursor

    # Audio & Brightness (CLIツール)
    wireplumber      # wpctl
    brightnessctl

    # Chat
    vesktop
  ];

  home.sessionVariables.NIXOS_OZONE_WL = "1";
}
