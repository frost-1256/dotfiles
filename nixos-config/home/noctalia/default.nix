{
  programs.noctalia = {
    enable = true;

    systemd.enable = true;

    settings = import ./settings.nix;
  };
}
