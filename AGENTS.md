# AGENTS.md

spring (haru) の NixOS dotfiles リポジトリ。作業中に新しいクセ・罠を見つけたらこのファイルに追記すること。

## 基本構成

- Flake は `nixos-config/flake.nix`（git root は `~/dotfiles`、Nix 設定は `nixos-config/` 配下）
- ホスト: `spring-t14-gen6`（ThinkPad T14 Gen6 / Intel）。ユーザーは `spring`
- nixpkgs は `nixos-unstable-small`、カーネル `linuxPackages_latest`、stateVersion `26.11`（system/home 両方）
- ディレクトリ役割:
  - `hosts/<host>/` — ホスト固有設定 + generated な `hardware-configuration.nix`
  - `modules/` — システム側機能モジュール（host の default.nix から import）
  - `home/` — home-manager モジュール（アプリごとに `default.nix` + 細分化ファイル）
  - `users/spring/` — `home.nix`（NixOS用 HM）/ `home-portable.nix`（非NixOS用 HM）/ `home/core.nix`（共通: username, homeDirectory, stateVersion）。システム側のユーザー定義は `modules/system.nix` に統合済み（旧 `nixos.nix` は削除）

## ビルド・再構築

- rebuild は既定で `sudo nixos-rebuild switch` を**直接実行**する（認証は指紋 fprintd）
- nixos-rebuild skill（tmux 経由）は **指紋認証ができなかった場合** と **ユーザーが明示的に tmux 使用を指示した場合のみ** 使う。手順: root shell が開いた tmux セッション `nixos-rebuild` へ `sudo nixos-rebuild switch 2>&1 | tee /tmp/rebuild-output` を送り、`/tmp/rebuild-output` を読む。セッションが無ければ自分で作らずユーザーに起動を依頼
- 構文・評価チェックは `nix flake check` / `nix eval .#nixosConfigurations.spring-t14-gen6`（書き込み禁止なら `--no-write-lock-file` 併用）で可
- 早めの構文チェックは `nix-instantiate --parse <file>.nix`（評価しない。ファイル単位のタイポ検出に便利）
- フォーマッタは **`pkgs.nixfmt`**（home/shell/default.nix で導入済み、CI なし）。旧 `nixfmt-rfc-style` は `pkgs.nixfmt` と同一になり deprecated 警告が出るため使わない。編集後は `nixfmt $(git ls-files '*.nix')` で整形、`--check` 付きで差分確認できる。スタイルは nixfmt 準拠（2 インデント）なので手書き時も周りに合わせる
- `flake.lock` はコミット済み。明示的な依頼なく `nix flake update` しない

## デスクトップ周のクセ

- WM は **Niri + Noctalia**（Hyprland からの移行済み）。`home/hypr/` は生きているが `users/spring/home.nix` の import がコメントアウトされて無効化されているだけ。**消さない・有効化しない**
- Niri 設定は `home/niri/config.nix` で **KDL DSL**（`inputs.niri.lib.kdl` の `node`/`plain`/`leaf`/`flag`）から生成する。DSL 関数の使い分けを間違えると KDL パースエラー:
  - 引数+子ノード → `node`、子のみ → `plain`、値のみ → `leaf`、空ノード → `flag`（例: `(flag "natural-scroll")` であって `(leaf "natural-scroll" true)` ではない）
- Noctalia の declarative 設定は `home/noctalia/settings.nix`（`pkgs.formats.toml` で TOML 化）。設定アプリの変更はランタイム側 `~/.local/state/noctalia/settings.toml` に書かれ、Nix には自動で入らない → declarative に落とすときは noctalia-sync skill を使う。反映は `systemctl --user restart noctalia.service`
- `programs.waybar.enable = lib.mkForce false`（home/niri/config.nix）: Noctalia 側のバーを使うため waybar は意図的に無効。`modules/perf-mode.nix` 内の `pkill -RTMIN+9 waybar` は Hyprland 時代の名残で実質 no-op
- host default.nix の `disabledModules = [ "programs/wayland/noctalia.nix" ]` は nixpkgs 内蔵版を無効化して flake input 版を使うため。外さない

