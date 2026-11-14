# 指紋認証 (ThinkPad T14 Gen6 専用)。センサは USB の Synaptics 06cb:00f9 (TOD goodix driver)。
# 04F3:3195 はタッチパッド側 (hid-multitouch から外して hidraw 経由で TOD に渡す)。
# 自動復旧の設計は AGENTS.md「電源プロファイル周」の fprintd 項を参照。
{ pkgs, ... }:
{
  security.pam.services.polkit-1.fprintAuth = true;

  services.fprintd = {
    enable = true;
    tod.enable = true;
    tod.driver = pkgs.libfprint-2-tod1-goodix;
  };
  # fprintd 自動復旧。指紋センサは USB の Synaptics 06cb:00f9 (TOD goodix driver)。
  # resume で USB デバイスが黙って切れ、fprintd は死んだ handle を握ったまま claim を保持する。
  # 以後 Claim は "already claimed" で全滅し、client の Release 時に transfer timed out →
  # fprint_device_release で SIGSEGV。endpoint halt は restart では消えず USB 再列挙が要る。
  # さらにこのセンサは resume 毎に degraded 化する (列挙できるのに NoEnrolledPrints /
  # transfer failed。restart 無効・unbind/bind のみ有効。2026-10-07 00:02/00:11 実測)。
  # resume 後に unit から restart すると noctalia の再 arm (PrepareForSleep(false) の
  # 約 14ms 後) と衝突して NoReply になり同セッション permanent dead
  # (2026-10-06 23:37:51 実測) のため、D-Bus activation 待ちで直列化する:
  # 睡眠前に止め (presuspend)、resume 後の初回利用時に ExecStartPre が USB 再列挙して
  # から起動する。呼び出し側はバスが最大 25 秒待つので競合しない。通常の idle 復帰は
  # stamp 判定で素通しする。
  systemd.services.fprintd.serviceConfig = {
    Restart = "on-failure";
    RestartSec = "2s";
    # 上流 unit は ProtectSystem=strict + ProtectKernelTunables で /sys が
    # read-only のため、ExecStartPre からの unbind/bind には例外が要る
    # (無いと Read-only file system で再列挙が黙って死ぬ。00:42:09 実測)。
    ReadWritePaths = [
      "/sys/bus/usb/drivers/usb"
      "/sys/bus/usb/devices"
    ];
    ExecStartPre = [
      "${pkgs.writeShellScript "fprintd-usb-cycle" ''
        set -u
        pre=/run/fprintd-presuspend-stamp
        cyc=/run/fprintd-usb-cycled
        force=/run/fprintd-force-cycle
        need=0
        # 睡眠を跨いだ直後の初回起動だけ再列挙する (通常の idle 復帰は素通し)。
        if [ -e "$pre" ] && { [ ! -e "$cyc" ] || [ "$pre" -nt "$cyc" ]; }; then need=1; fi
        # guard 経由の強制再列挙 (crash 後の stall 用)。
        if [ -e "$force" ]; then rm -f "$force"; need=1; fi
        [ "$need" = 0 ] && exit 0
        cycled=0
        for d in /sys/bus/usb/devices/*; do
          [ -f "$d/idVendor" ] || continue
          [ "$(cat "$d/idVendor")" = 06cb ] || continue
          [ "$(cat "$d/idProduct")" = 00f9 ] || continue
          dev=''${d##*/}
          echo "fprintd-usb-cycle: re-enumerating USB device $dev"
          if echo "$dev" > /sys/bus/usb/drivers/usb/unbind; then
            ${pkgs.coreutils}/bin/sleep 1
            if echo "$dev" > /sys/bus/usb/drivers/usb/bind; then
              cycled=1
            else
              echo "fprintd-usb-cycle: bind failed for $dev" >&2
            fi
          else
            echo "fprintd-usb-cycle: unbind failed for $dev (sandbox?)" >&2
          fi
          # bind 直後の probe は Entity not found で Ignoring device になる
          # (00:14:40 実測)。settle してから daemon 本体を起動する。
          ${pkgs.coreutils}/bin/sleep 2
          # udev の add rule が再適用されるはずだが、念のため明示的に常時給電へ。
          [ -w "$d/power/control" ] && echo on > "$d/power/control"
        done
        # デバイス不在でも起動は通す (daemon が空列挙を正直に返す)。
        # stamp は実際に回せた時だけ (失敗時は次回起動で再試行する)。
        [ "$cycled" = 1 ] && ${pkgs.coreutils}/bin/touch "$cyc"
      ''}"
    ];
  };
  # 睡眠前 stop (sleep.target の Before で実 sleep より確定的に先)。
  # 停止自体は 30 秒 idle 終了と同等で無害。stamp を残し resume 後初回起動の
  # 再列挙目印にする。
  systemd.services.fprintd-presuspend = {
    description = "Stop fprintd before sleep so no stale claim crosses suspend/resume";
    wantedBy = [ "sleep.target" ];
    before = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "15s";
      ExecStart = "${pkgs.writeShellScript "fprintd-presuspend" ''
        set -u
        ${pkgs.systemd}/bin/systemctl stop fprintd.service
        ${pkgs.coreutils}/bin/touch /run/fprintd-presuspend-stamp
      ''}";
    };
  };
  # guard からの復旧専用 (resume 契機では叩かない)。force stamp + restart のみで
  # USB 再列挙の実作業は ExecStartPre に一本化 (二重化しない)。
  systemd.services.fprintd-recover = {
    description = "Force USB re-enumeration and restart fprintd";
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "30s";
      ExecStart = "${pkgs.writeShellScript "fprintd-recover" ''
        set -u
        ctl=${pkgs.systemd}/bin/systemctl
        bus=${pkgs.systemd}/bin/busctl
        # fprintd が列挙している指紋デバイスの有無を見る。
        # stall 時は fprintd がデバイスを捨てるので空になる(empty = ao 0)。
        have_device() {
          out=$($bus --system call net.reactivated.Fprint /net/reactivated/Fprint/Manager \
            net.reactivated.Fprint.Manager GetDevices 2>/dev/null) || return 1
          case "$out" in
            *'ao 0'*) return 1 ;;
            *'/net/reactivated/Fprint/Device/'*) return 0 ;;
            *) return 1 ;;
          esac
        }
        ${pkgs.coreutils}/bin/touch /run/fprintd-force-cycle
        $ctl restart fprintd.service
        for _ in 1 2 3 4 5 6 7 8 9 10; do
          have_device && exit 0
          ${pkgs.coreutils}/bin/sleep 0.5
        done
        echo "fprintd-recover: device still missing after re-enumeration" >&2
        exit 1
      ''}";
    };
  };
  # ジャーナル監視 ("device was disconnected" / "transfer timed out" /
  # "transfer failed" / "code=dumped" / "Ignoring device")。passive に検知だけし、
  # 復旧は recover に一本化する。
  systemd.services.fprintd-guard = {
    description = "Watch fprintd journal and trigger fprintd-recover on device loss";
    wantedBy = [ "multi-user.target" ];
    after = [ "fprintd.service" ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "5s";
      ExecStart = "${pkgs.writeShellScript "fprintd-guard" ''
        set -u
        delay=10
        ${pkgs.systemd}/bin/journalctl -f -n0 -o cat -u fprintd |
        while IFS= read -r line; do
          case "$line" in
            *'device was disconnected'*|*'transfer timed out'*|*'transfer failed'*|*'Ignoring device due to initialization error'*|*'code=dumped'*)
              if ${pkgs.systemd}/bin/systemctl start --wait fprintd-recover.service; then
                delay=10
              else
                delay=$((delay * 3)); [ "$delay" -gt 300 ] && delay=300
              fi
              ${pkgs.coreutils}/bin/sleep "$delay"
              ;;
          esac
        done
      ''}";
    };
  };

  # Unbind fingerprint sensor from hid-multitouch so TOD driver can use it via hidraw
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="hid", DRIVER=="hid-multitouch", ATTRS{modalias}=="hid:b0018g0004v000004F3p00003195", RUN+="${pkgs.bash}/bin/sh -c 'echo $kernel > /sys/bus/hid/drivers/hid-multitouch/unbind'"
    # 指紋センサ (Synaptics 06cb:00f9) の USB autosuspend を無効化。
    # resume 後に endpoint stalled で初期化失敗する一因になるため常時給電にする。
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="06cb", ATTR{idProduct}=="00f9", ATTR{power/control}="on"
  '';
}
