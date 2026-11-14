# nixpkgs の pkgs.config を一元管理する共有アトリビュート。
# flake.nix の mkPkgs(standalone home-manager 用 pkgs)と
# modules/system.nix の nixpkgs.config(NixOS グローバル pkgs)の両方から import し、
# permittedInsecurePackages / allowUnfree の二重管理を防ぐ。
{
  allowUnfree = true;
  permittedInsecurePackages = [
    "electron-38.8.4"
  ];
}
