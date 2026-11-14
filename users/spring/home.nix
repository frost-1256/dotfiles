{
  pkgs,
  ...
}:
{
  imports = [
    ../../home/fcitx5
    ../../home/discord-rpc
    ../../home/niri
    ../../home/nvim
    ../../home/shell
    ../../home/git
    ../../home/noctalia
    ../../home/wezterm
    ../../home/omp
    ../../home/claude
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
    floorp-bin
    gimp
    fastfetch
    # gh / nix-search-cli は home/shell 側 (portable と共通)
    nwg-displays
    gthumb
    aria2
    pavucontrol
    protonup-qt
    protontricks
    proton-authenticator
    icoutils
    wine
    gpu-screen-recorder-gtk
    mpv
    thunderbird
    teams-for-linux
    tealdeer
    tmux
    tor-browser
    # ida-free # 要手動DL: nix-store --add-fixed sha256 ida-free-pc_93_x64linux.run してから有効化
    ghidra
    lan-mouse
    vesktop
    rustdesk
    distrobox
    distrobox-tui
    (bottles.override { removeWarningPopup = true; })
  ];

  # KeePassXC の .kdbx をデバイス間で同期する用の Syncthing。
  # Syncthing はファイル単体ではなくフォルダ単位で同期するため、
  # ~/Passwords/ を専用フォルダにして中に Passwords.kdbx を置く。
  services.syncthing = {
    enable = true;
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices.remote.id = "PCGB5KH-6M5RUEL-2LQV6YY-EKMKWS3-VI7NXXM-3Q3RGQF-WIVTNJH-SGWIPQK";
      folders."Passwords" = {
        id = "passwords";
        path = "/home/spring/Passwords";
        devices = [ "remote" ];
      };
    };
  };
  # programs.gpg / programs.git の本体は home/git (portable と共通)
  services.gpg-agent = {
    enable = true;
    enableSshSupport = false;

    pinentry.package = pkgs.pinentry-gnome3;
  };

  # set-SSH_AUTH_SOCK.service が basic.target の後に順序付けられて
  # sockets.target との循環依存を起こすのを防ぐ
  systemd.user.services.set-SSH_AUTH_SOCK = {
    Unit.DefaultDependencies = false;
  };
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
