# modules/hypr/dunst.nix
{ ... }: {
  services.dunst = {
    enable = true;
  };
  xdg.configFile."dunst/dunstrc".source = ./config/dunst/dunstrc;
}
