{ ... }: {
  # omp のグローバル設定。`~/.omp/agent/config.yml` はモジュールが
  # home-manager switch のたびに宣言値で上書き（writable copy）するため、
  # TUI の /settings や `omp config set` の結果はここに落とすこと。
  # 値がスキーマのデフォルトと同じキーは意図的に書かない（上流の既定変更を
  # 受けられるようにするため）。現在のデフォルト一致キー: theme.light,
  # symbolPreset, statusLine.separator, statusLine.contextLine,
  # statusLine.transparent, statusLine.compactThinkingLevel, display.shimmer,
  # textVerbosity, steeringMode, tools.approvalMode, stt.enabled, autoResume,
  # autolearn.enabled, edit.mode, providers.autoThinkingMaxEffort
  programs.omp.settings = {
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
    extendedContext = true;
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
}
