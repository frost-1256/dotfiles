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
  # Hyprland 時代の名残。WM は Niri に移行済みのため system 側の Hyprland は
  # 入れない (closure 縮小・rebuild 高速化。fallback が要る時は戻す)。
  programs.hyprland.enable = false;
}
