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
- **`/sys/firmware/acpi/platform_profile` を外部から書いてはいけない**: ppd が GFileMonitor で監視しており「ドライバが自力で切り替えた」と解釈して ActiveProfile を追随させる（power-saver が balanced に化ける）。EPP は監視されていないので上書き可
- ppd は EPP を「プロファイル変更 / AC・バッテリ切替 / レジューム」の 3 契機で書き戻す。`modules/perf-mode.nix` の `power-tune` は同じ 3 契機（state.ini の path unit・AC の udev uevent・suspend.target）で再適用する。state.ini は atomic rename なので watch はディレクトリ単位にする
- **AC 抜き差しのレース**: ppd の EPP 書き戻しは UPower 経由で非同期に少し遅れて来るため、udev 契機の即時 1 回では負ける（実測: 2026-10-05 12:36:23 に再適用した直後に ppd が EPP=power を書き戻した）。そのため AC / レジュームは `power-tune-delayed`（1,2,4,8 秒後に複数回再適用、冪等）経由で叩く。プロファイル変更は ppd が state.ini を書く前に EPP を書くので即時 1 回で勝てる
- `hwp_dynamic_boost=1`（power-tune が設定）: I/O 待ち復帰直後だけ最低 P-state を上げる HWP 機能。低電力時の初動もたつきを消す
- power-tune は power-saver の EPP を `balance_performance` へ書き戻す（ppd 既定の `power` は持続/初動とも 2〜3 倍遅い）。PL1=10W は温存するので持続消費の上限は ppd のまま。さらにキビキビさせたい時は `balance_performance` → `performance`、省電力を優先するなら `balance_power` にこの 1 箇所だけ変える
- Niri の `blur passes` は 1（3 pass は GPU 負荷が約 3 倍になり、power-saver の PL1=10W 下でカクつく）
- Niri の `output "eDP-1"` に `variable-refresh-rate`（引数なし=常時有効）。パネルは VRR 対応で、vblank 待ちから解放され遅延・ジャダーが減る。ちらつく場合はこの 1 行を外す
  - VRR の確認手段（i915/xe 側に専用 debugfs は無いが、**DRM core** が connector ごとに `vrr_range` を作る）: `sudo cat /sys/kernel/debug/dri/0/eDP-1/vrr_range`（=EDID の範囲、この機体は 40–60Hz）、`drm_info | grep VRR_ENABLED`（=1 で有効）、PSR 排他（VRR 有効中は PSR が必ず off / `sudo cat /sys/kernel/debug/dri/0/eDP-1/i915_psr_status`）。`niri msg output eDP-1 vrr on|off [--on-demand]` で一時的に A/B できる（config には保存されない）。`i915_` 接頭辞は i915/xe 共有の display コード由来で、GPU ドライバは xe
  - 検証ツール **`nixos-config/scripts/vrr-check.c`**（単一 C ファイル・依存なし・read-only）: `cc -O2 -o vrr-check vrr-check.c` で実行ファイル 1 個。vrr_capable / VRR_ENABLED / EDID レンジ / vblank 周期の実測（基準周期より 10% 以上長い周期が出たら adaptive sync 動作中。VRR off のぶれは ±0.1%）を出す。`-n` 計測スキップ / `-v` プロパティ dump。distrobox の Ubuntu 24.04 で動作確認済み（コンテナ内は `podman exec --user 1000`。container root は uid/gid 未マップで /dev/dri/card0 が EPERM になる）

## omp (oh-my-pi)

- omp 本体とグローバル設定は `home/omp/default.nix` の `programs.omp` 一点に集約（flake input `omp` = `github:can1357/oh-my-pi` の HM モジュール）
- **`enable = true;` を落とすと omp が PATH から消える**。モジュールは `config = lib.mkIf cfg.enable` で `home.packages` 追加と config 生成 activation の両方を括っているので、`programs.omp.settings` だけ書くと設定もパッケージも無効になる（rebuild 後に `zsh: command not found: omp` になる症状）
- `~/.omp/agent/config.yml` は HM switch のたびに宣言値で**上書き（writable copy、symlink ではない）**される。omp が flock + 原子的 rename で書き換えるため store symlink にできない。TUI `/settings` や `omp config set` の結果は次の switch で消えるので、変えた分は `settings` に落とす
- 非デフォルト設定の抽出（TUI 変更 → Nix 同期）: 空 `PI_CODING_AGENT_DIR` で `omp config list --json` を取ると全キーのデフォルトが得られる。実効値と diff して差分だけを `settings` に書く。デフォルトと同値のキーは書かない（上流の既定変更を受けられるように）
- `models.yml`（カスタム provider/model 定義）と `keybindings.yml` はモジュール非対応で `config.yml` とは別ファイル

## 自作 flake input

- `frost-1256/run-vm`, `frost-1256/discord-rpc`, `frost-1256/nixos-vrchat` はユーザー自身のリポジトリ。挙動のおかしい箇所はこれらの input 側が原因のことがある
- `noctalia` は cachix ブランチピン、`niri` は sodiboo/niri-flake（overlay + `niri-unstable` パッケージ、cachix 有効）
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
