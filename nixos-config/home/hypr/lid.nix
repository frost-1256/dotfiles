# modules/hypr/lid.nix
# ノートのフタ(Lid)を閉じたときにサスペンドするかを on/off できるトグル。
#
# ・logind 側の Lid 処理は host 設定で "ignore" にしてあり、Lid は Hyprland の
#   bindl(switch:Lid Switch)→ lid-action でのみ処理する(挙動を一本化)。
# ・lid-action はトグルの状態ファイルを見て、無効なら何もしない。
# ・状態ファイルは $XDG_RUNTIME_DIR に置くので、再起動・再ログインで
#   自動的に「サスペンド有効」へ戻る。
{ pkgs, ... }:
let
  stateFile = "$XDG_RUNTIME_DIR/lid-suspend-disabled";

  # Hyprland の Lid スイッチから呼ばれる本体。
  # トグルで無効化されているときは何もしない。
  # サスペンド前のロックは hypridle の before_sleep_cmd(loginctl lock-session)が担当する。
  lid-action = pkgs.writeShellScriptBin "lid-action" ''
    [ -e "${stateFile}" ] && exit 0
    systemctl suspend
  '';

  # フタ閉じサスペンドの有効/無効を切り替える(CLI / Waybar クリック)。
  lid-toggle = pkgs.writeShellScriptBin "lid-toggle" ''
    if [ -e "${stateFile}" ]; then
      rm -f "${stateFile}"
      ${pkgs.libnotify}/bin/notify-send -a Lid -i computer "フタ閉じサスペンド" "有効"
    else
      : > "${stateFile}"
      ${pkgs.libnotify}/bin/notify-send -a Lid -i computer "フタ閉じサスペンド" "無効 (フタを閉じても起きたまま)"
    fi
    # Waybar の custom/lid モジュールを即時更新する(signal=8 → SIGRTMIN+8)。
    ${pkgs.procps}/bin/pkill -RTMIN+8 waybar 2>/dev/null || true
  '';

  # Waybar 表示用。状態に応じてアイコンを出力する(󰒲=サスペンド有効 / 󰒳=無効)。
  lid-status = pkgs.writeShellScriptBin "lid-status" ''
    if [ -e "${stateFile}" ]; then
      printf '󰒳\n'
    else
      printf '󰒲\n'
    fi
  '';
in {
  home.packages = [ lid-action lid-toggle lid-status ];
}
