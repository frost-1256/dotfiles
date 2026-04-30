{ config, pkgs, ... }:
{
  imports = [
    <home-manager/nixos>
  ];
  users.users.spring.isNormalUser = true;
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;  
  home-manager.users.spring = { pkgs, ... }: {
    home.packages = with pkgs; [
    ];

    home.stateVersion = "25.11";
  };
}
