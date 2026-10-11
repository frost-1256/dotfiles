# nixpkgs から libdisplay-info_0_2 が削除されたことへの暫定互換レイヤ。
# niri-flake (sodiboo/niri-flake) は今も build.rs で libdisplay-info >= 0.1.0 < 0.3.0
# を要求し、Nix 側でも `assert version == "0.2.0"` しているため、
# 実体の 0.2.0 を自前でビルドして提供する。
# (0.4.0 に別名を付けるだけでは .pc のバージョンが通らずビルド失敗する)
# niri-flake 側が対応したら削除すること。
final: prev: {
  libdisplay-info_0_2 = final.stdenv.mkDerivation (finalAttrs: {
    pname = "libdisplay-info";
    version = "0.2.0";

    src = final.fetchFromGitLab {
      domain = "gitlab.freedesktop.org";
      owner = "emersion";
      repo = "libdisplay-info";
      rev = "${finalAttrs.version}";
      hash = "sha256-6xmWBrPHghjok43eIDGeshpUEQTuwWLXNHg7CnBUt3Q=";
    };

    nativeBuildInputs = [
      final.meson
      final.ninja
      final.pkg-config
      final.python3
      final.xmlto
      final.docbook_xsl
    ];
    buildInputs = [
      final.hwdata
      final.libdrm
    ];

    outputs = [
      "out"
      "dev"
    ];
    postPatch = ''
      patchShebangs --build tool
    '';
    mesonBuildType = "release";
    strictDeps = true;
  });
}
