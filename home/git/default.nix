# NixOS 用 (users/spring/home.nix) と portable 用 (home-portable.nix) で共通の git / gpg。
{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user.name = "spring";
      user.email = "harusan@spring-server.com";
    };
  };
  programs.gpg.enable = true;
}
