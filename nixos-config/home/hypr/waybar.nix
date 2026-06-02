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
    /*
     * BeerCSS -> Waybar adapter
     *
     * Waybar uses GTK CSS, so browser-only BeerCSS syntax such as
     * :root, --primary, var(--primary), rem, and component classes cannot be
     * pasted unchanged. Keep the BeerCSS values here and map them to GTK
     * @define-color tokens:
     *
     *   --primary: #70A8A0;            -> @define-color primary #70A8A0;
     *   --on-primary: rgba(...);       -> @define-color on_primary rgba(...);
     *   --surface: rgba(...);          -> @define-color surface rgba(...);
     */

    /* ===== BeerCSS / Material You tokens, mapped to the original dark theme ===== */
    @define-color primary                 #70A8A0;
    @define-color on_primary              rgba(72, 56, 32, 0.70);
    @define-color primary_container       rgba(108, 88, 56, 0.70);
    @define-color on_primary_container    #F0D8A0;

    @define-color secondary               #7A9878;
    @define-color on_secondary            #F0D8A0;
    @define-color secondary_container     rgba(84, 66, 40, 0.70);
    @define-color on_secondary_container  #F0D8A0;

    @define-color tertiary                #7A9878;
    @define-color on_tertiary             #F0D8A0;
    @define-color tertiary_container      rgba(48, 72, 56, 0.70);
    @define-color on_tertiary_container   #F0D8A0;

    @define-color error                   #D06858;
    @define-color on_error                #F0D8A0;
    @define-color error_container         rgba(88, 48, 40, 0.70);
    @define-color on_error_container      #D06858;

    @define-color surface                 rgba(80, 64, 40, 0.70);
    @define-color surface_dim             rgba(60, 46, 30, 0.70);
    @define-color surface_container_low   rgba(72, 56, 32, 0.70);
    @define-color surface_container       rgba(84, 66, 40, 0.70);
    @define-color surface_container_high  rgba(96, 76, 48, 0.70);
    @define-color surface_variant         rgba(108, 88, 56, 0.70);
    @define-color on_surface              #F0D8A0;
    @define-color on_surface_variant      #F0D8A0;
    @define-color outline                 rgba(120, 100, 72, 0.70);
    @define-color shadow                  rgba(0, 0, 0, 0.22);

    @define-color warning_container       rgba(72, 56, 8, 0.70);
    @define-color on_warning_container    #D8C070;

    /* ===== General ===== */
    * {
      border: none;
      border-radius: 4;
      box-shadow: none;
      font-family: "Fira Code", "FontAwesome", monospace;
      font-size: 14px;
      min-height: 0;
      padding: 2;
    }

    /* ===== BeerCSS-like utility classes for modules that expose class names ===== */
    .primary {
      background: @primary;
      color: @on_primary;
    }

    .secondary {
      background: @secondary_container;
      color: @on_secondary_container;
    }

    .tertiary {
      background: @tertiary_container;
      color: @on_tertiary_container;
    }

    .error {
      background: @error_container;
      color: @on_error_container;
    }

    .surface {
      background: @surface_container;
      color: @on_surface;
    }

    .round {
      border-radius: 999px;
    }

    .border {
      border: 1px solid @outline;
    }

    /* ===== Waybar Base ===== */
    window#waybar {
      background: @surface;
      color: @on_surface;
    }

    window#waybar.hidden {
      opacity: 0.2;
    }

    /* ===== Shared module shape ===== */
    #clock,
    #battery,
    #cpu,
    #memory,
    #pulseaudio,
    #network,
    #backlight,
    #temperature,
    #mode,
    #custom-media,
    #idle_inhibitor,
    #power-profiles-daemon,
    #language,
    #tray,
    #custom-power {
      background: @surface_container;
      color: @on_surface;
      border-radius: 10px;
      padding: 0 15px 0 15px;
    }

    /* ===== Workspaces ===== */
    #workspaces {
      margin: 0;
    }

    #workspaces button {
      background: @surface_variant;
      color: @on_surface;
      border-radius: 10px;
      margin: 0 3px 0 3px;
      padding: 0 15px 0 15px;
    }

    #workspaces button:hover {
      background: @surface_container_high;
      color: @on_surface;
    }

    #workspaces button.active {
      background: @primary;
      color: @on_primary;
    }

    #workspaces button.urgent {
      background: @error_container;
      color: @on_error_container;
    }

    /* ===== Modules ===== */
    #clock {
      background: @secondary;
      color: @on_secondary;
      border-radius: 10px;
    }

    #battery.warning {
      background: @warning_container;
      color: @on_warning_container;
    }

    #battery.critical {
      background: @error_container;
      color: @error;
    }

    #network.disconnected,
    #pulseaudio.muted {
      background: @error_container;
      color: @on_error_container;
    }

    #taskbar button {
      background: @surface_container;
      margin: 0 3px 0 3px;
      padding: 1;
    }

    #taskbar button:hover {
      background: @surface_container_high;
    }

    #taskbar button.active {
      background: @secondary;
      color: @on_secondary;
      border-radius: 10px;
      margin: 0 3px 0 3px;
      padding: 3px;
    }

    #mode {
      background: @primary;
      color: @on_primary;
      font-weight: bold;
    }

    #custom-power {
      background: @error_container;
      color: @on_surface;
      padding: 0 15px 0 15px;
      border-radius: 10px;
    }

    /* ===== Tooltip ===== */
    tooltip {
      background: @surface_variant;
      color: @on_surface;
      border: 1px solid @outline;
    }

    tooltip label {
      color: @on_surface;
      padding: 6px;
    }
  '';
}
