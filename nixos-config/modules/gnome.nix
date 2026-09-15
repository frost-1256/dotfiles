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
  #WM
  programs.hyprland.enable = true;
}
