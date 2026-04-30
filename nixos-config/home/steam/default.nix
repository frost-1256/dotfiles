{pkgs, ...}: {
  home.packages = with pkgs; [
    protontricks
    steam-run
    mangohud
  ];

  home.sessionVariables = {
    # Proton GE などを手動配置するときの標準的な置き場所。
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
  };
}
