{ ... }:
{
  # CLI (tailscale) は nixpkgs の services.tailscale モジュールが
  # environment.systemPackages に入れる (nixos/modules/services/networking/tailscale.nix)。
  # ここで重ねて入れない。
  services.tailscale.enable = true;
}