## モジュール・設定の罠

- `modules/gnome.nix` は**名前に反して GNOME を有効化しない**。GDM + Hyprland + gnome-keyring の有効化が本体（gnome-keyring はかつて mkForce false だったが有効化に転換済み）
- `modules/virtualisation.nix` の `boot.kernelModules` に `vfio_virqfd` を**入れない**: kernel 6.x で vfio 本体に統合されてモジュールが消えており、書くと `systemd-modules-load` が毎起動 `Failed to find module 'vfio_virqfd'` を出す
- ボリューム削減の設定（2026-10 追加）: `/nix` と `/home` に btrfs `compress=zstd,noatime`（`hosts/spring-t14-gen6/default.nix`。反映は reboot か `mount -o remount /nix /home`）、`documentation.doc.enable = false`（HTML マニュアル + `nixos-help` を削除、man は残す）、`environment.defaultPackages` から perl を除外、`nix.settings.auto-optimise-store = true`。既存 store を hardlink 最適化するには `sudo nix store optimise`（自動では新規追加分のみ）。`services.speechd.enable = false`（graphical-desktop の mkDefault で入る画面読み上げ。orca 不使用なら不要で mbrola voices 含め約 0.7GB 削減）。`/tmp` の Android ROM 残骸（system.new.dat 等）は都度捨てる（9/27 分で約 9GB。10 月分は現役の可能性あり温存）
- **`system.disableInstallerTools = true` にしてはいけない**: `nixos-install`/`nixos-generate-config`/`nixos-option` だけでなく `nixos-rebuild`(-ng) 本体も system path から消え、`sudo nixos-rebuild switch` が `command not found` になる（2026-10-05 に実際に踏んだ。復旧は前世代の `sw/bin/nixos-rebuild` を絶対パスで叩く）
- flake の `specialArgs` / `extraSpecialArgs` で `username` と `inputs` が全モジュールに注入される。モジュール引数で `{ username, ... }` / `{ inputs, ... }` を取れるのが前提
- `allowUnfree` / `permittedInsecurePackages = [ "electron-38.8.4" ]` は `nixos-config/nixpkgs-config.nix` に一元化済み。flake の `mkPkgs`（standalone HM 用 pkgs）と `modules/system.nix` の `nixpkgs.config`（NixOS グローバル pkgs）が同じファイルを import している。変えるのはこの 1 ファイルだけで良い
- `mkHomeModules`（NixOS 経由）と `mkPortableHomeModules`（standalone HM）の 2 系統の home 構成がある。`home/` 配下のモジュールは両方から拾われるので、NixOS 専用依存（noctalia input 等）を portable 側で参照しない
- ブランチ `portable-hm` は非 NixOS（macOS 含む）向け home-manager 専用。main にマージする前提で分離されている
- `modules/perf-mode.nix`: sysfs 書き込みは NOPASSWD sudo を `perf-apply` にのみ許可するスコープ最小化設計。bar の即時更新は signal（RTMIN+9）方式。`perf-apply balanced` は iGPU 下限を既定の rpe に戻すだけで rpn(100MHz) まで下げない（DVFS の立ち上がりが間に合わずカクつくため）
- 固有机能: fprintd（TOD goodix ドライバ + hid-multitouch unbind udev ルール）、NextDNS DoT、Syncthing で `~/Passwords`（KeePassXC）同期、VRChat/Unity 一式（`modules/unity.nix` に fzf ベースの `unity` CLI ラッパ、ALCOM/vrc-get、unityhub:// ハンドラ）

## 電源プロファイル (power-profiles-daemon) 周

