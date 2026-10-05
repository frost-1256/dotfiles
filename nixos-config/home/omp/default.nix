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
    };
  };

  home.sessionVariables = walkerEnv;
}
