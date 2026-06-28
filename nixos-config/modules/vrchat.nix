{...}: {
  # Meta Quest 2 で VRChat を遊ぶための一式 (WiVRn + Monado + xrizer)。
  # モジュール本体は github:frost-1256/nixos-vrchat。
  programs.vrchat-quest = {
    enable = true;

    # Steam は modules/steam.nix で proton-ge 付きで設定済みなので
    # こちら側の Steam 設定は無効化して重複を避ける。
    steam.enable = false;
  };

  # ブート直後に wivrn.service が起動順レースで 9757 を掴み損ね
  # ("Address already in use") → 落ちる事があるので、自動で立て直す。
  systemd.user.services.wivrn.serviceConfig = {
    Restart = "on-failure";
    RestartSec = 3;
  };
}