- ホストは T14 Gen6 / Core Ultra 5 228V（Lunar Lake）。intel_pstate active + HWP、iGPU は **xe** ドライバ（`/sys/class/drm/card0/device/tile*/gt*/freq0` に min_freq 等）
- 実測（P-core 固定・同一ワークロード）: 持続時間 performance 248ms / balance_performance 264ms / **power 693ms**、3秒アイドル後の初動 34ms / 60ms / (もっと遅い)。体感速度も初動のもたつき（=「ワンテンポ遅れる」）もほぼ EPP で決まる
- ppd の割り当て: performance→EPP=performance + platform=performance、balanced→balance_power(バッテリ)/balance_performance(AC) + balanced、power-saver→**EPP=power** + platform=**low-power**（PL1 が 37W→10W。time window は 28 秒なのでバーストは効く）
- **`/sys/firmware/acpi/platform_profile` を外部から書いてはいけない**: ppd が GFileMonitor で監視しており「ドライバが自力で切り替えた」と解釈して ActiveProfile を追随させる（power-saver が balanced に化ける）。EPP は監視されていないので上書き可。`perf-apply` は governor / iGPU クロックのみを書き、このファイルには触らない（プロファイル変更は呼び出し側の `powerprofilesctl set` に一本化）
- ppd は EPP を「プロファイル変更 / AC・バッテリ切替 / レジューム」の 3 契機で書き戻す。`modules/perf-mode.nix` の `power-tune` は同じ 3 契機（state.ini の path unit・AC の udev uevent・suspend.target）で再適用する。state.ini は atomic rename なので watch はディレクトリ単位にする
- **AC 抜き差しのレース**: ppd の EPP 書き戻しは UPower 経由で非同期に少し遅れて来るため、udev 契機の即時 1 回では負ける（実測: 2026-10-05 12:36:23 に再適用した直後に ppd が EPP=power を書き戻した）。そのため AC / レジュームは `power-tune-delayed`（1,2,4,8 秒後に複数回再適用、冪等）経由で叩く。プロファイル変更は ppd が state.ini を書く前に EPP を書くので即時 1 回で勝てる
- `hwp_dynamic_boost=1`（power-tune が設定）: I/O 待ち復帰直後だけ最低 P-state を上げる HWP 機能。低電力時の初動もたつきを消す
- power-tune は power-saver の EPP を `balance_performance` へ書き戻す（ppd 既定の `power` は持続/初動とも 2〜3 倍遅い）。PL1=10W は温存するので持続消費の上限は ppd のまま。さらにキビキビさせたい時は `balance_performance` → `performance`、省電力を優先するなら `balance_power` にこの 1 箇所だけ変える
  - **罠**: `Type=oneshot` + `wantedBy = [ "multi-user.target" ]` は完了まで target 到達を引き留める。`power-tune` のように ppd 起動前 (ppd 自体が multi-user 到達後) に `powerprofilesctl` を叩くと D-Bus タイムアウト約 50 秒が固まり userspace 68 秒の主因になった (2026-10-06 実測)。起動時トリガは `systemd.paths` / udev / delayed service で足りるなら WantedBy に入れない。`powerprofilesctl` 呼び出しには `timeout 5` を付け、`TimeoutStartSec = "30s"` も付ける
  - fprintd は切断処理で SEGV する (Claim 競合 → transfer timed out → segfault)。SEGV 後の `endpoint stalled` は restart だけでは消えず USB 再列挙が必要なため、`modules/system.nix` に自動復旧を入れている: 睡眠前 stop の `fprintd-presuspend` + 本体 `ExecStartPre` (`fprintd-usb-cycle`。睡眠跨ぎの初回起動だけ unbind/bind、stamp 判定) + `fprintd-recover` (guard 専用。force stamp + restart) + `fprintd-guard`（ジャーナル監視）。センサは USB の Synaptics `06cb:00f9` (autosuspend 無効化の udev あり)。`04F3:3195` はタッチパッド側で無関係
  - **resume 後に fprintd を unit から restart してはいけない** (2026-10-06 23:37:51 実測): noctalia が PrepareForSleep(false) の約 14ms 後に VerifyStart を投げるため正面衝突して NoReply になり同セッション permanent dead。D-Bus activation 待ちで直列化する (呼び出し側は最大 25 秒待つ)。列挙できる ≠ healthy (resume 毎に degraded 化し NoEnrolledPrints になる。restart 無効・unbind/bind のみ有効。00:02/00:11 実測) のため睡眠跨ぎは毎回再列挙。**罠**: 上流 unit は `ProtectSystem=strict` で /sys read-only のため ExecStartPre の unbind/bind には `ReadWritePaths` が要る (無いと黙って死ぬ。00:42:09 実測)。確認は `journalctl -b` と `journalctl --user -u noctalia` (`[fingerprint]` 行) の突き合わせ
  - **指を置かずに `fprintd-verify` を回してはいけない** (2026-10-06 の疑い): `transfer failed` の直後にセンサ USB が自発再列挙し、以後の daemon から enrollment が不可視化した。再登録 + USB unbind/bind で復旧。診断時の素振り verify は避ける
