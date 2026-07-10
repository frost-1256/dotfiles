{pkgs, ...}: {
    services = {
       displayManager.gdm.enable = true;
    };
    #WM
    programs.hyprland.enable = true;
}
