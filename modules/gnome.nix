{ ... }: {
  services = {
    displayManager.gdm.enable = true;
    # GVfs を起動して Nautilus で smb:// (SMB) を扱えるようにする
    gvfs.enable = true;
    gnome.gnome-keyring.enable = true;
    # gnome-keyring が gcr-ssh-agent を既定で有効化するが、
    # programs.ssh.startAgent と同時有効化できないため無効化
    gnome.gcr-ssh-agent.enable = false;
  };

  # GDM グリーターの背景画像。gdm-bg.nix が gnome-shell の
  # gnome-shell-theme.gresource を再パッケージして #lockDialogGroup に画像を敷く。
  # pkgs.gnome-shell を差し替え対象にするので、GDM モジュール内の参照も一緒に変わる。
  nixpkgs.overlays = [
    (final: prev: {
      gnome-shell = final.callPackage ../hosts/spring-t14-gen6/gdm-bg.nix {
        gnome-shell = prev.gnome-shell;
        boot-wallpaper = ../hosts/spring-t14-gen6/assets/boot-wallpaper.png;
      };
    })
  ];
  # Hyprland 時代の名残。WM は Niri に移行済みのため system 側の Hyprland は
  # 入れない (closure 縮小・rebuild 高速化。fallback が要る時は戻す)。
  programs.hyprland.enable = false;
}
