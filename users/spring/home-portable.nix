# 非 NixOS (macOS / 他ディストリ / lxc-aarch64) 向けの最小 home。
# gh は home/shell の programs.gh、nix-search-cli も home/shell 側で入る。
{ ... }:
{
  # NixOS 側と同じく unstable nixpkgs + 26.11 の HM / nixvim の組み合わせ。
  home.enableNixpkgsReleaseCheck = false;
  programs.nixvim.version.enableNixpkgsReleaseCheck = false;

  imports = [
    ../../home/nvim
    ../../home/shell
    ../../home/git
    ../../home/claude
    ../../home/core.nix
  ];
}
