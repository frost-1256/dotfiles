{
  pkgs,
  ...
}:
{
  imports = [
    ../../home/nvim
    ../../home/shell
    ../../home/core.nix
  ];
  home.packages = with pkgs; [
    github-cli
    nix-search-cli
  ];
  programs.gpg.enable = true;
  programs.git.settings = {
    user.name = "spring";
    user.email = "harusan@spring-server.com";
  };
}
