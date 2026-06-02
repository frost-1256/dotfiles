{
  ccusage,
  llm-agents,
  nix-claude-code,
  pkgs,
  ...
}: {
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
    nix-claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
    ccusage.packages.${pkgs.stdenv.hostPlatform.system}.default
    llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.ccstatusline
  ];
  home.file.".claude/settings.json" = {
    force = true;
    text = builtins.toJSON {
      effortLevel = "medium";
      theme = "auto";
      statusLine = {
        type = "command";
        command = "ccstatusline";
        padding = 0;
        refreshInterval = 10;
      };
    };
  };
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
