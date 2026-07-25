{ pkgs, ... }:
{
  programs.niri.settings = {
    input = {
      keyboard = {
        xkb = {
          layout = "us";
        };
      };
    };
    layout = {
      gaps = 8;
    };
  };
}