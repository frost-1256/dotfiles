# modules/perf-mode.nix
# 電源モード(高性能/バランス)の実行時切り替えを Waybar から行うための一式。
#
# ・modules/vrchat.nix の performanceMode と同じノブ(governor / platform_profile /
#   Intel iGPU 最低クロック)を、再ビルド無しで toggle できるようにする。
# ・sysfs への書き込みは root が要るので、引数固定(high|balanced)の専用ヘルパ
#   perf-apply に対してだけ NOPASSWD sudo を許可する(スコープを最小化)。
# ・platform_profile/EPP は power-profiles-daemon(polkit, パスワード不要)に任せ、
#   perf-apply は governor と iGPU クロックの sysfs 書き込みだけを担当する。
# ・Waybar の custom/perf は perf-status-icon を exec、クリックで perf-toggle、
#   signal=9(SIGRTMIN+9)で即時更新する(lid.nix と同じ作法)。
{ pkgs, ... }:
let
  username = "spring";
  ppd = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl";

  # 特権部分。$1 = high | balanced。sysfs への書き込みのみを行う(冪等)。
  perf-apply = pkgs.writeShellScriptBin "perf-apply" ''
    case "$1" in
      high)
        gov=performance; profile=performance; clock=rp0 ;;
      balanced)
        gov=powersave;   profile=balanced;    clock=rpn ;;
      *)
        echo "usage: perf-apply high|balanced" >&2; exit 2 ;;
    esac

    for c in /sys/devices/system/cpu/cpu[0-9]*/cpufreq; do
      [ -w "$c/scaling_governor" ] && echo "$gov" > "$c/scaling_governor"
    done
    [ -w /sys/firmware/acpi/platform_profile ] && echo "$profile" > /sys/firmware/acpi/platform_profile

    for card in /sys/class/drm/card[0-9]*; do
      # i915: gt_RP0(最大) / gt_RPn(最小) を最低クロックに固定/解放する。
      if [ "$clock" = rp0 ] && [ -r "$card/gt_RP0_freq_mhz" ]; then
        rp0=$(cat "$card/gt_RP0_freq_mhz")
        [ -w "$card/gt_min_freq_mhz" ]   && echo "$rp0" > "$card/gt_min_freq_mhz"
        [ -w "$card/gt_boost_freq_mhz" ] && echo "$rp0" > "$card/gt_boost_freq_mhz"
      elif [ "$clock" = rpn ] && [ -r "$card/gt_RPn_freq_mhz" ]; then
        rpn=$(cat "$card/gt_RPn_freq_mhz")
        [ -w "$card/gt_min_freq_mhz" ] && echo "$rpn" > "$card/gt_min_freq_mhz"
      fi
      # xe ドライバ: tile/gt 配下の min_freq を rp0_freq/rpn_freq に合わせる。
      for gt in "$card"/device/tile*/gt*/freq0; do
        src="$gt/''${clock}_freq"
        [ -r "$src" ] && [ -w "$gt/min_freq" ] && echo "$(cat "$src")" > "$gt/min_freq"
      done
    done
  '';

  # 現在のプロファイルを見て高性能⇄バランスを切り替える(CLI / Waybar クリック)。
  #
  # 順序が重要: intel_pstate では scaling_governor=performance の間 EPP
  # (energy_performance_preference)への書き込みが EBUSY になり、
  # powerprofilesctl set が失敗する(→ ppd が performance のまま=アイコンが更新されない)。
  # そのため balanced へ落とす時は「先に perf-apply で governor を powersave へ解放」→
  # 「その後 powerprofilesctl set balanced」の順にする。高性能へ上げる時は逆に、
  # 先に powerprofilesctl set performance(EPP 書き込み)→ その後 governor/iGPU を pin。
  perf-toggle = pkgs.writeShellScriptBin "perf-toggle" ''
    if [ "$(${ppd} get 2>/dev/null)" = performance ]; then
      sudo ${perf-apply}/bin/perf-apply balanced
      ${ppd} set balanced
      ${pkgs.libnotify}/bin/notify-send -a Perf -i battery "電源モード" "バランス"
    else
      ${ppd} set performance
      sudo ${perf-apply}/bin/perf-apply high
      ${pkgs.libnotify}/bin/notify-send -a Perf -i battery-charging "電源モード" "高性能 (給電時 VR 用)"
    fi
    # Waybar の custom/perf を即時更新する(signal=9 → SIGRTMIN+9)。
    ${pkgs.procps}/bin/pkill -RTMIN+9 waybar 2>/dev/null || true
  '';

  # Waybar 表示用。JSON(text/class/tooltip)を返し、状態でアイコン・色を変える。
  perf-status-icon = pkgs.writeShellScriptBin "perf-status-icon" ''
    if [ "$(${ppd} get 2>/dev/null)" = performance ]; then
      printf '{"text":"󰓅","class":"highperf","tooltip":"高性能モード (クリックでバランス)"}\n'
    else
      printf '{"text":"󰾅","class":"balanced","tooltip":"バランスモード (クリックで高性能)"}\n'
    fi
  '';
in {
  environment.systemPackages = [ perf-apply perf-toggle perf-status-icon ];

  # 引数固定の perf-apply にだけパスワード無しの sudo を許可する。
  security.sudo.extraRules = [{
    users = [ username ];
    commands = [{
      command = "${perf-apply}/bin/perf-apply";
      options = [ "NOPASSWD" ];
    }];
  }];
}
