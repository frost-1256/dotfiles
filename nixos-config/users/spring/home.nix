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
    filezilla
    floorp-bin
    nix-search-cli
    vrcx
    github-cli
    nwg-displays
    obsidian
    keybase
    keybase-gui
    pavucontrol
    protonup-qt
  ];
  services.keybase.enable = true;
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;

    pinentry.package = pkgs.pinentry-curses;
    # GUIなら:
    # pinentry.package = pkgs.pinentry-qt;
  };
  programs.git.settings = {
    user.name = "spring";
    user.email = "harusan@spring-server.com";
  };
}
