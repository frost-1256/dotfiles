{ pkgs, ... }: {
  users.users.spring = {
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;
}
