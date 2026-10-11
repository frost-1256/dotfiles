{ ... }:
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
  # zenfix: 内蔵 opencode-zen の UUID セッション付与を避け、
  # opencode UA + ses_/msg_ 形式ヘッダで Zen 無料枠を通す。
  home.file.".omp/agent/models.yml".text = ''
    providers:
      zenfix:
        baseUrl: https://opencode.ai/zen/v1
        api: openai-completions
        apiKey: OPENCODE_API_KEY
        headers:
          User-Agent: opencode/1.18.31
          Referer: https://opencode.ai/
          x-opencode-client: cli
          x-opencode-session: ses_ee9213315ffeMXYcXtQVAeJ5IB
          x-opencode-request: msg_0b176f647001bIJxq0BSRHt8pu
        models:
          - id: fledge-alpha-free
            name: Fledge Alpha Free (zenfix)
            reasoning: true
            input: [text, image]
            contextWindow: 1048576
            maxTokens: 131072
            thinking:
              mode: effort
              efforts: [minimal, low, medium, high, xhigh]
          - id: muse-spark-1.3-contributor-free
            name: Muse Spark 1.3 Free (zenfix)
            api: openai-responses
            reasoning: true
            input: [text, image]
            contextWindow: 1048576
            maxTokens: 131072
            thinking:
              mode: effort
              efforts: [minimal, low, medium, high, xhigh]
            compat:
              supportsReasoningSummary: true
              includeEncryptedReasoning: false
              filterReasoningHistory: true
              replayReasoningContent: false
              reasoningContentField: reasoning_content
              allowsSyntheticReasoningContentForToolCalls: true
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

  home.sessionVariables = walkerEnv;
}