- Niri の `blur passes` は 1（3 pass は GPU 負荷が約 3 倍になり、power-saver の PL1=10W 下でカクつく）
- Niri の `output "eDP-1"` に `variable-refresh-rate`（引数なし=常時有効）。パネルは VRR 対応で、vblank 待ちから解放され遅延・ジャダーが減る。ちらつく場合はこの 1 行を外す
  - VRR の確認手段（i915/xe 側に専用 debugfs は無いが、**DRM core** が connector ごとに `vrr_range` を作る）: `sudo cat /sys/kernel/debug/dri/0/eDP-1/vrr_range`（=EDID の範囲、この機体は 40–60Hz）、`drm_info | grep VRR_ENABLED`（=1 で有効）、PSR 排他（VRR 有効中は PSR が必ず off / `sudo cat /sys/kernel/debug/dri/0/eDP-1/i915_psr_status`）。`niri msg output eDP-1 vrr on|off [--on-demand]` で一時的に A/B できる（config には保存されない）。`i915_` 接頭辞は i915/xe 共有の display コード由来で、GPU ドライバは xe
  - 検証ツール **`nixos-config/scripts/vrr-check.c`**（単一 C ファイル・依存なし・read-only）: `cc -O2 -o vrr-check vrr-check.c` で実行ファイル 1 個。vrr_capable / VRR_ENABLED / EDID レンジ / vblank 周期の実測（基準周期より 10% 以上長い周期が出たら adaptive sync 動作中。VRR off のぶれは ±0.1%）を出す。`-n` 計測スキップ / `-v` プロパティ dump。distrobox の Ubuntu 24.04 で動作確認済み（コンテナ内は `podman exec --user 1000`。container root は uid/gid 未マップで /dev/dri/card0 が EPERM になる）

## zsh 起動速度

- compinit の呼び出し元は `home/shell/default.nix` の `completionInit` **だけ**。NixOS 側は `modules/system.nix` の `programs.zsh.enableGlobalCompInit = false` で `/etc/zshrc` の compinit を止めている（戻すと起動に +0.4 秒、二重 compinit になる）
- **罠**: `[[ -n $var(#qN.mh+24) ]]` は `[[ ]]` 内では glob 展開されず**常に真**。そのため毎回フル compinit（= ダンプ全走査、起動 +0.6 秒）になっていた。glob qualifier は `zcompdump_stale=( $HOME/.zcompdump(N.mh+24) )` のように `[[ ]]` の外で展開する
- **罠**: 検証で HM 管理の dotfile リンク（`~/.zshrc` 等）を一時的に差し替えたあと戻すときは `readlink -f` を使わない。store の実体へ直接張り直すと HM activation が `Existing file ... would be clobbered` で失敗する。`readlink`（= `.../home-manager-files/.zshrc` 形式）で復元する

