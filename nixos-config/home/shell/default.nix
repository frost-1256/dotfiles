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

      vim = "nvim";
      vi = "nvim";
      kernel-build = "sudo systemd-nspawn -D /var/lib/machines/kernel-build --network-veth --resolv-conf=auto /bin/bash";
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
	unset GTK_IM_MODULE
      '')
    ];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
