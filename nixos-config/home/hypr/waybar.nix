# modules/hypr/waybar.nix
{ ... }: {
  programs.waybar = {
    enable = true;
  };
  xdg.configFile."waybar/config.jsonc".text = ''
    // -*- mode: jsonc -*-
    {
        // "layer": "top", // Waybar at top layer
        // "position": "bottom", // Waybar position (top|bottom|left|right)
        "height": 25, // Waybar height (to be removed for auto height)
        // "width": 1280, // Waybar width
        "spacing": 4, // Gaps between modules (4px)
        // Choose the order of the modules
        "modules-left": [
            "hyprland/workspaces",
            "wlr/taskbar"
        ],
        "modules-center": [
            "clock"
        ],
        "modules-right": [
            "pulseaudio",
            "network",
            "cpu",
            "memory",
            "backlight",
            "tray",
            "battery",
            "custom/power"
        ],
        "keyboard-state": {
            "numlock": true,
            "capslock": true,
            "format": "{name} {icon}",
            "format-icons": {
                "locked": "",
                "unlocked": ""
            }
        },
        "hyprland/mode": {
            "format": "<span style=\"italic\">{}</span>"
        },
        "hyprland/scratchpad": {
            "format": "{icon} {count}",
            "show-empty": false,
            "format-icons": ["", ""],
            "tooltip": true,
            "tooltip-format": "{app}: {title}"
        },
        "tray": {
            // "icon-size": 21,
            "spacing": 10,
            // "icons": {
            //   "blueman": "bluetooth",
            //   "TelegramDesktop": "$HOME/.local/share/icons/hicolor/16x16/apps/telegram.png"
            // }
        },
        "wlr/taskbar": {
            "icon-size": 20,
            "on-click": "activate",
            "on-click-right": "minimize",
            "format": "{icon}"
        },
        "clock": {
            "timezone": "Asia/Tokyo",
            "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
            "format-alt": "{:%Y-%m-%d}",
            "justify": "center"
        },
        "cpu": {
            "format": "{usage}% ",
            "tooltip": false,
            "justify": "center"
        },
        "memory": {
            "format": "{}% ",
            "justify": "center"
        },
        "temperature": {
            // "thermal-zone": 2,
            // "hwmon-path": "/sys/class/hwmon/hwmon2/temp1_input",
            "critical-threshold": 80,
            // "format-critical": "{temperatureC}°C {icon}",
            "format": "{temperatureC}°C {icon}",
            "format-icons": [""],
            "justify": "center"
        },
        "backlight": {
            // "device": "acpi_video1",
            "format": "{percent}% {icon}",
            "format-icons": ["", "", "", "", "", "", "", "", ""],
            "justify": "center"
        },
        "battery": {
            "states": {
                // "good": 95,
                "warning": 35,
                "critical": 20
            },
            "format": "{capacity}% {icon}",
            "format-full": "{capacity}% {icon}",
            "format-charging": "{capacity}% ",
            "format-plugged": "{capacity}% ",
            "format-alt": "{time} {icon}",
            // "format-good": "", // An empty format will hide the module
            // "format-full": "",
            "format-icons": ["", "", "", "", ""],
            "justify": "center"
        },
        "power-profiles-daemon": {
          "format": "{icon}",
          "tooltip-format": "Power profile: {profile}\nDriver: {driver}",
          "tooltip": true,
          "format-icons": {
            "default": "",
            "performance": "",
            "balanced": "",
            "power-saver": ""
          }
        },
        "network": {
            // "interface": "wlp2*", // (Optional) To force the use of this interface
            "format-wifi": "{essid} [{signalStrength}%]  ",
            "format-ethernet": "{ipaddr}/{cidr} ",
            "tooltip-format": "{ifname} via {gwaddr} ",
            "format-linked": "{ifname} (No IP) ",
            "format-disconnected": "Disconnected ⚠",
            "format-alt": "{ifname}: {ipaddr}/{cidr}",
            "justify": "center"
        },
        "pulseaudio": {
            // "scroll-step": 1, // %, can be a float
            "format": "{volume}% {icon} {format_source}",
            "format-bluetooth": "{volume}% {icon} {format_source}",
            "format-bluetooth-muted": "󰝟 {format_source}",
            "format-muted": "󰝟 {format_source}",
            "format-source": "{volume}% ",
            "format-source-muted": "󰍭",
            "format-icons": {
                "default": ["", "", ""]
            },
            "justify": "center",
            "on-click": "pavucontrol"
        },
        "custom/power": {
            "justify": "center",
            "format" : "",
            "on-click": "wlogout"
        }
    }
  '';
  xdg.configFile."waybar/style.css".text = ''
    /* ===== General ===== */
    * {
      border: none;
      border-radius: 4;
      font-family: "Fira Code", "FontAwesome", monospace;
      font-size: 14px;
      min-height: 0;
      padding: 2;
    }

    /* ===== Neko Kipferl — all transparent ===== */
    @define-color bg_dim      rgba(60, 46, 30, 0.70);
    @define-color bg0         rgba(72, 56, 32, 0.70);
    @define-color bg1         rgba(84, 66, 40, 0.70);
    @define-color bg2         rgba(96, 76, 48, 0.70);
    @define-color bg3         rgba(108, 88, 56, 0.70);
    @define-color bg4         rgba(120, 100, 72, 0.70);
    @define-color bg_visual   rgba(80, 64, 40, 0.70);
    @define-color bg_red      rgba(88, 48, 40, 0.70);
    @define-color bg_green    rgba(48, 72, 56, 0.70);
    @define-color bg_blue     rgba(40, 72, 88, 0.70);
    @define-color bg_yellow   rgba(72, 56, 8, 0.70);
    @define-color fg          #F0D8A0;
    @define-color red         #D06858;
    @define-color orange      #C8905A;
    @define-color yellow      #D8C070;
    @define-color green       #7A9878;
    @define-color aqua        #70A8A0;
    @define-color blue        #8098B8;
    @define-color purple      #B890A0;
    @define-color grey0       #907060;
    @define-color grey1       #A88870;
    @define-color grey2       #C0A888;

    /* ===== Waybar Base ===== */
    window#waybar {
      background: @bg_visual;
      color: @fg;
    }

    /* ===== Modules ===== */
    #workspaces button {
      background: @bg3;
      color: @fg;
      border-radius: 10px;
      padding: 0 15 0 15px;
      margin: 0 3 0 3px;
    }
    #workspaces button.active {
      background: @aqua;
      color: @bg0;
    }

    #clock,
    #battery,
    #cpu,
    #memory,
    #pulseaudio,
    #backlight,
    #temperature,
    #mode,
    #custom-media,
    #idle_inhibitor,
    #power-profiles-daemon,
    #language {
      background: @bg1;
      border-radius: 10px;
      padding: 0 15px 0 15px;
    }

    #network {
      background: @bg1;
      padding: 0 15px 0 15px;
      border-radius: 10px
    }

    #battery.warning  { background: @bg_yellow; color: @yellow; }
    #battery.critical { background: @bg_red;    color: @red;    }

    #clock {
      background: @green;
      color: @fg;
      border-radius: 10px;
    }

    #tray {
      padding: 0 10px;
      background-color: @bg1;
      border-radius: 10px;
    }
    /*#taskbar        { background: @bg1; }*/
    #taskbar button { margin: 0 3 0 3px; padding: 1; background: @bg1; }
    #taskbar button.active {
      margin: 0 3 0 3px;
      padding: 3px;
      background-color: @green;
      border-radius: 10px;
    }

    /* ===== Mode Indicator ===== */
    #mode {
      background: @aqua;
      color: @bg0;
      font-weight: bold;
    }

    /* ===== Tooltip ===== */
    tooltip {
      background: @bg3;
      color: @fg;
      border: 1px solid @bg4;
    }

    /* ===== Custom ===== */
    #custom-power {
      background: @bg_red;
      color: @fg;
      padding: 0 15px 0 15px;
      border-radius: 10px;
    }
  '';
}