## nvim (nixvim)

- `home/nvim/default.nix` が唯一の nvim 設定（flake input `nixvim` の HM モジュール）。`~/.config/nvim/init.lua` は HM が生成する symlink（`programs.nixvim.nixpkgs.*` 以外はすべて nixvim の `plugins.*` で書く。`extraPlugins`/`extraConfigLua` は原則使わない）
- **tree-sitter は nvim-treesitter を使わない**（nvim 0.12 で core に統合、本家は archived）。parser は `nvim-treesitter-parsers.<lang>`、queries は `nvim-treesitter.queries.<lang>` を `extraPlugins` に入れて Nix 固定し、`:TSInstall` 等が必要な言語だけ `tree-sitter-manager.nvim`（`buildVimPlugin` + `fetchFromGitHub` で固定）で実行時導入する。manager には `assume_installed` で Nix 固定言語を渡す（二重管理防止）
  - **罠**: core には tree-sitter の `indentexpr` が無い（`vim.treesitter.indentexpr` は存在しない）。nvim-treesitter を外すと TS ベースのインデントは失われ、Vim の filetype indent にフォールバックする
  - manager が parser を clone/ビルドできるよう `extraPackages = [ git gcc tree-sitter ]` を nvim の PATH に追加している
- **LSP**: `plugins.lsp.servers.{nixd,lua_ls}.enable`
  - **罠**: `plugins.lsp.servers.<name>.settings` は nixvim がルートキー（lua_ls → `Lua = {}`、nixd → `nixd = {}`）で包む。`settings` 側にそのキーを書くと二重になる（例: `Lua.Lua.runtime`）
  - `plugins.cmp.autoEnableSources = false` にしているので、LSP の補完能力は `plugins.lsp.capabilities` に `cmp_nvim_lsp.default_capabilities()` を明示的に足している（auto-enable 任せだと入らない）
- **罠**: nixvim は `nixpkgs.source` から**独自に pkgs を作る**ため、NixOS 側の `nixpkgs.config`（allowUnfree 等）が引き継がれない。`programs.nixvim.nixpkgs.config = import ../../nixpkgs-config.nix;` を渡さないと `barbar-nvim`（unfree 扱い）で評価が落ちる
- ビルド検証は `nix build --impure --no-link --print-out-paths --expr '(builtins.getFlake "/home/spring/dotfiles/nixos-config").nixosConfigurations.spring-t14-gen6.config.home-manager.users.spring.programs.nixvim.build.package'`。実機確認は `XDG_CONFIG_HOME` に生成 init.lua を置いて headless 起動（`xdg.configFile."nvim/init.lua".source` で store path が取れる）

## omp (oh-my-pi)

- omp 本体とグローバル設定は `home/omp/default.nix` の `programs.omp` 一点に集約（flake input `omp` = `github:can1357/oh-my-pi` の HM モジュール）
- **`enable = true;` を落とすと omp が PATH から消える**。モジュールは `config = lib.mkIf cfg.enable` で `home.packages` 追加と config 生成 activation の両方を括っているので、`programs.omp.settings` だけ書くと設定もパッケージも無効になる（rebuild 後に `zsh: command not found: omp` になる症状）
- `~/.omp/agent/config.yml` は HM switch のたびに宣言値で**上書き（writable copy、symlink ではない）**される。omp が flock + 原子的 rename で書き換えるため store symlink にできない。TUI `/settings` や `omp config set` の結果は次の switch で消えるので、変えた分は `settings` に落とす
- 非デフォルト設定の抽出（TUI 変更 → Nix 同期）: 空 `PI_CODING_AGENT_DIR` で `omp config list --json` を取ると全キーのデフォルトが得られる。実効値と diff して差分だけを `settings` に書く。デフォルトと同値のキーは書かない（上流の既定変更を受けられるように）
- `models.yml`（カスタム provider/model 定義）と `keybindings.yml` はモジュール非対応で `config.yml` とは別ファイル

