{
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    (runCommand "gh-zsh-completion" {} ''
      mkdir -p $out/share/zsh/site-functions
      ${lib.getExe gh} completion -s zsh > $out/share/zsh/site-functions/_gh
    '')
    pure-prompt
    zsh-completions
  ];

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.local/share/pnpm"
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    PNPM_HOME = "$HOME/.local/share/pnpm";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    defaultKeymap = "emacs";

    completionInit = ''
      autoload -Uz compinit
      zcompdump=${config.home.homeDirectory}/.zcompdump

      if [[ -f $zcompdump ]]; then
        compinit -C -d $zcompdump
      else
        compinit -d $zcompdump
      fi
    '';

    history = {
      path = "${config.home.homeDirectory}/.histfile";
      size = 10000;
      save = 10000;
      ignoreSpace = true;
    };

    shellAliases = {
      nix-gc = "sudo nix-collect-garbage -d && sudo nixos-rebuild switch";
      ":q" = "exit";

      # VRChat アバター作業 (nixos-vrchat flake の vrchat-unity / FHS 経由で起動)
      alcom = "ALCOM &!"; # ALCOM wrapper 側で FHS に入る
      unity-paths = "unity-android-paths"; # Android(Quest) 用 SDK/NDK/JDK のパス表示

      vim = "nvim";
      vi = "nvim";
      kernel-build = "sudo systemd-nspawn -D /var/lib/machines/kernel-build --network-veth --resolv-conf=auto /bin/bash";
      ubuntu-bootstrap = "sudo ubuntu-nspawn-bootstrap noble /var/lib/machines/ubuntu";
      ubuntu-network-init = "sudo ubuntu-nspawn-configure-network /var/lib/machines/ubuntu";
      ubuntu-container = "sudo systemd-nspawn -M ubuntu -D /var/lib/machines/ubuntu --boot --network-veth --resolv-conf=auto";
      ubuntu-shell = "sudo systemd-nspawn -M ubuntu -D /var/lib/machines/ubuntu --network-veth --resolv-conf=auto /bin/bash";
      ubuntu-machine-start = "sudo ubuntu-nspawn-configure-network /var/lib/machines/ubuntu && sudo systemctl start systemd-nspawn@ubuntu";
      ubuntu-machine-stop = "sudo systemctl stop systemd-nspawn@ubuntu";
    };

    setOptions = [ "NO_NOMATCH" ];

    plugins = [
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh";
      }
      {
        name = "fast-syntax-highlighting";
        src = pkgs.zsh-fast-syntax-highlighting;
        file = "share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh";
      }
    ];

    initContent = lib.mkMerge [
      (lib.mkOrder 500 ''
        typeset -U path
      '')

      (lib.mkOrder 1000 ''
        function ubuntu-machine-shell {
          local user="''${1:-root}"
          sudo machinectl shell "''${user}@ubuntu"
        }

        # Unity Editor を FHS 経由で開く。引数は ~/ALCOM/Projects 配下のプロジェクト名。
        # 省略時は Kipfel。スラッシュ/絶対パスを渡せばそのまま使う。Tab 補完あり。
        # 例: unity-open Kipfel  /  unity-open  /  unity-open /abs/path
        function unity-open {
          local base="$HOME/ALCOM/Projects"
          local arg="''${1:-Kipfel}"
          local proj
          case "$arg" in
            /*|*/*) proj="$arg" ;;       # 絶対 or スラッシュ含み → パスとして扱う
            *)      proj="$base/$arg" ;; # 素の名前 → ~/ALCOM/Projects 配下
          esac
          if [[ ! -d "$proj" ]]; then
            echo "プロジェクトが見つかりません: $proj" >&2
            return 1
          fi
          local editor
          editor=$(ls -d "$HOME"/Unity/Hub/Editor/*/Editor/Unity 2>/dev/null | sort -V | tail -n1)
          if [[ -z "$editor" ]]; then
            echo "Unity Editor が見つかりません (~/Unity/Hub/Editor/*/Editor/Unity)" >&2
            return 1
          fi
          echo "起動: $editor -projectPath $proj"
          unity-fhs-env "$editor" -projectPath "$proj" >/dev/null 2>&1 &!
        }

        # unity-open のプロジェクト名補完 (~/ALCOM/Projects 配下のディレクトリ名)。
        function _unity-open {
          local -a projects
          projects=( "$HOME"/ALCOM/Projects/*(/N:t) )
          compadd -a projects
        }
        compdef _unity-open unity-open

        bindkey "^[OH" beginning-of-line
        bindkey "^[OF" end-of-line
        bindkey "^[[3~" delete-char

        autoload -Uz promptinit
        promptinit
        prompt pure
	unset GTK_IM_MODULE
      '')
    ];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
