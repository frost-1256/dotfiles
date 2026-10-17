# GDM (greeter) の背景差し替え。
#
# 背景: GDM 50.x のグリーター (loginDialog) は画像レイヤーを持たず、画面全体は
# gnome-shell-theme.gresource 内の CSS (#lockDialogGroup / .screen-shield-background)
# の背景色がそのまま出る。
#
# 方式: gnome-shell を overrideAttrs し、postInstall で
# share/gnome-shell/gnome-shell-theme.gresource を再パッケージして自 $out に
# 置き換える。
# - 既存 gresource から CSS 3種 (dark/light/high-contrast) と SVG/pad-osd を展開
# - `#lockDialogGroup` ルールに背景画像指定を注入 (3 CSS 各 1 箇所のみ。50.4 で
#   検証済み。既存 background-color は画像の下層に隠れるためそのまま)
# - 画像は CSS から resource:/// 参照するため gresource.xml の file エントリに
#   追加が必須 → build 時に XML や未同梱ファイルを生成・展開する
#
# 注意: libshell-18.so はビルド時に焼かれた datadir ($out/share) 直下の
# gnome-shell-theme.gresource を名前で解決する。別 out への cp -r +
# chmod だけの runCommand では ExecStart / libshell が元 store パスを
# 指し続けて背景が効かなかった (2026-10-17 実測、gen376 で確認)。
# overrideAttrs の postInstall なら $out が自パッケージに一致するので
# unit の ExecStart も採られ、正しく差し替わる。

{
  lib,
  gnome-shell,
  boot-wallpaper,
}:
let
  injectCss = css: ''
    sed -i 's|^#lockDialogGroup {|#lockDialogGroup {\n  background-image: url("resource:///org/gnome/shell/theme/gdm-background.png");\n  background-size: cover;\n  background-position: center;\n|' ${css}
  '';

  gdmBgPostInstall = ''
        # --- GDM 背景画像の注入 ---
        mkdir theme
        cd theme

        R=$out/share/gnome-shell/gnome-shell-theme.gresource

        # 1. 既存 gresource から CSS 3種 + SVG/pad-osd を展開
        for f in \
          gnome-shell-dark.css gnome-shell-light.css gnome-shell-high-contrast.css \
          calendar-today.svg calendar-today-light.svg gnome-shell-start.svg \
          pad-osd.css workspace-placeholder.svg
        do
          gresource extract $R /org/gnome/shell/theme/$f > $f
        done

        # 2. CSS に画像を注入
        ${lib.concatMapStrings injectCss [
          "gnome-shell-dark.css"
          "gnome-shell-light.css"
          "gnome-shell-high-contrast.css"
        ]}

        # 3. 背景画像をコピー
        cp ${boot-wallpaper} gdm-background.png

        # 4. gresource.xml を再生成 (upstream data/gnome-shell-theme.gresource.xml に画像 File を追加)
        cat > gdm-theme.gresource.xml <<XML
    <?xml version="1.0" encoding="UTF-8"?>
    <gresources>
      <gresource prefix="/org/gnome/shell/theme">
        <file>calendar-today.svg</file>
        <file>calendar-today-light.svg</file>
        <file>gnome-shell-dark.css</file>
        <file>gnome-shell-light.css</file>
        <file>gnome-shell-high-contrast.css</file>
        <file>gnome-shell-start.svg</file>
        <file>pad-osd.css</file>
        <file>workspace-placeholder.svg</file>
        <file>gdm-background.png</file>
      </gresource>
    </gresources>
    XML

        # 5. 再パッケージして元 gresource と差し替え
        glib-compile-resources --sourcedir=. \
          --target=gdm-theme.gresource \
          gdm-theme.gresource.xml
        mv gdm-theme.gresource $R
        cd ..
        rm -rf theme
  '';
in
gnome-shell.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + gdmBgPostInstall;
  # 独自生成なので区別可能に (nixpkgs 側の name に gdm-bg を足す)。
  name = old.name or "${old.pname}-gdm-bg";
})
