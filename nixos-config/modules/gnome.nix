{pkgs, ...}: {
    services = {
       displayManager.gdm.enable = true;
       gnome.gnome-keyring.enable = false;
    };
    #WM
    programs.hyprland.enable = true;
}
