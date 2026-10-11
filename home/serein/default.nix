{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  # 上流 flake の systems は x86_64-linux / aarch64-darwin のみ。
  # aarch64-linux (LXC コンテナ) ではビルドできないので、そのときは何も積まない。
  system = pkgs.stdenv.hostPlatform.system;
in
{
  home.packages = lib.optional (
    inputs.serein.packages ? ${system}
  ) inputs.serein.packages.${system}.serein;
}