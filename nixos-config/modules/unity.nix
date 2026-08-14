{
  pkgs,
  ...
}:
let
  fzf = "${pkgs.fzf}/bin/fzf";
  vrcGet = "${pkgs.vrc-get}/bin/vrc-get";

  projectsRoot = "$HOME/ALCOM/Projects";
  unityDefaultVersion = "2022.3.22f1";
  unityDefaultRev = "887be4894c44";

  listProjects = ''
    ls -d ${projectsRoot}/*/ 2>/dev/null | sed 's|.*/||; s|/$||'
  '';

  selectProject = ''
    ls -d ${projectsRoot}/*/ 2>/dev/null | sed 's|.*/||; s|/$||' | ${fzf} --prompt="プロジェクト > "
  '';

  unityCli = pkgs.writeShellScriptBin "unity" ''
    #!/usr/bin/env bash
    set -euo pipefail

    hub_url() { unityhub-shell -c "unityhub '$1'"; }

    cmd_hub() { unityhub-shell -c unityhub; }

    cmd_install() {
      local version="''${1:-${unityDefaultVersion}}"
      local rev="''${2:-${unityDefaultRev}}"
      if [ "$version" = "${unityDefaultVersion}" ]; then rev="${unityDefaultRev}"; fi
      echo "Unity $version をインストールします (rev $rev)"
      echo "Unity Hub が開くので指示に従ってください"
      hub_url "unityhub://$version/$rev"
    }

    cmd_url() {
      local url="''${1:-}"
      if [ -z "$url" ]; then
        url=$(wl-paste 2>/dev/null || true)
      fi
      if [ -z "$url" ]; then
        echo "unityhub:// URL を指定してください (クリップボードからも取れます)" >&2
        exit 1
      fi
      echo "URL を Unity Hub に渡します: $url"
      hub_url "$url"
    }

    cmd_open() {
      local proj="''${1:-}"
      if [ -z "$proj" ]; then
        if [ ! -d ${projectsRoot} ]; then
          echo "プロジェクトディレクトリがありません: ${projectsRoot}" >&2
          exit 1
        fi
        proj=$(${selectProject})
      fi
      [ -n "$proj" ] || exit 1
      local dir="${projectsRoot}/$proj"
      if [ ! -d "$dir" ]; then
        echo "プロジェクトが見つかりません: $dir" >&2
        exit 1
      fi
      echo "Unity で $proj を開きます..."
      unity-fhs-editor -projectPath "$dir"
    }

    cmd_alcom() { ALCOM; }

    cmd_new() {
      echo "新規プロジェクトは ALCOM で作成します (右上の + ボタン)" >&2
      ALCOM
    }

    cmd_vrc() {
      local proj="''${1:-}"
      if [ -z "$proj" ]; then
        proj=$(${selectProject})
      fi
      [ -n "$proj" ] || exit 1
      shift || true
      echo "パッケージ一覧を更新しています..."
      ${vrcGet} update 2>/dev/null || true
      (
        cd "${projectsRoot}/$proj"
        if [ $# -eq 0 ]; then
          echo "追加するパッケージ ID を入力してください (例: com.vrchat.avatars)" >&2
          echo "パッケージ ID が分からない場合は空 Enter で ALCOM に切り替えます" >&2
          read -r -p "ID > " pkg
          if [ -z "$pkg" ]; then
            ALCOM
            exit 0
          fi
          ${vrcGet} install "$pkg"
        else
          ${vrcGet} install "$@"
        fi
      )
    }

    cmd_android() { unity-android-paths; }

    cmd_help() {
      cat <<'EOF'
unity - VRChat アバター制作ツール

使い方:
  unity                 TUI メニュー
  unity hub             Unity Hub を開く
  unity install [ver]   エディタをインストール (既定 2022.3.22f1)
  unity open [project]  プロジェクトを Unity で開く (未指定なら選択)
  unity alcom           ALCOM を開く
  unity new             ALCOM で新規プロジェクト作成
  unity vrc [project]   vrc-get で VCC パッケージ追加
  unity url [url]       unityhub:// URL を Hub に渡す (既定: クリップボード)
  unity android         Android パス設定を表示
EOF
    }

    cmd_menu() {
      local choice
      choice=$(${fzf} --prompt="unity> " <<'EOF'
Hub      Unity Hub を開く
Install  Unity Editor 2022.3.22f1 をインストール
Open     プロジェクトを開く
New      ALCOM で新規プロジェクト作成
Vrc      vrc-get で VCC パッケージ追加
Alcom    ALCOM を開く (パッケージ/GUI 管理)
Url      unityhub:// URL を Hub に渡す
Android  Android パス設定を表示
Help     ヘルプを表示
Exit     終了
EOF
    ) || exit 1
      case "''${choice%% *}" in
        Hub) cmd_hub ;;
        Install) cmd_install ;;
        Open) cmd_open ;;
        New) cmd_new ;;
        Vrc) cmd_vrc ;;
        Alcom) cmd_alcom ;;
        Url) cmd_url ;;
        Android) cmd_android ;;
        Help) cmd_help ;;
        *) exit 0 ;;
      esac
    }

    case "''${1:-}" in
      "") cmd_menu ;;
      hub) cmd_hub ;;
      install) shift; cmd_install "$@" ;;
      open) shift; cmd_open "$@" ;;
      alcom) cmd_alcom ;;
      new) cmd_new ;;
      vrc) shift; cmd_vrc "$@" ;;
      url) shift; cmd_url "$@" ;;
      android) cmd_android ;;
      help|-h|--help) cmd_help ;;
      *) echo "不明なコマンド: $1 (unity help で確認)" >&2; exit 1 ;;
    esac
  '';
in {
  # VRChat アバター制作環境 (Unity Hub + ALCOM + Android SDK/NDK/JDK)
  programs.vrchat-unity = {
    enable = true;
  };

  environment.systemPackages = [
    # Unity 制作の面倒な操作をまとめた TUI/CLI
    unityCli
    # vrc-get (ALCOM の CLI 基盤) を unity vrc から使う
    pkgs.vrc-get
    # Unity Hub を FHS 環境経由でランチャー (drun) から起動できるようにする
    (pkgs.makeDesktopItem {
      name = "unity-hub";
      desktopName = "Unity Hub";
      comment = "Unity Hub (via unity-fhs-env)";
      exec = "unityhub-shell -c unityhub";
      icon = "unityhub";
      categories = [ "Development" ];
      startupNotify = false;
    })
  ];
}