# 普通の Linux 向けバイナリを NixOS でそのまま実行できるようにする (spring-b550m-pro4 / spring-t14-gen6、2026-11-16)。
# - nix-ld: /lib64/ld-linux-x86-64.so.2 に汎用ローダを置き、下の libraries を
#   NIX_LD_LIBRARY_PATH で見せる。ダウンロードしたバイナリ / AppImage (fuse) /
#   Unity Editor (~/Unity/Hub/Editor/*/Editor/Unity) 等を FHS ラッパー無しで直接起動できる
# - envfs: /bin と /usr/bin を FUSE で PATH から解決し、`#!/bin/bash` や `#!/usr/bin/env python3`
#   の外部スクリプト (Unity 同梱の Android ツール等) がそのまま動く
# 足りないライブラリで落ちたら (`error while loading shared libraries: libXXX.so`) ここに足す。
# Unity は従来どおり Hub の FHS 経由 (modules/unity.nix) でも動く。こちらは直接実行用の保険
#
# 下の libraries に無いライブラリが要るバイナリは nix-alien で「必要な分だけ取ってきて」動かす:
#   nix-alien ./app [-- args]      不足 .so を ELF から洗い出し、nix-index DB で nixpkgs の
#                                  パッケージに解決 → それを含む FHS 環境で実行
#   nix-alien-ld ./app [-- args]   同じく解決したライブラリを NIX_LD_LIBRARY_PATH で渡して nix-ld で実行
#   nix-alien-find-libs ./app      解決結果 (パッケージ名) だけ表示 → 常用するならここに足す
# 解決結果は ~/.cache/nix-alien/<バイナリの絶対パス由来>/ にキャッシュされ、2 回目からは即起動。
# 候補が複数あるライブラリは fzf で選ぶ。DB は nix-alien 同梱の nix-index-database (週次更新、
# flake.lock の更新で新しくなる) なので nix-index のローカル生成は不要。
# ついでに同じ DB で comma: `, cowsay hi` のように未インストールのコマンドをその場で取ってきて実行
{
  inputs,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  environment.systemPackages = [
    inputs.nix-alien.packages.${system}.nix-alien
    inputs.nix-alien.inputs.nix-index-database.packages.${system}.comma-with-db
  ];

  services.envfs.enable = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # 基本 (C/C++ ランタイム・圧縮・暗号・ネットワーク)
      stdenv.cc.cc
      glibc
      zlib
      zstd
      xz
      bzip2
      libffi
      openssl
      curl
      krb5
      icu
      libuuid
      util-linux
      ncurses
      ncurses5
      libxml2
      expat
      systemdLibs
      dbus
      libsecret
      fuse # AppImage (type 2) 用の libfuse.so.2
      libusb1

      # GUI (X11 / Wayland / GTK)
      libx11
      libxcursor
      libxext
      libxi
      libxrandr
      libxrender
      libxcomposite
      libxdamage
      libxfixes
      libxscrnsaver
      libxcb
      libxtst
      libxshmfence
      libxkbcommon
      libice
      libsm
      wayland
      glib
      gtk3
      gdk-pixbuf
      cairo
      pango
      harfbuzz
      atk
      at-spi2-core
      fontconfig
      freetype
      libnotify
      cups
      nss
      nspr

      # GPU / 描画 (NVIDIA の GL/EGL/Vulkan は /run/opengl-driver から別途見える)
      libglvnd
      libGLU
      libdrm
      libgbm
      libva
      vulkan-loader
      SDL2

      # 音声
      alsa-lib
      libpulseaudio
      pipewire
    ];
  };
}
