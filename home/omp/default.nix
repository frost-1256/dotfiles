{ pkgs, ... }:
let
  # omp のネイティブ層 (pi-walker) の設定。既定はいずれも控えめで、
  # エージェントの grep → glob → ast-grep の連続呼び出しでほぼ毎回フル走査になる:
  #   FS_SCAN_CACHE_TTL_MS        既定 1000ms  → 直後の再走査しか共有しない
  #   FS_SCAN_CACHE_MAX_ENTRIES   既定 16
  #   FS_SCAN_CACHE_MAX_BYTES     既定 64MiB
  #   PI_WALK_WORKERS             既定 4 本   → この機体は 8 スレッド、既定は過小
  # 自身の書き込みは omp が invalidateFsScanCache で無効化するので、
  # TTL を伸ばしてもエージェント自身が編集したファイルは即座に反映される。
  walkerEnv = {
    FS_SCAN_CACHE_TTL_MS = "15000";
    FS_SCAN_CACHE_MAX_ENTRIES = "64";
    FS_SCAN_CACHE_MAX_BYTES = "268435456";
    PI_WALK_WORKERS = "0";
  };
in
{
  # omp のグローバル設定。`~/.omp/agent/config.yml` はモジュールが
  # home-manager switch のたびに宣言値で上書き（writable copy）するため、
  # TUI の /settings や `omp config set` の結果はここに落とすこと。
  # 値がスキーマのデフォルトと同じキーは意図的に書かない（上流の既定変更を
  # 受けられるようにするため）。
  programs.omp = {
    enable = true;

    settings = {
      startup = {
        quiet = true;
        setupWizard = false;
      };
      theme.dark = "dark-dracula";
      composer = {
        shape = "claude";
        tokenRate = true;
      };
      statusLine.preset = "minimal";
      tui = {
        imeSafeCursor = true;
        codexResetFireworks = true;
      };
      defaultThinkingLevel = "auto";
      hideThinkingBlock = true;
      completion.notify = "off";
      error.notify = "on";

      # 1 リクエストあたりの input トークン上限を明示する。
      # 既定はモデルの窓（この環境のモデルは catalog 上 1M）と reserve だけで
      # 決まるため、実測で 1 セッション 35 万トークン/リクエスト、
      # コンパクションが一度も発動しない状態になっていた。
      # thresholdTokens は percentage より優先される固定上限。
      compaction.thresholdTokens = 150000;

      # 1M 級の長コンテキスト窓は premium 価格帯に入ることがあり、
      # 上限も実質無制限になるので無効化する。
      extendedContext = false;

      # 実験的機能: モデルのストリーミング中に検証済みのローカル read を
      # 先回りして実行し、ツール往復の待ち時間を減らす（結果は破棄可能）。
      # 無効化するならこの 2 行を消す（既定 false）。
      tools.speculativeExecution = {
        enabled = true;
        maxInFlight = 4;
      };

      security.enabled = true;
      github.enabled = true;
      computer.enabled = true;
      astGrep.enabled = true;
      task.enableLsp = true;
      commands = {
        enableOpencodeUser = true;
        enableClaudeUser = true;
      };

      # 既定モデルは Zen 無料枠 (zenfix 経由。内蔵 opencode-zen は
      # OMP が UUID 形式の x-opencode-session を後付けして 403 になる)。
      # config.yml は HM switch で上書きされるため宣言側にも書く。
      modelRoles.default = "zenfix/muse-spark-1.3-contributor-free";
    };
  };

  # models.yml はモジュール非対応のため home.file で宣言化。
  # zenfix: baseUrl を Vercel 上のプロキシ (Bun runtime) に向ける。
  # プロキシが opencode の UA / descending な ses_ セッション / 本物の
  # tools 配列を付与して上流 https://opencode.ai/zen/v1 へ転送する。
  # フォールバックとして下のローカル zen-proxy (127.0.0.1:8790) も起動したまま。
  home.file.".omp/agent/models.yml" = {
    force = true;
    text = ''
      providers:
        zenfix:
          baseUrl: https://zenfix-rho.vercel.app/zen/v1
          api: openai-completions
          apiKey: OPENCODE_API_KEY
          # Zen 無料枠モデル。protocol はモデル固定で、muse 系のみ responses。
          # jev-1.13-free は chat/responses どちらも ModelProtocolUnsupported の
          # ため載せない。thinking.mode は effort のみ (toggle は不可)。
          models:
            - id: muse-spark-1.3-contributor-free
              name: Muse Spark 1.3 Free (zenfix)
              api: openai-responses
              reasoning: true
              input: [text, image]
              contextWindow: 1048576
              maxTokens: 131072
              thinking:
                mode: effort
                efforts: [minimal, low, medium, high, xhigh, max]
              compat:
                supportsReasoningSummary: true
                includeEncryptedReasoning: false
                filterReasoningHistory: true
                replayReasoningContent: false
                reasoningContentField: reasoning_content
                allowsSyntheticReasoningContentForToolCalls: true
            - id: muse-spark-1.2-contributor-free
              name: Muse Spark 1.2 Free (zenfix)
              api: openai-responses
              reasoning: true
              input: [text, image]
              contextWindow: 1048576
              maxTokens: 131072
              thinking:
                mode: effort
                efforts: [minimal, low, medium, high, xhigh, max]
              compat:
                supportsReasoningSummary: true
                includeEncryptedReasoning: false
                filterReasoningHistory: true
                replayReasoningContent: false
                reasoningContentField: reasoning_content
                allowsSyntheticReasoningContentForToolCalls: true
            - id: deepseek-v4.1-flash-free
              name: DeepSeek V4.1 Flash Free (zenfix)
              reasoning: true
              input: [text]
              contextWindow: 1048576
              maxTokens: 384000
              thinking:
                mode: effort
                efforts: [minimal, low, medium, high, xhigh, max]
            - id: glm-5.3-flash-free
              name: GLM-5.3-Flash Free (zenfix)
              reasoning: true
              input: [text, image]
              contextWindow: 200000
              maxTokens: 32000
              thinking:
                mode: effort
                efforts: [low, high, max]
            - id: cat-jam-free
              name: Cat Jam Free (zenfix)
              reasoning: true
              input: [text]
              contextWindow: 1048576
              maxTokens: 131072
              thinking:
                mode: effort
                efforts: [low, medium, high, xhigh, max]
            - id: ll-alpha-free
              name: LL Alpha Free (zenfix)
              reasoning: true
              input: [text]
              contextWindow: 262144
              maxTokens: 65536
              thinking:
                mode: effort
                efforts: [low, medium, high, xhigh, max]
            - id: space-bunny-free
              name: Space Bunny Free (zenfix)
              reasoning: true
              input: [text, image]
              contextWindow: 1048576
              maxTokens: 524288
              thinking:
                mode: effort
                efforts: [low, medium, high, xhigh, max]
            - id: nemotron-3.5-super-vl-free
              name: Nemotron 3.5 Super VL Free (zenfix)
              reasoning: true
              input: [text, image]
              contextWindow: 1048576
              maxTokens: 131072
              thinking:
                mode: effort
                efforts: [minimal, low, medium, high, xhigh]
            - id: longcat-2.5-preview-free
              name: LongCat 2.5 Preview Free (zenfix)
              reasoning: true
              input: [text, image]
              contextWindow: 1000000
              maxTokens: 131072
            - id: mimo-v2.6-flash-free
              name: MiMo-V2.6-Flash Free (zenfix)
              reasoning: true
              input: [text, image]
              contextWindow: 200000
              maxTokens: 32000
            - id: nemotron-3.5-lightning-free
              name: Nemotron 3.5 Lightning Free (zenfix)
              reasoning: true
              input: [text]
              contextWindow: 262144
              maxTokens: 262144
        orcarouter:
          baseUrl: https://api.orcarouter.ai/v1
          api: openai-completions
          apiKey: orcakey
          authHeader: true
          models:
            - id: deepseek/deepseek-v4-flash-free
              name: DeepSeek V4 Flash Free
              reasoning: false
              input: [text]
              contextWindow: 200000
              maxTokens: 8192
              compat:
                supportsDeveloperRole: false
                maxTokensField: max_tokens
    '';
  };

  # Vercel プロキシのフォールバック用ローカルプロキシ (127.0.0.1:8790)。
  # 通常は Vercel 側を使う。必要なら baseUrl をこれに向け直す。
  home.packages = [ pkgs.bun ];
  home.file.".omp/zen-proxy/proxy.ts".source = ./zen-proxy/proxy.ts;
  home.file.".omp/zen-proxy/opencode_tools.json".source = ./zen-proxy/opencode_tools.json;

  systemd.user.services.zen-proxy = {
    Unit = {
      Description = "opencode Zen free-tier proxy";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      ExecStart = "${pkgs.bun}/bin/bun %h/.omp/zen-proxy/proxy.ts";
      Environment = [ "ZEN_PROXY_PORT=8790" ];
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.sessionVariables = walkerEnv;
}
