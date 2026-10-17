# modules/perf-mode.nix
# ppd (power-profiles-daemon) 周りの実行時補正を一手に引き受ける一式。
#
# ・高性能⇄バランスの手動トグル (perf-toggle/perf-apply/perf-status-icon) は
#   VR 専用に設計されていたため削除 (2026-10-17)。performance プロファイルが
#   要る時は `powerprofilesctl set performance` を直接叩けば足りる。
# ・ppd のプロファイル (balanced / power-saver) でも低電力時にカクつかないよう、
#   power-tune が EPP / HWP dynamic boost を補正する (下の power-tune を参照)。
#   platform_profile/EPP の本来の管理者は ppd。perf-mode はそれに追随するだけ。
{ pkgs, ... }:
let
  ppd = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl";

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

    # ppd 未起動の起動直後は D-Bus 呼び出しが固まるため timeout 付き
    # (素の powerprofilesctl get が約50秒ブロックし boot 完了を引き留めていた)。
    [ "$(${pkgs.coreutils}/bin/timeout 5 ${ppd} get 2>/dev/null)" = power-saver ] || exit 0

    for c in /sys/devices/system/cpu/cpu[0-9]*/cpufreq; do
      pref="$c/energy_performance_preference"
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
    # multi-user.target の WantedBy に入れない: Type=oneshot は完了まで target 到達を
    # 引き留める。ppd は multi-user 到達後に起動するため、起動直後の powerprofilesctl が
    # D-Bus タイムアウト(約50秒)まで固まり userspace 68秒の主因になっていた。
    # 起動時は power-tune.path / udev / power-tune-delayed からの trigger で足りる。
    after = [ "power-profiles-daemon.service" ];
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "30s";
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
}
