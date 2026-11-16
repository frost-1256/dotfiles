# VRChat アバター制作環境 (Unity Hub + Unity Editor + ALCOM)。spring-b550m-pro4 専用。
#
# 目標は「Windows / 普通の Linux と同じ操作感」(2026-11-16 作り直し):
# - Unity Hub をランチャーから普通に起動し、Hub でエディタを入れてプロジェクトを開く
# - ALCOM から「Unity で開く」がそのまま動く
# - External Tools (JDK / Android SDK / NDK) は既定の "Installed with Unity" のまま
#   Quest 向け (Android) ビルドが通る
#
# 構成: nixpkgs の unityhub は自前の FHS 環境 (fhsEnv。エディタ用ライブラリ込み) で
# Hub を動かすパッケージなので、この FHS を 1 枚だけ使い、Hub / ALCOM / エディタを
# すべてその中で動かす。Hub から起動したエディタは Hub の子プロセスとして FHS 内で動き、
# ALCOM も FHS 内で動かすので ALCOM が直接起動するエディタも FHS 内になる。
# 以前は nixos-vrchat の programs.vrchat-unity (unity-fhs-env で Hub をもう 1 枚包む二重 FHS +
# Nix 製 Android SDK を /etc/unity-android に固定して External Tools を手で指定) だったが、
# 手作業が多くずれの元だったのでやめた。nixos-vrchat input は VR 側 (modules/vrchat.nix) だけで使う。
#
# Android 一式は Hub のモジュール (android + 子モジュールの OpenJDK / SDK & NDK Tools) として
# エディタと一緒に入れる (`unity install`、または Hub の GUI で Android Build Support に
# チェック)。FHS 内なので Unity 同梱の java / aapt2 / NDK clang もそのまま動く。
{
  pkgs,
  ...
}:
let
  # VRChat SDK が要求するエディタ (2026-11 時点でも 2022.3.22f1 のまま。
  # 本体は Unity 6 に移ったが、SDK プロジェクトを Unity 6 にしてはいけないと公式が案内している)
  defaultVersion = "2022.3.22f1";
  defaultChangeset = "887be4894c44";
  editorsRoot = "$HOME/Unity/Hub/Editor";
  projectsRoot = "$HOME/ALCOM/Projects";

  # Hub の FHS に足すもの:
  # - フォント: エディタは FHS 内の /usr/share/fonts を見る。CJK が無いと UI の日本語が化ける
  # - ncurses5: Unity 同梱の Android NDK ツールが libtinfo.so.5 を要求することがある
  unityhub = pkgs.unityhub.override {
    extraLibs =
      p: with p; [
        noto-fonts-cjk-sans
        ipafont
        ncurses5
      ];
  };
  # Hub と同じ FHS で任意のコマンドを実行する入口 (runScript が空なので引数をそのまま exec)
  fhs = "${unityhub.fhsEnv}/bin/unityhub-fhs-env";
  # FHS の中にいるか (中なら /usr/lib に GTK がある。NixOS ホスト側の /usr には無い)
  inFhs = "[ -e /usr/lib/libgtk-3.so.0 ] || [ -e /usr/lib64/libgtk-3.so.0 ]";

  # ALCOM 起動時の自動更新ダイアログを抑止 (nixpkgs の build は checkForUpdates=false だが
  # UI 側がそのフラグを見ていない。nixos-vrchat と同じパッチ。ALCOM はローカルビルドになる)
  alcom = pkgs.alcom.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace vrc-get-gui/components/providers.tsx \
        --replace-fail 'import { tc } from "@/lib/i18n";' $'import { tc } from "@/lib/i18n";\nimport globalInfo from "@/lib/global-info";' \
        --replace-fail 'if (import.meta.env.DEV) return;' $'if (import.meta.env.DEV) return;\n\t\t\t\tif (!globalInfo.checkForUpdates) return;'
    '';
  });
  # ALCOM を Hub の FHS 内で起動する。ALCOM はエディタ一覧を Hub (`unityhub --headless`) から
  # 取り、選んだエディタを直接起動するので、FHS 内で動かせばエディタも FHS 内で動く。
  # PATH はホスト側を引き継ぐので、中から呼ぶ unityhub も下の package の wrapper が拾われる
  alcomLauncher = pkgs.writeShellScriptBin "ALCOM" ''
    exec ${fhs} ${alcom}/bin/ALCOM "$@"
  '';
  alcomApp = pkgs.runCommand "alcom-fhs" { } ''
    mkdir -p $out/bin $out/share/applications
    ln -s ${alcomLauncher}/bin/ALCOM $out/bin/ALCOM
    # アイコンは本体のものをそのまま使う
    if [ -d ${alcom}/share/icons ]; then
      cp -rs ${alcom}/share/icons $out/share/icons
    fi
    # vcc:// (VCC のリポジトリ追加リンク) も ALCOM で受ける
    cat > $out/share/applications/ALCOM.desktop <<EOF
    [Desktop Entry]
    Name=ALCOM
    Comment=ALCOM - Alternative Creator Companion (VRChat)
    Exec=$out/bin/ALCOM %u
    Icon=ALCOM
    StartupWMClass=ALCOM
    Type=Application
    Terminal=false
    Categories=Development;
    MimeType=x-scheme-handler/vcc;
    EOF
  '';

  # エディタを起動するラッパー。Windows の Hub と同じく、-projectPath があれば
  # ProjectSettings/ProjectVersion.txt のバージョンのエディタを選ぶ (無ければ defaultVersion)。
  # 複数バージョン (将来の Unity 6 等) を入れても VRChat プロジェクトを違う版で開かない。
  # ALCOM の「Unity のパス」を手で指定したい時もこれを指定すればよい
  unityEditor = pkgs.writeShellScriptBin "unity-editor" ''
    set -euo pipefail
    proj=""
    prev=""
    for a in "$@"; do
      [ "$prev" = "-projectPath" ] && proj="$a"
      prev="$a"
    done
    ver=""
    if [ -n "$proj" ] && [ -f "$proj/ProjectSettings/ProjectVersion.txt" ]; then
      ver=$(sed -n 's/^m_EditorVersion: *//p' "$proj/ProjectSettings/ProjectVersion.txt" | tr -d '\r')
    fi
    ver="''${ver:-${defaultVersion}}"
    exe="${editorsRoot}/$ver/Editor/Unity"
    if [ ! -x "$exe" ]; then
      echo "Unity $ver がインストールされていません (unity install で入れられます)" >&2
      exit 1
    fi
    if ${inFhs}; then exec "$exe" "$@"; fi
    exec ${fhs} "$exe" "$@"
  '';

  fzf = "${pkgs.fzf}/bin/fzf";
  vrcGet = "${pkgs.vrc-get}/bin/vrc-get";
  selectProject = ''
    ls -d ${projectsRoot}/*/ 2>/dev/null | sed 's|/$||; s|.*/||' | ${fzf} --bind "j:down,k:up" --prompt="プロジェクト > "
  '';

  # よく使う操作の TUI / CLI。GUI (Hub / ALCOM) だけで完結するので無くても困らない
  unityCli = pkgs.writeShellScriptBin "unity" ''
        set -euo pipefail

        cmd_hub() { exec unityhub "$@"; }

        # エディタ + VRChat 制作に要るモジュールを Hub の headless CLI で一括インストール。
        # - android (+ --childModules で OpenJDK / Android SDK & NDK Tools): Quest 向けビルド。
        #   External Tools は "Installed with Unity" のままでこれが使われる
        # - windows-mono: PC 向けアバターのビルド (Linux エディタでも VRChat PC 用は
        #   StandaloneWindows64 でビルドするので必要)
        cmd_install() {
          local version="''${1:-${defaultVersion}}" changeset="''${2:-}"
          if [ "$version" = "${defaultVersion}" ]; then changeset="${defaultChangeset}"; fi
          if [ -z "$changeset" ]; then
            echo "$version の changeset を第 2 引数で指定してください (Unity のダウンロードアーカイブの URL にある 12 桁)" >&2
            exit 1
          fi
          echo "Unity $version ($changeset) を Android / Windows Build Support 付きでインストールします"
          unityhub --headless install --version "$version" --changeset "$changeset" \
            --module android --module windows-mono --childModules
        }

        # 既存エディタに後からモジュールを足す (Hub の GUI の「モジュールを加える」と同じ)
        cmd_modules() {
          local version="''${1:-${defaultVersion}}"
          unityhub --headless install-modules --version "$version" \
            --module android --module windows-mono --childModules
        }

        cmd_open() {
          local proj="''${1:-}"
          [ -n "$proj" ] || proj=$(${selectProject}) || exit 1
          [ -n "$proj" ] || exit 1
          local dir="$proj"
          [ -d "$dir" ] || dir="${projectsRoot}/$proj"
          [ -d "$dir" ] || { echo "プロジェクトが見つかりません: $proj" >&2; exit 1; }
          exec unity-editor -projectPath "$dir"
        }

        cmd_vrc() {
          local proj="''${1:-}"
          [ -n "$proj" ] || proj=$(${selectProject}) || exit 1
          [ -n "$proj" ] || exit 1
          shift || true
          ${vrcGet} update 2>/dev/null || true
          cd "${projectsRoot}/$proj"
          if [ $# -eq 0 ]; then
            read -r -p "追加するパッケージ ID (例: com.vrchat.avatars。空 Enter で ALCOM) > " pkg
            [ -n "$pkg" ] || exec ALCOM
            ${vrcGet} install "$pkg"
          else
            ${vrcGet} install "$@"
          fi
        }

        cmd_help() {
          cat <<'EOF'
    unity - VRChat アバター制作ツール (普段は Unity Hub / ALCOM の GUI だけで足りる)

      unity                    メニュー
      unity hub                Unity Hub を開く
      unity install [ver cs]   エディタ + Android / Windows Build Support を一括導入 (既定 ${defaultVersion})
      unity modules [ver]      既存エディタに Android / Windows Build Support を追加
      unity open [project]     プロジェクトを対応するバージョンのエディタで開く
      unity alcom              ALCOM を開く
      unity vrc [project]      vrc-get で VCC パッケージ追加
    EOF
        }

        cmd_menu() {
          local choice
          choice=$(${fzf} --bind "j:down,k:up" --prompt="unity> " <<'EOF'
    Hub      Unity Hub を開く
    Open     プロジェクトを開く
    Alcom    ALCOM を開く
    Vrc      vrc-get で VCC パッケージ追加
    Install  Unity ${defaultVersion} + Android / Windows Build Support を導入
    Modules  既存エディタにビルドモジュールを追加
    Help     ヘルプ
    EOF
        ) || exit 1
          case "''${choice%% *}" in
            Hub) cmd_hub ;;
            Open) cmd_open ;;
            Alcom) exec ALCOM ;;
            Vrc) cmd_vrc ;;
            Install) cmd_install ;;
            Modules) cmd_modules ;;
            *) cmd_help ;;
          esac
        }

        case "''${1:-}" in
          "") cmd_menu ;;
          hub) shift; cmd_hub "$@" ;;
          install) shift; cmd_install "$@" ;;
          modules) shift; cmd_modules "$@" ;;
          open) shift; cmd_open "$@" ;;
          alcom) exec ALCOM ;;
          vrc) shift; cmd_vrc "$@" ;;
          help|-h|--help) cmd_help ;;
          *) echo "不明なコマンド: $1 (unity help)" >&2; exit 1 ;;
        esac
  '';
in
{
  environment.systemPackages = [
    # unityhub コマンド + デスクトップエントリ + unityhub:// (ログイン / インストールリンク) の受け口
    unityhub
    alcomApp
    unityEditor
    unityCli
    pkgs.vrc-get
  ];

  # Linux VRChat SDK Patch (ALCOM に https://befuddledlabs.github.io/LinuxVRChatSDKPatch/index.json を追加)
  # の Build & Test 用 Proton。SDK Control Panel の Proton path にこのパスを指定する
  environment.etc."compatibilitytools.d/Proton-GE".source = pkgs.proton-ge-bin.steamcompattool;
}
