{ username, ... }:
{
  # パスワード認証の SSH サーバー。
  # パスワードが未設定だとログインできないので、必要なら `passwd` で設定する
  # (users.mutableUsers は既定の true のままなので /etc/shadow に保持される)。
  services.openssh = {
    enable = true;
    # socket activation を使うと sshd.service を止めても待受が残るため無効。
    # 「off = 22 番ポートが閉じる」を成立させる。
    startWhenNeeded = false;
    openFirewall = true; # TCP 22
    settings = {
      PasswordAuthentication = true;
      # PAM 経由の対話認証は使わない (パスワードは直接検証)。
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      # パスワード総当たりのコストを上げる
      MaxAuthTries = 4;
      LoginGraceTime = 20;
    };
  };

  # ssh-on / ssh-off / ssh-toggle 用。systemctl 全体ではなく
  # sshd の start/stop/restart だけをパスワード無しで許可する。
  security.sudo.extraRules = [
    {
      users = [ username ];
      commands =
        map
          (verb: {
            command = "/run/current-system/sw/bin/systemctl ${verb} sshd";
            options = [ "NOPASSWD" ];
          })
          [
            "start"
            "stop"
            "restart"
          ];
    }
  ];
}
