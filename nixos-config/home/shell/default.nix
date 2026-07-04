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

        # --- 電源モード手動切り替え (modules/vrchat.nix の performanceMode と同じノブ) ---
        # highperf  : 最大性能。governor=performance / platform_profile=performance に加え
        #             Intel iGPU の最低クロックを最大(RP0)へ固定。給電時の VR 用。
        # balanced  : 省電力寄りへ戻す (governor=powersave / iGPU 最低クロックを RPn へ解放)。
        # perf-status: 現在のプロファイル/governor/iGPU クロックを表示。
        # ※ sysfs 書き込みは modules/perf-mode.nix の perf-apply(NOPASSWD sudo)に委譲し、
        #   Waybar の custom/perf トグルとロジックを共有する。
        function highperf {
          powerprofilesctl set performance
          sudo perf-apply high && echo "high performance mode: ON"
        }

        function balanced {
          # governor=performance のままだと EPP 書き込みが busy になり
          # powerprofilesctl set balanced が失敗するので、先に governor を解放する。
          sudo perf-apply balanced
          powerprofilesctl set balanced && echo "high performance mode: OFF (balanced)"
        }

        function perf-status {
          echo "power profile : $(powerprofilesctl get 2>/dev/null)"
          echo "platform      : $(cat /sys/firmware/acpi/platform_profile 2>/dev/null)"
          echo "governor      : $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
          for card in /sys/class/drm/card[0-9]*; do
            [ -r "$card/gt_min_freq_mhz" ] && \
              echo "iGPU min/cur/max: $(cat "$card/gt_min_freq_mhz")/$(cat "$card/gt_cur_freq_mhz")/$(cat "$card/gt_max_freq_mhz") MHz"
            for gt in "$card"/device/tile*/gt*/freq0; do
              [ -r "$gt/min_freq" ] && \
                echo "iGPU(xe) min/cur: $(cat "$gt/min_freq")/$(cat "$gt/cur_freq") MHz"
            done
          done
        }

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
