final: prev: let
  # コマンドライン引数（GPU支援あり）
  gpuArgs = toString [
    "--enable-accelerated-mjpeg-decode"
    "--enable-accelerated-video"
    "--enable-zero-copy"
    "--use-gl=desktop"
    "--disable-features=UseOzonePlatform"
    "--enable-features=VaapiVideoDecoder"
    "--ignore-gpu-blacklist"
    "--enable-native-gpu-memory-buffers"
    "--enable-gpu-rasterization"
  ];

  mkDiscordWrapper = args: final.runCommand "discord-gpu-wrapper-${prev.discord.version}" {
    buildInputs = [ final.makeWrapper ];
  } ''
    mkdir -p $out/bin $out/share/applications $out/share/icons/hicolor/256x256/apps

    # 元の実行ファイルをコピー
    cp ${prev.discord}/bin/discord $out/bin/discord-original

    # ラッパースクリプト作成
    makeWrapper $out/bin/discord-original $out/bin/discord \
      --add-flags "${args}"

    # .desktop ファイル（完全自作）
    cat > $out/share/applications/discord-gpu.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Discord(Modded)
Comment=All-in-one voice and text chat for gamers that's free, secure, and works on both your desktop and phone.
Exec=$out/bin/discord --enable-accelerated-mjpeg-decode --enable-accelerated-video --enable-zero-copy --use-gl=desktop --disable-features=UseOzonePlatform --enable-features=VaapiVideoDecoder --ignore-gpu-blacklist --enable-native-gpu-memory-buffers --enable-gpu-rasterization
Icon=discord
Terminal=false
Categories=Network;InstantMessaging;
EOF

    # アイコンもコピー（rofi 用）
    cp ${prev.discord}/share/icons/hicolor/256x256/apps/discord.png \
       $out/share/icons/hicolor/256x256/apps/discord.png || true
  '';

in {
  discord-gpu = mkDiscordWrapper gpuArgs;
}

