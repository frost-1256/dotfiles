# modules/perf-mode.nix
# 電源モードの実行時切り替えを一手に引き受ける一式。
#
# ・governor / Intel iGPU 最低クロックを、再ビルド無しで toggle できるようにする。
#   platform_profile は ppd が管理するため perf-apply からは触らない。
# ・sysfs への書き込みは root が要るので、引数固定(high|balanced)の専用ヘルパ
#   perf-apply に対してだけ NOPASSWD sudo を許可する(スコープを最小化)。
# ・platform_profile/EPP は power-profiles-daemon(polkit, パスワード不要)に任せ、
#   perf-apply は governor と iGPU クロックの sysfs 書き込みだけを担当する。
# ・ppd のプロファイル(balanced / power-saver)でも低電力時にカクつかないよう、
#   power-tune が EPP / HWP dynamic boost を補正する(下の power-tune を参照)。
{ pkgs, ... }:
let
  username = "spring";
  ppd = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl";

  # 特権部分。$1 = high | balanced。sysfs への書き込みのみを行う(冪等)。
  perf-apply = pkgs.writeShellScriptBin "perf-apply" ''
    case "$1" in
      high)
        gov=performance; clock=rp0 ;;
      balanced)
        gov=powersave;   clock=rpe ;;
      *)
        echo "usage: perf-apply high|balanced" >&2; exit 2 ;;
    esac

    # platform_profile は書かない。ppd が GFileMonitor で監視しており、外部から
    # 書き換えると「ドライバが自力で切り替えた」と解釈して ActiveProfile を追随させる
    # (power-saver が balanced に化ける)。プロファイル変更は呼び出し側
    # (perf-toggle / highperf / balanced) の powerprofilesctl set に一本化する。
    for c in /sys/devices/system/cpu/cpu[0-9]*/cpufreq; do
      [ -w "$c/scaling_governor" ] && echo "$gov" > "$c/scaling_governor"
    done

    for card in /sys/class/drm/card[0-9]*; do
      # i915: rp0 は最低クロックを最大に固定、rpe はドライバ既定のまま解放する。
      # (rpn=100MHz まで下げると DVFS の立ち上がりが間に合わずカクつきの原因になる)
      if [ "$clock" = rp0 ] && [ -r "$card/gt_RP0_freq_mhz" ]; then
        rp0=$(cat "$card/gt_RP0_freq_mhz")
        [ -w "$card/gt_min_freq_mhz" ]   && echo "$rp0" > "$card/gt_min_freq_mhz"
        [ -w "$card/gt_boost_freq_mhz" ] && echo "$rp0" > "$card/gt_boost_freq_mhz"
      elif [ "$clock" = rpe ] && [ -r "$card/gt_RPe_freq_mhz" ]; then
        rpe=$(cat "$card/gt_RPe_freq_mhz")
        [ -w "$card/gt_min_freq_mhz" ] && echo "$rpe" > "$card/gt_min_freq_mhz"
      fi
      # xe ドライバ: tile/gt 配下の min_freq を rp0_freq(高性能) / rpe_freq(バランス) に合わせる。
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
  '';

  # Waybar 表示用。JSON(text/class/tooltip)を返し、状態でアイコン・色を変える。
  perf-status-icon = pkgs.writeShellScriptBin "perf-status-icon" ''
    if [ "$(${ppd} get 2>/dev/null)" = performance ]; then
      printf '{"text":"󰓅","class":"highperf","tooltip":"高性能モード (クリックでバランス)"}\n'
    else
      printf '{"text":"󰾅","class":"balanced","tooltip":"バランスモード (クリックで高性能)"}\n'
    fi
  '';

  # ppd のプロファイルに追随して「低電力でもカクつかない最低限」まで応答性を上げる。
  # root で動く(power-tune.service)。再ビルド不要。
  #
  # 実測(T14 Gen6 / Core Ultra 5 228V / Lunar Lake, P-core 固定・同一ワークロード):
  #           持続時間   3s アイドル後の初動
  #   performance      248ms   34ms
  #   balance_performance 264ms   60ms
  #   balance_power    452ms   91ms
  #   power            693ms   -      ← ppd の power-saver 既定値
  # ppd の power-saver は EPP=power を強制し、持続・初動ともに 2〜3 倍遅い
  # (Niri/Noctalia の 16.6ms/frame を落とす主因)。初動の遅さは体感で「ワンテンポ
  # 遅れる」になる。そこで power-saver の時だけ EPP を balance_performance へ
  # 書き戻す。省電力の主レバーである platform_profile=low-power の PL1=10W は
  # ppd に任せて温存する(持続消費の上限はそのまま)。
  #
  # platform_profile は絶対に触らない: ppd は /sys/firmware/acpi/platform_profile を
  # GFileMonitor で監視しており、外部から書き換えると「ドライバが自力で切り替えた」
  # と解釈して ActiveProfile を追随させる(power-saver → balanced に化ける)。
  # EPP は監視されていないため上書きしても安全。
  #
  # ppd は EPP を「プロファイル変更時 / AC・バッテリ切替時 / レジューム時」に
  # 書き戻すので、同じ 3 契機で再適用する(下の systemd 定義を参照)。
  power-tune = pkgs.writeShellScriptBin "power-tune" ''
    set -u

    # HWP dynamic boost: I/O 待ちから復帰した直後だけ最低 P-state を一時的に
    # 引き上げる機能。入力やフレーム待ち明けの初動のもたつきを消し、
    # 通常時は EPP のままなので消費電力への影響は軽微。
    boost=/sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost
    if [ -w "$boost" ] && [ "$(cat "$boost")" != 1 ]; then
      echo 1 > "$boost"
    fi

    [ "$(${ppd} get 2>/dev/null)" = power-saver ] || exit 0

    for c in /sys/devices/system/cpu/cpu[0-9]*/cpufreq; do
      pref="$c/energy_performance_preference"
      # perf-toggle で governor=performance の間は EPP 書き込みが EBUSY になる
      [ -w "$pref" ] || continue
      if [ "$(cat "$pref")" != balance_performance ]; then
        echo balance_performance > "$pref" 2>/dev/null || true
      fi
    done
    exit 0
  '';

  # AC 抜き差し・レジュームでは ppd が EPP を書き戻すが、その完了は UPower 経由で
  # 非同期に少し遅れて来る。実測(2026-10-05): udev 契機の即時再適用(12:36:23)の
  # 直後に ppd が EPP=power を書き戻し、レースに負けた。1 回では足りないので
  # 数秒おきに複数回再適用して確実に上書きする(冪等なので安価)。
  power-tune-delayed = pkgs.writeShellScript "power-tune-delayed" ''
    for delay in 1 2 4 8; do
      ${pkgs.coreutils}/bin/sleep "$delay"
      ${pkgs.systemd}/bin/systemctl --no-block restart power-tune.service
    done
  '';
