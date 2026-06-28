{pkgs, ...}: {
  # Meta Quest 2 で VRChat を遊ぶための一式 (WiVRn + Monado + xrizer)。
  # モジュール本体は github:frost-1256/nixos-vrchat。
  programs.vrchat-quest = {
    enable = true;

    # Lunar Lake (Intel Arc / Xe2)。VA-API + H.265 HW エンコードに固定し、
    # intel-media-driver(iHD) と LIBVA_DRIVER_NAME=iHD を自動投入する。
    gpu.vendor = "intel";

    # 常時最大化: governor/EPP/platform_profile を performance に、
    # iGPU 最低クロックを最大(RP0)に固定。給電前提なので有効化。
    # (GameMode は既定 ON。Steam の起動オプションに `gamemoderun %command%` を)
    performanceMode.enable = true;

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
