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
  - `users/spring/` — `nixos.nix`（システム側ユーザー定義）/ `home.nix`（NixOS用 HM）/ `home-portable.nix`（非NixOS用 HM）/ `home/core.nix`（共通: username, homeDirectory, stateVersion）

## ビルド・再構築

- rebuild は既定で `sudo nixos-rebuild switch` を**直接実行**する（認証は指紋 fprintd）
- nixos-rebuild skill（tmux 経由）は **指紋認証ができなかった場合** と **ユーザーが明示的に tmux 使用を指示した場合のみ** 使う。手順: root shell が開いた tmux セッション `nixos-rebuild` へ `sudo nixos-rebuild switch 2>&1 | tee /tmp/rebuild-output` を送り、`/tmp/rebuild-output` を読む。セッションが無ければ自分で作らずユーザーに起動を依頼
- 構文・評価チェックは `nix flake check` / `nix eval .#nixosConfigurations.spring-t14-gen6`（書き込み禁止なら `--no-write-lock-file` 併用）で可
- 早めの構文チェックは `nix-instantiate --parse <file>.nix`（評価しない。ファイル単位のタイポ検出に便利）
- フォーマッタは **`nixfmt-rfc-style`**（home/shell/default.nix で導入済み、CI なし）。編集後は `nixfmt $(git ls-files '*.nix')` で整形、`--check` 付きで差分確認できる。スタイルは nixfmt 準拠（2 インデント）なので手書き時も周りに合わせる
- `flake.lock` はコミット済み。明示的な依頼なく `nix flake update` しない

## デスクトップ周のクセ

- WM は **Niri + Noctalia**（Hyprland からの移行済み）。`home/hypr/` は生きているが `users/spring/home.nix` の import がコメントアウトされて無効化されているだけ。**消さない・有効化しない**
- Niri 設定は `home/niri/config.nix` で **KDL DSL**（`inputs.niri.lib.kdl` の `node`/`plain`/`leaf`/`flag`）から生成する。DSL 関数の使い分けを間違えると KDL パースエラー:
  - 引数+子ノード → `node`、子のみ → `plain`、値のみ → `leaf`、空ノード → `flag`（例: `(flag "natural-scroll")` であって `(leaf "natural-scroll" true)` ではない）
- Noctalia の declarative 設定は `home/noctalia/settings.nix`（`pkgs.formats.toml` で TOML 化）。設定アプリの変更はランタイム側 `~/.local/state/noctalia/settings.toml` に書かれ、Nix には自動で入らない → declarative に落とすときは noctalia-sync skill を使う。反映は `systemctl --user restart noctalia.service`
- `programs.waybar.enable = lib.mkForce false`（home/niri/config.nix）: Noctalia 側のバーを使うため waybar は意図的に無効。`modules/perf-mode.nix` 内の `pkill -RTMIN+9 waybar` は Hyprland 時代の名残で実質 no-op
- host default.nix の `disabledModules = [ "programs/wayland/noctalia.nix" ]` は nixpkgs 内蔵版を無効化して flake input 版を使うため。外さない

## モジュール・設定の罠

- `modules/gnome.nix` は**名前に反して GNOME を有効化しない**。GDM + Hyprland の有効化と gnome-keyring の mkForce false が本体
- flake の `specialArgs` / `extraSpecialArgs` で `username` と `inputs` が全モジュールに注入される。モジュール引数で `{ username, ... }` / `{ inputs, ... }` を取れるのが前提
- `permittedInsecurePackages = [ "electron-38.8.4" ]` が **2 箇所**（flake の `mkPkgs` と `modules/system.nix` の nixpkgs.config）に重複存在。変える時は両方
- `mkHomeModules`（NixOS 経由）と `mkPortableHomeModules`（standalone HM）の 2 系統の home 構成がある。`home/` 配下のモジュールは両方から拾われるので、NixOS 専用依存（noctalia input 等）を portable 側で参照しない
- ブランチ `portable-hm` は非 NixOS（macOS 含む）向け home-manager 専用。main にマージする前提で分離されている
- `modules/perf-mode.nix`: sysfs 書き込みは NOPASSWD sudo を `perf-apply` にのみ許可するスコープ最小化設計。bar の即時更新は signal（RTMIN+9）方式
- 固有机能: fprintd（TOD goodix ドライバ + hid-multitouch unbind udev ルール）、NextDNS DoT、Syncthing で `~/Passwords`（KeePassXC）同期、VRChat/Unity 一式（`modules/unity.nix` に fzf ベースの `unity` CLI ラッパ、ALCOM/vrc-get、unityhub:// ハンドラ）

## 自作 flake input

- `frost-1256/run-vm`, `frost-1256/discord-rpc`, `frost-1256/nixos-vrchat` はユーザー自身のリポジトリ。挙動のおかしい箇所はこれらの input 側が原因のことがある
- `noctalia` は cachix ブランチピン、`niri` は sodiboo/niri-flake（overlay + `niri-unstable` パッケージ、cachix 有効）

## コミット・コメントのクセ

- コード内コメントは日本語が主流。既存の日本語コメント・設計意図の説明は保持・踏襲する
- このリポジトリでコミットする際は **`--no-gpg-sign` で署名なし**。リポジトリ側は `commit.gpgsign=true` だが、gpg の PIN プロンプトがエージェントのシェルに出てユーザーが入力できないため
- main のコミットメッセージは「aaaa」「ok stable?」「fix error」等の雑なものが混在。**真似しない**。書くなら `feat(scope):` / `fix:` 形式で日本語説明付き（portable-hm ブランチの流儀）
- flake description は "haru's ..." だがユーザー名/git name は "spring"。どちらに寄せるか迷ったら `spring`

## その他

- `nixos-config/.codex` は中身 0 バイトの残骸。`.gitignore` には `old-dots/` と `flake-lock.nix` がある
- i18n は `en_US.UTF-8` ベース + `extraLocaleSettings` で ja_JP を個別指定（fcitx5 + hazkey 入力）
