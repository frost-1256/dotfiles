self: super: {
  floorp = super.callPackage ({ lib
  , stdenv
  , fetchurl
  , makeWrapper
  , autoPatchelfHook
  , gtk3
  , gdk-pixbuf
  , glib
  , cairo
  , pango
  , atk
  , freetype
  , fontconfig
  , dbus
  , alsa-lib
  , xorg
  }:
    stdenv.mkDerivation rec {
      pname = "floorp";
      version = "12.1.2";
      
      src = fetchurl {
        url = "https://github.com/Floorp-Projects/Floorp/releases/download/v${version}/floorp-linux-amd64.tar.xz";
        sha256 = "1c1172f848be9cbd93e68219c0979e3fd5efd6b7fa5439463f0abc849fef450f";
      };
      
      nativeBuildInputs = [ makeWrapper autoPatchelfHook ];
      
      # autoPatchelfHookが必要とする全ての依存関係を明示的に指定
      buildInputs = [
        gtk3
        gdk-pixbuf
        glib
        cairo
        pango
        atk
        freetype
        fontconfig
        dbus
        alsa-lib
        stdenv.cc.cc.lib  # libstdc++.so.6, libgcc_s.so.1
      ] ++ (with xorg; [
        libX11
        libXcomposite
        libXdamage
        libXext
        libXfixes
        libXrandr
        libXrender
        libXcursor
        libXi
        libxcb
        libxcbutil
      ]);
      
      dontBuild = true;
      dontConfigure = true;
      dontStrip = true;
      
      installPhase = ''
        mkdir -p $out/lib/floorp
        tar -xf $src --strip-components=1 -C $out/lib/floorp
        
        mkdir -p $out/bin
        makeWrapper $out/lib/floorp/floorp $out/bin/floorp
        
        mkdir -p $out/share/applications
        cat > $out/share/applications/floorp.desktop << EOF
[Desktop Entry]
Name=Floorp
Comment=A Firefox-based privacy-focused web browser
Exec=$out/bin/floorp %U
Terminal=false
Type=Application
Icon=$out/lib/floorp/browser/chrome/icons/default/default128.png
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
EOF
      '';
      
      meta = with lib; {
        description = "A Firefox-based web browser with privacy enhancements";
        homepage = "https://floorp.app/";
        platforms = platforms.linux;
        license = licenses.mpl20;
      };
    }
  ) {};
}
