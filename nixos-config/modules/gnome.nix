{pkgs, lib, ...}: {
    services = {
       displayManager.gdm.enable = true;
       gnome.gnome-keyring.enable = lib.mkForce false;
    };
    #WM
    programs.hyprland.enable = true;
}
