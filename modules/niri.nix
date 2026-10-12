{
  pkgs,
  inputs,
  config,
  ...
}:
{
  niri-flake.cache.enable = true;

  nixpkgs.overlays = [
    (import ../overlays/niri-compat.nix)
    inputs.niri.overlays.niri
  ];

  programs.niri.enable = true;
  programs.niri.package = pkgs.niri-unstable;

  # GDM 50 の gdm-wayland-session は .desktop の Exec (niri-session) を
  # PATH で解決するが、display-manager.service の PATH には gnome-session
  # しか入らないため "Unable to run session" で即落ちする (2026-10-12 実測)。
  # sessionPackages (XDG_DATA_DIRS) だけでは足りず bin の PATH 追加が要る。
  systemd.services.display-manager.path = [ config.programs.niri.package ];

  # defaultSession 未設定だと GDM が存在しない gnome-session を起動しようとして
  # 同じく "Unable to run session" で即落ちする (gnome 本体は未導入のため
  # user 側 PATH に gnome-session が無い)。niri を既定に固定する。
  services.displayManager.defaultSession = "niri";
}
