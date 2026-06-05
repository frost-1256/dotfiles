# modules/hypr/wlogout.nix
{ pkgs, ... }: let
  icons = "${pkgs.wlogout}/share/wlogout/icons";
in {
  programs.wlogout = {
    enable = true;

    layout = [
      {
        label = "lock";
        action = "loginctl lock-session";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "logout";
        action = "loginctl terminate-user $USER";
        text = "Logout";
        keybind = "e";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "hibernate";
        action = "systemctl hibernate";
        text = "Hibernate";
        keybind = "h";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot";
        keybind = "r";
      }
    ];

    style = ''
      /* wlogout — Matcha Latte */
      * {
          background-image: none;
          box-shadow: none;
          font-family: "Fira Code", "Symbols Nerd Font", monospace;
          font-size: 16px;
          transition: all 0.2s ease;
      }

      window {
          background-color: rgba(31, 37, 24, 0.88);
      }

      button {
          color: #ECE4CC;
          background-color: rgba(52, 60, 43, 0.85);
          border: 2px solid rgba(120, 134, 92, 0.40);
          border-radius: 22px;
          margin: 14px;
          background-repeat: no-repeat;
          background-position: center;
          background-size: 26%;
      }

      button:focus,
      button:hover {
          background-color: #A4BC7C;
          color: #28311F;
          border-color: #A4BC7C;
      }

      #lock      { background-image: image(url("${icons}/lock.png")); }
      #logout    { background-image: image(url("${icons}/logout.png")); }
      #suspend   { background-image: image(url("${icons}/suspend.png")); }
      #hibernate { background-image: image(url("${icons}/hibernate.png")); }
      #shutdown  { background-image: image(url("${icons}/shutdown.png")); }
      #reboot    { background-image: image(url("${icons}/reboot.png")); }
    '';
  };
}
