{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    pure-prompt
    zsh-completions
    carapace
    ripgrep
    fd
    sd
    dust
    duf
    procs
    nixfmt
  ];

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.local/share/pnpm"
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    PNPM_HOME = "$HOME/.local/share/pnpm";
  };

  programs.bat.enable = true;

  programs.bottom.enable = true;

  programs.carapace = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.gh = {
    enable = true;
    # home.packages の github-cli と二重に入るのを避けるためこちらに一本化
    # _gh 補完はパッケージ付属 + carapace で拾われる
    # 既存 config.yml から移植 (残りは gh デフォルトと同じ値なので省略)
    settings = {
      git_protocol = "https";
      aliases = {
        co = "pr checkout";
      };
    };
  };

  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    defaultKeymap = "emacs";

    completionInit = ''
      # --- zstyle は compinit より前に定義する ---
      # 大文字小文字・ハイフン/アンダースコアを無視
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'
      # メニュー選択・色付け・グループ表示
      zstyle ':completion:*' menu select
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
      zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'
      zstyle ':completion:*' verbose true
      # キャッシュで高速化 (~/.cache/zsh)
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path ${config.xdg.cacheHome}/zsh/zcompcache
      mkdir -p ${config.xdg.cacheHome}/zsh

      autoload -Uz compinit
      zcompdump=${config.home.homeDirectory}/.zcompdump

      # 24時間以内のダンプは -C で即時読込、それ以外は再生成して陳腐化を防ぐ
      if [[ -n $zcompdump(#qN.mh+24) ]]; then
        compinit -d $zcompdump
      else
        compinit -C -d $zcompdump
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

      vim = "nvim";
      vi = "nvim";
      kernel-build = "sudo systemd-nspawn -D /var/lib/machines/kernel-build --network-veth --resolv-conf=auto /bin/bash";

      grep = "rg";
      find = "fd";
      ls = "eza --icons --group-directories-first";
      ll = "eza -la --icons --git";
      cat = "bat";
      du = "dust";
      df = "duf";
      ps = "procs";
      top = "btm";
      man = "tldr";
      cd = "z";
    };

    setOptions = [
      "NO_NOMATCH"
      "EXTENDED_GLOB"
    ];

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
        # --- 電源モード手動切り替え ---
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

        # --- distrobox コンテナ内ではプロンプト先頭にコンテナ名を表示 ---
        # pure の precustom フックが psvar[22] (custom prefix) を描画するので、
        # PROMPT を直接書き換えずにここへ載せる。ホストでは何もしない。
        function prompt_pure_precustom {
          [[ -f /run/.containerenv ]] || return 0
          local cname
          cname=$(sed -n 's/^name="\([^"]*\)"/\1/p' /run/.containerenv)
          [[ -n $cname ]] && psvar[22]="(distrobox:$cname)"
        }
      '')
    ];
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
