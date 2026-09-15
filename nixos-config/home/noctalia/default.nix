{ pkgs, ... }:
let
  # 起動時に NetworkManager より先に Noctalia が立ち上がると、WiFi ウィジェットが
  # disconnected のまま接続確立に追随できなくなる（v5.0.1 で確認）。
  # ログイン時点で既に connected なら何もしないでちらつきを防ぎ、
  # 未接続のときだけ接続確立を待って一度だけ noctalia を再同期する。
  wifiResync = pkgs.writeShellScript "noctalia-wifi-resync" ''
    set -eu
    export PATH="/run/current-system/sw/bin:$PATH"

    is_connected() {
      [ "$(nmcli -t -f STATE general status 2>/dev/null || true)" = "connected" ]
    }

    if is_connected; then
      exit 0
    fi

    for _ in $(seq 1 60); do
      sleep 2
      if is_connected; then
        systemctl --user restart noctalia.service
        exit 0
      fi
    done
  '';
in
{
  programs.noctalia = {
    enable = true;

    systemd.enable = true;

    settings = import ./settings.nix;

    # Dracula カスタムパレット
    customPalettes = {
      Dracula = {
        dark = {
          mPrimary = "#BD93F9"; # Purple
          mOnPrimary = "#F8F8F2"; # Foreground
          mSecondary = "#6272A4"; # Muted
          mOnSecondary = "#F8F8F2"; # Foreground
          mTertiary = "#FF79C6"; # Pink
          mOnTertiary = "#F8F8F2"; # Foreground
          mError = "#FF5555"; # Red
          mOnError = "#F8F8F2"; # Foreground
          mSurface = "#21222C"; # Surface (bar/panel/menu bg)
          mOnSurface = "#F8F8F2"; # Foreground
          mSurfaceVariant = "#282A36"; # Background (popup/elevated)
          mOnSurfaceVariant = "#F8F8F2"; # Foreground
          mOutline = "#44475A"; # Surface Alt (border/separator)
          mShadow = "#000000"; # Black
          mHover = "#36384D"; # Hover Surface (派生)
          mOnHover = "#F8F8F2"; # Foreground
          terminal = {
            background = "#282A36";
            foreground = "#F8F8F2";
            cursor = "#F8F8F2";
            cursorText = "#282A36";
            selectionBg = "#44475A";
            selectionFg = "#F8F8F2";
            normal = {
              black = "#21222C";
              red = "#FF5555";
              green = "#50FA7B";
              yellow = "#F1FA8C";
              blue = "#BD93F9";
              magenta = "#FF79C6";
              cyan = "#8BE9FD";
              white = "#F8F8F2";
            };
            bright = {
              black = "#6272A4";
              red = "#FF5555";
              green = "#50FA7B";
              yellow = "#F1FA8C";
              blue = "#BD93F9";
              magenta = "#FF79C6";
              cyan = "#8BE9FD";
              white = "#FFFFFF";
            };
          };
        };
      };
    };
  };

  systemd.user.services.noctalia-wifi-resync = {
    Unit = {
      Description = "Sync Noctalia WiFi widget after NetworkManager connects";
      After = [ "noctalia.service" ];
      Wants = [ "noctalia.service" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${wifiResync}";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
