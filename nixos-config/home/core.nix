{username, pkgs, ...}: {
  home = {
    inherit username;
    homeDirectory =
      if pkgs.stdenv.isDarwin
      then "/Users/${username}"
      else "/home/${username}";

    stateVersion = "26.11";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
