{
  programs.noctalia = {
    enable = true;

    systemd.enable = true;

    settings = import ./settings.nix;

    # Dracula カスタムパレット
    customPalettes = {
      Dracula = {
        dark = {
          mPrimary = "#BD93F9";           # Purple
          mOnPrimary = "#F8F8F2";         # Foreground
          mSecondary = "#6272A4";         # Muted
          mOnSecondary = "#F8F8F2";       # Foreground
          mTertiary = "#FF79C6";          # Pink
          mOnTertiary = "#F8F8F2";        # Foreground
          mError = "#FF5555";             # Red
          mOnError = "#F8F8F2";           # Foreground
          mSurface = "#21222C";           # Surface (bar/panel/menu bg)
          mOnSurface = "#F8F8F2";         # Foreground
          mSurfaceVariant = "#282A36";    # Background (popup/elevated)
          mOnSurfaceVariant = "#F8F8F2";  # Foreground
          mOutline = "#44475A";           # Surface Alt (border/separator)
          mShadow = "#000000";            # Black
          mHover = "#36384D";             # Hover Surface (派生)
          mOnHover = "#F8F8F2";           # Foreground
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
}
