{pkgs, ...}: {
    services = {
       displayManager.gdm.enable = true;
       desktopManager.gnome.enable = true;
       gnome.core-apps.enable = true;
    };
    programs.firefox.enable = true;
    #WM
    programs.hyprland.enable = true;
}
