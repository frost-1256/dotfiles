{
  pkgs,
  inputs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  imports = [
    ../../home/fcitx5
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
  # nixpkgs は nixos-unstable-small を追うが、home-manager / nixvim は 26.11
  # リリースを使うので release check の警告が毎回出る。意図的な組み合わせなので抑制。
  home.enableNixpkgsReleaseCheck = false;
  programs.nixvim.version.enableNixpkgsReleaseCheck = false;

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
    #gpu-screen-recorder-gtk
    mpv
    thunderbird
    tealdeer
    tmux
    tor-browser
    # ida-free # 要手動DL: nix-store --add-fixed sha256 ida-free-pc_93_x64linux.run してから有効化
    lan-mouse
    vesktop
    distrobox
    distrobox-tui
    deepseek-harness
    # T3 Code (コーディングエージェントの GUI)。t3code-desktop が Electron 版
    t3code
    # Orca (AI コーディング IDE + CLI)。llm-agents.nix のビルドをそのまま使う。
    # computer use 用の AT-SPI は modules/system.nix 側で有効化済み。
    inputs.llm-agents.packages.${system}.orca
    # ターミナルで動くコーディングエージェント (両方 nixpkgs のビルドをそのまま使う)
    opencode # コマンド: opencode
    antigravity-cli # Google の TUI エージェント。コマンド: agy
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