## 自作 flake input

- `frost-1256/run-vm`, `frost-1256/discord-rpc`, `frost-1256/nixos-vrchat` はユーザー自身のリポジトリ。挙動のおかしい箇所はこれらの input 側が原因のことがある
- `noctalia` は cachix ブランチピン、`niri` は sodiboo/niri-flake（overlay + `niri-unstable` パッケージ、cachix 有効）
  - noctalia に local carry パッチあり (`home/noctalia/patches/*.patch`。現在は未適用・dormant): 指紋 VerifyStart の bounded retry (16 x 500ms) + watchdog 再 arm。素は ClaimDevice 時にしか再試行せず resume 直後の NoReply/NoEnrolledPrints/NoSuchDevice で同セッション死亡する。ExecStartPre 方式 (activation 待ち直列化) で解決したため適用していないが、再発時は `programs.noctalia.package.overrideAttrs` で当てる。既存テストの契約 (disconnect で再 arm しない・他人の claim に手を出さない) は保ってある。input 更新でパッチが当たらなくなったらビルド失敗で気付くので中身を見直す
- nixpkgs から `libdisplay-info_0_2` が削除されたが niri-flake がまだ要求するため、`overlays/niri-compat.nix` で現行 `libdisplay-info` を 0.2.0 として見せて互換化している（mkPkgs と modules/niri.nix の両方に適用、niri-flake 側が対応したら削除）。`gpu-screen-recorder` の UI は外部 flake `gsr-ui-nix` がオプション衝突を起こすため削除済み。nixpkgs 内蔵の `programs.gpu-screen-recorder.ui` を使うこと

## コミット・コメントのクセ

- コード内コメントは日本語が主流。既存の日本語コメント・設計意図の説明は保持・踏襲する
- このリポジトリでコミットする際は **`--no-gpg-sign` で署名なし**。リポジトリ側は `commit.gpgsign=true` だが、gpg の PIN プロンプトがエージェントのシェルに出てユーザーが入力できないため
- main のコミットメッセージは「aaaa」「ok stable?」「fix error」等の雑なものが混在。**真似しない**。書くなら `feat(scope):` / `fix:` 形式で日本語説明付き（portable-hm ブランチの流儀）
- flake description は "haru's ..." だがユーザー名/git name は "spring"。どちらに寄せるか迷ったら `spring`

## opencode スキル (~/.config/opencode/skills/)

該当作業では必ずスキルを load してから動く。リポジトリ外にあるので clone してもここには入らない。

- `niri-config` — Niri 設定 (`home/niri/config.nix`) の編集・保守。KDL DSL の規則、最小 diff、UX に効く変更 (レイアウト・アニメーション・操作体系) は承認取り
- `noctalia-config` — Noctalia の declarative 設定 (`home/noctalia/`) の編集・保守。既存パレット再利用・最小 diff 方針
- `noctalia-sync` — 設定アプリが書いたランタイム側 `~/.local/state/noctalia/settings.toml` を settings.nix へ反映する。設定アプリで変更があった・ランタイム設定を declarative に落としたい時に使う
- `nixos-rebuild` — tmux セッション経由のリビルド手順。指紋認証失敗時か明示指示時のみ (上記「ビルド・再構築」参照)
- `agent-workflow` — 非自明タスクをサブエージェントへ委譲して実装するワークフロー

## その他

- `nixos-config/.codex` は中身 0 バイトの残骸。`.gitignore` には `old-dots/` と `flake-lock.nix` がある
- i18n は `en_US.UTF-8` ベース + `extraLocaleSettings` で ja_JP を個別指定（fcitx5 + hazkey 入力）