in
{
  services.power-profiles-daemon.enable = true;

  environment.systemPackages = [
    perf-apply
    perf-toggle
    perf-status-icon
    power-tune
  ];

  # ppd が EPP を書き戻す 3 契機で power-tune を再実行する。

  # (1) プロファイル変更。ppd は state.ini を atomic rename で書き換えるため、
  #     ファイル単体ではなくディレクトリごと watch する(rename は IN_MOVED_TO)。
  #     activate(driver への EPP 書き込み)→ save_configuration(state.ini)の順なので、
  #     ここで書く EPP が ppd の値に勝つ。
  systemd.paths.power-tune = {
    description = "Watch power-profiles-daemon state for profile changes";
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathChanged = "/var/lib/power-profiles-daemon";
      PathModified = "/var/lib/power-profiles-daemon";
    };
  };

  systemd.services.power-tune = {
    description = "Re-apply EPP / HWP dynamic boost for power-profiles-daemon";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${power-tune}/bin/power-tune";
    };
  };

  # (2)(3) AC 抜き差し・レジュームでは ppd の EPP 書き戻しが非同期に遅れて来るため、
  # 遅延付きで複数回再適用する power-tune-delayed.service を使う(実装は上の let)。
  # AC の uevent(udev)とレジューム(suspend.target は復帰後に active)の両方から叩く。
  systemd.services.power-tune-delayed = {
    description = "Re-apply power tuning after AC change / resume (delayed, multi-pass)";
    after = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    wantedBy = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${power-tune-delayed}";
    };
  };

  # Mains(AC)の変化だけに絞る。BAT0 の容量更新などで無駄に走らせない。
  services.udev.extraRules = ''
    ACTION=="change", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_TYPE}=="Mains", RUN+="${pkgs.systemd}/bin/systemctl --no-block restart power-tune-delayed.service"
  '';

  # 引数固定の perf-apply にだけパスワード無しの sudo を許可する。
  security.sudo.extraRules = [
    {
      users = [ username ];
      commands = [
        {
          command = "${perf-apply}/bin/perf-apply";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
