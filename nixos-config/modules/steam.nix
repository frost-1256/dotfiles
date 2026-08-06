{
  ...
}: {
  # Steam: デスクトップ用途のみ (VR 関連は入れない)
  programs.steam = {
    enable = true;
    gamescopeSession.enable = false;
  };
}
