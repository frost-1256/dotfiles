{username, ...}: {
  home = {
    inherit username;
    homeDirectory = "/home/${username}";

    stateVersion = "26.05";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
