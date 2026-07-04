{pkgs, ...}: {
  # Meta Quest 2 で VRChat を遊ぶための一式 (WiVRn + Monado + xrizer)。
  # モジュール本体は github:frost-1256/nixos-vrchat。
  programs.vrchat-quest = {
    enable = true;

    # Lunar Lake (Intel Arc / Xe2)。VA-API + H.265 HW エンコードに固定し、
    # intel-media-driver(iHD) と LIBVA_DRIVER_NAME=iHD を自動投入する。
    gpu.vendor = "intel";

    # 常時最大化は無効化する。これを true にすると起動時/resume 毎に governor・
    # platform_profile・iGPU クロックを performance へ強制 pin し、実行時トグル
    # (modules/perf-mode.nix / Waybar の custom/perf・highperf/balanced)を打ち消す。
    # 電源モードはトグルを唯一の真実として扱い、起動はバランス、VR 時に手動で high へ。
    # (Steam ゲームは gamemoderun %command% が governor を一時ブーストする)
    performanceMode.enable = false;

    # 接続時の WayVR 自動起動は無効化中。使いたくなったら下行を有効化する
    # (package 渡しで絶対パス化されるので PATH 問題は起きない)。
    # wivrn.autoLaunch = pkgs.wayvr;

    # Steam は modules/steam.nix で proton-ge 付きで設定済みなので
    # こちら側の Steam 設定は無効化して重複を避ける。
    steam.enable = false;

    # 既定の wayvr に加え、VA-API HW エンコードの検証用 vainfo を入れる。
    extraPackages = [
      pkgs.wayvr
      pkgs.libva-utils
    ];
  };

  # Unity/ALCOM でのアバター作業環境 (同じ nixos-vrchat flake の vrchat-unity)。
  # 旧 modules/unity-avatar.nix はこのモジュールへ移行済み。FHS ランチャー
  # (ALCOM / unity-fhs-env / unity-android-paths)・Android SDK/NDK/JDK・
  # Proton-GE はすべて既定で有効になる。
  programs.vrchat-unity.enable = true;

  # Lunar Lake (Xe2, xe ドライバ) で VA-API エンコーダのドライバを iHD に確定。
  # 自動検出に任せると取りこぼす事があるので明示する。
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  systemd.user.services.wivrn = {
    # wivrn-server 内のエンコーダにも確実に渡す。
    environment.LIBVA_DRIVER_NAME = "iHD";

    # ブート直後に wivrn.service が起動順レースで 9757 を掴み損ね
    # ("Address already in use") → 落ちる事があるので、自動で立て直す。
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
