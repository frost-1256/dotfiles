# NixOS 上で Unity + ALCOM を動かし、VRChat アバターをアップロードするための一式。
#
# 元ネタ: NixOS で Unity を動かして VRChat アバターをアップロードする手順メモ。
# 主な詰まりどころと、このモジュールでの対処:
#   1. Unity Editor / ALCOM が libxml2.so.2 を要求するが NixOS は libxml2.so しか出さない
#        → FHS 環境内に libxml2.so.2 の互換 symlink を生やす (libxml2FakeAbi)。
#   2. UnityHub / Unity Editor が NixOS の非 FHS 構造で起動できない
#        → buildFHSEnv で /usr/lib にライブラリが並ぶ環境を作る (unity-fhs-env)。
#   3. ALCOM が NixOS 上で Unity を検出できない / 「Unity で開く」が動かない
#        → ALCOM ごと FHS 環境内で起動する (`unity-fhs-env alcom`)。
#   4. Linux VRChat SDK Patch が Proton / VRChat クライアントのパスを要求する
#        → Proton-GE を固定パス (/etc/compatibilitytools.d/Proton-GE) で提供する。
#
# GPU Offloading (amd-run 等) はこのホストが単一 iGPU (Intel Lunar Lake) のため不要。
# dGPU を積んだ機種に移す場合のみ、別途ラッパースクリプトを足すこと。
#
# 使い方の例:
#   # UnityHub を FHS 内で起動 (元記事の `unityhub-shell` 互換)
#   unityhub-shell -c "unityhub"
#   # 指定バージョンの Unity Editor をインストール
#   unityhub-shell -c "unityhub unityhub://2022.3.22f1/887be4894c44"
#   # ALCOM を FHS 内で起動 (Unity 検出/「Unity で開く」を効かせるならこちら)
#   unity-fhs-env alcom
#   # Unity Editor を直接起動 (ALCOM で作ったプロジェクトを開く)
#   unity-fhs-env ~/Applications/.../Editor/2022.3.22f1/Editor/Unity \
#     -projectpath ~/Projects/VRChat/<ProjectName>
#
# ALCOM 側でやること (宣言的に書けないので手動):
#   - リポジトリ追加: https://befuddledlabs.github.io/LinuxVRChatSDKPatch/index.json
#   - プロジェクトに "Linux VRChat SDK Patch Base" / "...Avatar" を追加
#   - SDK Control Panel で Proton -> /etc/compatibilitytools.d/Proton-GE を指定
#   ※ 本パッチは VRChat の利用規約に反する可能性あり。利用は自己責任。
#
# 注意 (noexec):
#   アバタープロジェクトは noexec の付いた fs に置かないこと
#   (シェーダーコンパイル失敗 / VR でアバターが左右分裂する等の症状)。
#   確認: findmnt -no OPTIONS <project-dir>   推奨: ~/Projects/VRChat/<Name>
{
  lib,
  pkgs,
  ...
}: let
  # Unity Editor / ALCOM が要求する libxml2.so.2 を FHS 内に生やすための互換 ABI。
  # NixOS の libxml2 は libxml2.so しか出さないため symlink で埋める。
  libxml2FakeAbi = pkgs.runCommand "libxml2-fake-abi" {} ''
    mkdir -p $out/lib
    ln -s "${lib.getLib pkgs.libxml2}/lib/libxml2.so" $out/lib/libxml2.so.2
  '';

  # Unity / ALCOM 実行用 FHS 環境。
  # 引数があればそれを FHS 内で実行し、無ければ対話シェルに入る。
  unityFhsEnv = pkgs.buildFHSEnv {
    name = "unity-fhs-env";

    runScript = pkgs.writeShellScript "unity-fhs-run" ''
      # FHS 内 /usr/lib に置いた libxml2.so.2 を Unity Editor に確実に見せる。
      export LD_LIBRARY_PATH="/usr/lib:/usr/lib32''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      if [ "$#" -eq 0 ]; then
        exec ${pkgs.bashInteractive}/bin/bash
      fi
      exec "$@"
    '';

    targetPkgs = p:
      with p; [
        unityhub
        alcom
        xdg-utils
        gsettings-desktop-schemas
        hicolor-icon-theme
      ];

    multiPkgs = p:
      with p; [
        # 先頭で /usr/lib/libxml2.so.2 を確保する (元記事の workaround)。
        libxml2FakeAbi

        # 元記事の最小依存セット。
        gtk3
        glib
        libglvnd
        libxml2
        vulkan-loader
        wayland
        zlib
        libx11
        libxcursor
        libxext
        libxi
        libxrandr
        libxrender

        # Unity Editor が追加で要求しがちな依存 (起動失敗を避けるため明示)。
        nss
        nspr
        alsa-lib
        cups
        dbus
        expat
        fontconfig
        freetype
        libdrm
        libnotify
        libpulseaudio
        libuuid
        libxkbcommon
        atk
        at-spi2-atk
        at-spi2-core
        cairo
        gdk-pixbuf
        pango
        libxcomposite
        libxdamage
        libxfixes
        libxscrnsaver
        libxcb
        libxtst
      ];
  };

  # 元記事の `unityhub-shell -c "..."` 互換ラッパー。
  # `unity-fhs-env bash "$@"` に委譲するので `-c "..."` がそのまま使える。
  unityhubShell = pkgs.writeShellScriptBin "unityhub-shell" ''
    exec ${unityFhsEnv}/bin/unity-fhs-env bash "$@"
  '';
in {
  environment.systemPackages = [
    unityFhsEnv # FHS 環境 (Unity Editor / ALCOM をこの中で起動)
    unityhubShell # 元記事互換の `unityhub-shell -c "..."`
    pkgs.alcom # ALCOM 単体 (検出が効くなら FHS なしでも起動できる)
  ];

  # Linux VRChat SDK Patch から参照する Proton-GE を固定パスで提供する。
  # SDK Control Panel の Proton -> Installed Proton Path にこのパスを指定する:
  #   /etc/compatibilitytools.d/Proton-GE
  environment.etc."compatibilitytools.d/Proton-GE".source =
    pkgs.proton-ge-bin.steamcompattool;
}
