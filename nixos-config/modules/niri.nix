{ pkgs, inputs, ... }:
{
  niri-flake.cache.enable = true;

  nixpkgs.overlays = [
    (import ../overlays/niri-compat.nix)
    inputs.niri.overlays.niri
  ];

  programs.niri.enable = true;
  programs.niri.package = pkgs.niri-unstable;
}
