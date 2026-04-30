# modules/hyprlock.nix
{ ... }: {
  programs.hyprlock = {
    enable = true;
  };
  xdg.configFile."hypr/hyprlock.conf".source = ./config/hypr/hyprlock.conf;
}
