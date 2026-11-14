# 非 NixOS (macOS / 他ディストリ / lxc-aarch64) 向けの最小 home。
# gh は home/shell の programs.gh、nix-search-cli も home/shell 側で入る。
{ ... }:
{
  imports = [
    ../../home/nvim
    ../../home/shell
    ../../home/git
    ../../home/claude
    ../../home/core.nix
  ];
}
