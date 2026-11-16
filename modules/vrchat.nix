# VRChat を Quest で遊ぶ一式 (spring-b550m-pro4 専用。2026-11-16 に RTX 3080 化で復活)。
# 経路: VRChat (Steam / Proton) → xrizer (OpenVR→OpenXR) → WiVRn + Monado → Quest (Wi-Fi)。
# SteamVR は使わない。本体は flake input `nixos-vrchat` の programs.vrchat-quest。
# Unity / ALCOM 制作環境は modules/unity.nix (programs.vrchat-unity)。
{
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.nixos-vrchat.nixosModules.default ];

  programs.vrchat-quest = {
    enable = true;
    # WiVRn のエンコーダを NVENC (h265) に固定。Quest 2 は AV1 をハードデコードできない
    gpu.vendor = "nvidia";
    # 常時最大化 (governor / EPP / platform_profile / Intel iGPU クロック) は host 側で
    # governor=performance 済み。Intel 向けの処理も混ざるので使わない
    performanceMode.enable = false;

    # --- シームレス化 (2026-11-16。WiVRn 26.9 前提) ---
    # openvrpaths.vrpath はモジュールにログイン時に静的に書かせず WiVRn に任せる。
    # WiVRn (0.23 以降) は接続中だけ OpenVR ランタイムを自分の xrizer / OpenComposite に
    # 向け、切断時に戻す (nixpkgs の wivrn は ovrCompatSearchPaths に両方を持つ)。
    # 静的ファイルと二重管理になると、フルトラ用に WiVRn ダッシュボードで
    # OpenComposite へ切り替えても次のログインで xrizer に戻されてしまう。
    openvr.autoConfigure = false;
    # 接続した瞬間に WayVR (VR 内デスクトップ / オーバーレイ) を自動起動する。
    # VRChat はヘッドセット内の WiVRn ランチャー (Steam のゲーム一覧が出る。
    # services.wivrn.steam.enable で Steam が server の PATH に入っている) か WayVR から起動する
    wivrn.autoLaunch = pkgs.wayvr;
  };

  # 罠: nixpkgs の wivrn は既定 cudaSupport = config.cudaSupport (= false) で、
  # NVENC 無しでビルドされる。gpu.vendor = "nvidia" で encoder を nvenc に固定すると
  # エンコーダが見つからず失敗するので、NVENC 付きでビルドし直す。
  # cudaSupport で増えるのは WIVRN_USE_NVENC と autoAddDriverRunpath だけで、
  # CUDA ツールキットは引かない (libnvidia-encode はドライバから実行時に dlopen)。
  # unfree の cuda 系を引かないので軽いローカルビルドで済む。
  services.wivrn.package = pkgs.wivrn.override { cudaSupport = true; };

  # VRChat 用 Proton。モジュールが入れる GE-Proton (proton-ge-bin) に加えて、
  # VR ソーシャルゲーム向けパッチ入りの GE-Proton RTSP を入れる
  # (動画プレイヤーの RTSP / AVPro 等。Steam の互換ツール一覧で選ぶ)。
  programs.steam.extraCompatPackages = [ pkgs.proton-rtsp-bin ];

  environment.systemPackages = with pkgs; [
    # VRChat のフレンド・ワールド履歴管理
    vrcx
    # 起動オプションに `gamemoderun %command%` を付けると VRChat 起動中だけ GameMode が効く
    # (gamemode 自体はモジュールが有効化)
    protontricks
  ];
}
