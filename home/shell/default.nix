{
  config,
  lib,
  pkgs,
  ...
}:
let
  # `eval "$(tool init zsh)"` 系は起動のたびに fork+exec が走る (carapace だけで ~5ms)。
  # 出力はパッケージにしか依存しないので build 時に生成して source するだけにする
  mkZshInit =
    name: cmd:
    pkgs.runCommand "${name}-init.zsh" { } ''
      export HOME=$TMPDIR
      ${cmd} > $out
    '';
  carapaceInit = mkZshInit "carapace" "${config.programs.carapace.finalPackage}/bin/carapace _carapace zsh";
  direnvInit = mkZshInit "direnv" "${lib.getExe config.programs.direnv.package} hook zsh";
  zoxideInit = mkZshInit "zoxide" "${lib.getExe config.programs.zoxide.package} init zsh";

  # fast-syntax-highlighting は読み込み時に `$(uname -a)` で Darwin 判定する (fork ~2ms)。
  # 同じ判定は $OSTYPE で fork 無しにできる
  # pure は起動時、SSH_CONNECTION が無いと `who -m` を fork して「sudo -s 越しの SSH」を
  # 検出しようとする (~2ms)。sshd はたまにしか使わず、普通の SSH ログインは
  # SSH_CONNECTION で判定されるので who フォールバックは切る
  purePrompt = pkgs.pure-prompt.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace pure.zsh \
        --replace-fail '(( $+commands[who] ))' '(( 0 ))'
    '';
  });

  fastSyntaxHighlighting = pkgs.zsh-fast-syntax-highlighting.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace fast-syntax-highlighting.plugin.zsh \
        --replace-fail '$(uname -a)' '$OSTYPE'
    '';
  });
