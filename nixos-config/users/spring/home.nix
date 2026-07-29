{
  ccusage,
  llm-agents,
  nix-claude-code,
  pkgs,
  ...
}: {
  imports = [
    ../../home/fcitx5
    # Hyprland → Niri に移行済みのため無効化
    # ../../home/hypr
    ../../home/niri
    ../../home/nvim
    ../../home/shell
    ../../home/noctalia
    ../../home/wezterm
    ../../home/kitty
    ../../home/core.nix
  ];
  # nm-applet / blueman-applet の自動起動を無効化
  xdg.autostart.entries = {
    "nm-applet.desktop" = {
      enable = false;
    };
    "blueman.desktop" = {
      enable = false;
    };
  };

  home.packages = with pkgs; [
    filezilla
    floorp-bin
    fastfetch
    nix-search-cli
    vrcx
    github-cli
    nwg-displays
    obsidian
    keybase
    keybase-gui
    pavucontrol
    protonup-qt
    gpu-screen-recorder-gtk
    nix-claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
    ccusage.packages.${pkgs.stdenv.hostPlatform.system}.default
    llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.ccstatusline
    thunderbird
    teams-for-linux
    tealdeer
    keepassxc
    tmux
    vesktop
  ];

  # KeePassXC の .kdbx をデバイス間で同期する用の Syncthing。
  # Syncthing はファイル単体ではなくフォルダ単位で同期するため、
  # ~/Passwords/ を専用フォルダにして中に Passwords.kdbx を置く。
  services.syncthing = {
    enable = true;
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices.remote.id =
        "PCGB5KH-6M5RUEL-2LQV6YY-EKMKWS3-VI7NXXM-3Q3RGQF-WIVTNJH-SGWIPQK";
      folders."Passwords" = {
        id = "passwords";
        path = "/home/spring/Passwords";
        devices = [ "remote" ];
      };
    };
  };
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
    enableSshSupport = false;

    pinentry.package = pkgs.pinentry-curses;
    # GUIなら:
    # pinentry.package = pkgs.pinentry-qt;
  };

  # set-SSH_AUTH_SOCK.service が basic.target の後に順序付けられて
  # sockets.target との循環依存を起こすのを防ぐ
  systemd.user.services.set-SSH_AUTH_SOCK = {
    Unit.DefaultDependencies = false;
  };
  programs.git = {
    settings = {
      user.name = "spring";
      user.email = "harusan@spring-server.com";
    };
  };
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
