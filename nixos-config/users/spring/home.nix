{pkgs, ...}: {
  imports = [
    ../../home/fcitx5
    ../../home/hypr
    ../../home/nvim
    ../../home/shell
    ../../home/steam
    ../../home/wezterm
    ../../home/core.nix
  ];
  home.packages = with pkgs; [
    floorp-bin
    obsidian
  ];
  programs.git.settings = {
    user.name = "spring";
    user.email = "harusan@spring-server.com";
  };
}