in
{
  home.packages = with pkgs; [
    purePrompt
    zsh-completions
    # programs.carapace は init にフルパスを埋めるだけで PATH に入れない。
    # 補完関数は `carapace` をコマンド名で呼ぶため消さないこと
    carapace
    ripgrep
    fd
    sd
    dust
    duf
    procs
    nixfmt
    nix-search-cli
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

  # carapace / zoxide / direnv の zsh 統合は自前で build 時生成したものを source する (mkZshInit)
  programs.carapace = {
    enable = true;
    enableZshIntegration = false;
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
    extraOptions = [ "--group-directories-first" ];
    # ls / la / lt / lla は統合が生成する (eza エイリアス経由で上のオプションが付く)
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = false;
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

      # ダンプが無い / 24 時間より古いときだけフル compinit で再生成し、
      # それ以外は -C で読み込むだけにして起動パスからスキャンを外す。
      # 注意: `[[ -n $zcompdump(#qN.mh+24) ]]` は `[[ ]]` 内では glob 展開されず
      # 常に真になり、毎回フル compinit（実測 +0.6 秒）になっていた。
      # glob qualifier は必ず外側で展開すること。
      zcompdump_stale=( ${config.home.homeDirectory}/.zcompdump(N.mh+24) )
      if (( $#zcompdump_stale )); then
        compinit -d "$zcompdump"
        # 罠: compinit は関数集合が変わらないとダンプを書き直さないため mtime が
        # 古いまま残り、24h 判定が永遠に真 = 毎回フル compinit (compaudit 込み)
        # になっていた (2026-11-14 実測: 10/18 から未更新)。明示的に touch する。
        touch "$zcompdump"
      else
        compinit -C -d "$zcompdump"
      fi
      unset zcompdump_stale
      # ダンプをバイトコンパイル (source 時に新しい .zwc が自動で使われる)。
      # 起動を待たせないようバックグラウンドで。
      {
        if [[ -s $zcompdump && ( ! -s $zcompdump.zwc || $zcompdump -nt $zcompdump.zwc ) ]]; then
          zcompile "$zcompdump"
        fi
      } &!
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
      ll = "eza -la";
      cat = "bat";
      du = "dust";
      df = "duf";
      ps = "procs";
      top = "btm";
      man = "tldr";
      cd = "z";
    };

    # .zshrc 冒頭 (プラグイン読み込み前) に書かれる
    localVariables = {
      # --- zsh-autosuggestions の入力レスポンス ---
      # MANUAL_REBIND: 毎 precmd での全 widget 再ラップを止める (プロンプト復帰が軽くなる)
      # BUFFER_MAX_SIZE: 長い貼り付け中に履歴検索で固まるのを防ぐ
      # (非同期化 USE_ASYNC は 0.7.1 が zsh>=5.0.8 で自動有効化するので書かない)
      ZSH_AUTOSUGGEST_MANUAL_REBIND = 1;
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = 50;
      # fast-syntax-highlighting の既定 (~/.cache/fast-syntax-highlighting) は存在せず、
      # 毎回 fsh へフォールバックして `mkdir -p` を fork していた (~3ms)。最初から fsh を指す
      FAST_WORK_DIR = "${config.xdg.cacheHome}/fsh";
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
        src = fastSyntaxHighlighting;
        file = "share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh";
      }
    ];

    initContent = lib.mkMerge [
      (lib.mkOrder 1000 ''
        # --- 電源モード手動切り替え ---
        # highperf : performance プロファイルへ。重めビルド・ベンチ等の一時使用用
        #            (旧来の governor/iGPU pin は VR 専用だったため削除)。
        # balanced : バランスへ戻す。
        # power    : 省電力 (power-tune が EPP だけ balance_performance に補正する)。
        # perf-status: 現在のプロファイル/governor/iGPU クロックを表示。
        function highperf { powerprofilesctl set performance }
        function balanced { powerprofilesctl set balanced }
        function power { powerprofilesctl set power-saver }

        function perf-status {
          echo "power profile : $(powerprofilesctl get 2>/dev/null)"
          echo "platform      : $(cat /sys/firmware/acpi/platform_profile 2>/dev/null)"
          echo "governor      : $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
          echo "EPP           : $(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null)"
          for card in /sys/class/drm/card[0-9]*; do
            for gt in "$card"/device/tile*/gt*/freq0; do
              [ -r "$gt/min_freq" ] && \
                echo "iGPU(xe) min/cur/max: $(cat "$gt/min_freq")/$(cat "$gt/cur_freq" 2>/dev/null)/$(cat "$gt/rp0_freq" 2>/dev/null) MHz"
            done
          done
        }

        # --- SSH サーバーのオン/オフ (modules/sshd.nix の sudo ルール使用) ---
        # off は 22 番ポートが閉じる (socket activation 無効)。
        function ssh-on { sudo systemctl start sshd && echo "sshd: on" }
        function ssh-off { sudo systemctl stop sshd && echo "sshd: off" }
        function ssh-toggle {
          if systemctl is-active --quiet sshd; then ssh-off; else ssh-on; fi
        }
        function ssh-status {
          echo "sshd   : $(systemctl is-active sshd 2>/dev/null)"
          ss -ltnH 'sport = :22' | awk '{print "listen : " $4}'
        }

        bindkey "^[OH" beginning-of-line
        bindkey "^[OF" end-of-line
        bindkey "^[[3~" delete-char

        # promptinit は fpath 全体から prompt_*_setup を探す (~2ms) ので通さず pure を直接読む。
        # promptinit 経由で付く prompt_opts (subst / percent) はここで立てる
        setopt prompt_subst prompt_percent
        autoload -Uz prompt_pure_setup
        prompt_pure_setup

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
      # --- `./binary` の不足ライブラリを自動解決 (nix-alien があるホストのみ = modules/nix-ld.nix を import している両デスクトップ) ---
      # Enter 時に、先頭語がパス指定 (/ を含む) の Nix ストア外 ELF で、nix-ld の共通ライブラリ
      # (NIX_LD_LIBRARY_PATH) を足しても ldd に "not found" が出る時だけ、
      # `nix-alien-ld <bin> -- <args>` に書き換えて実行する (不足分を nix-index で解決して取得。
      # 2 回目以降は ~/.cache/nix-alien のキャッシュで即起動)。足りていれば何もしない。
      # accept-line 自体は上書きせず Enter 用の別ウィジェットから `zle accept-line` を呼ぶ
      # (autosuggestions / fast-syntax-highlighting が accept-line を包んでいるので連鎖を壊さない)。
      # zsh 内で打った時だけ効く (ファイラ等からの起動は nix-ld のみ)。起動時は関数定義だけで fork 無し。
      # portable (macOS) では nix-alien-ld が無いので何も定義しない
      (lib.mkOrder 1100 ''
        if (( $+commands[nix-alien-ld] )); then
          function _nix_alien_accept_line {
            local -a words
            words=(''${(z)BUFFER})
            local cmd=''${(Q)words[1]-}
            if [[ $cmd == */* && -f $cmd && -x $cmd && ''${cmd:A} != /nix/store/* ]]; then
              local magic=""
              read -r -k 4 -u 0 magic < $cmd 2>/dev/null
              if [[ $magic == $'\x7f'ELF ]] &&
                LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH ldd -- $cmd 2>/dev/null | grep -q 'not found'; then
                if (( ''${#words} > 1 )); then
                  BUFFER="nix-alien-ld ''${words[1]} -- ''${words[2,-1]}"
                else
                  BUFFER="nix-alien-ld ''${words[1]}"
                fi
                zle redisplay
              fi
            fi
            zle accept-line
          }
          zle -N nix-alien-accept-line _nix_alien_accept_line
          bindkey '^M' nix-alien-accept-line
        fi
      '')
      # zoxide は HM 既定と同じく compinit (mkOrder 570) の後
      (lib.mkOrder 851 "source ${zoxideInit}")
      (lib.mkOrder 1500 ''
        source ${direnvInit}
        source ${carapaceInit}
      '')
    ];
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = false;
    nix-direnv.enable = true;
  };
}
