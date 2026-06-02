# modules/hypr/waybar.nix
{ ... }: {
  programs.waybar = {
    enable = true;
  };
  xdg.configFile."waybar/config.jsonc".text = ''
    // -*- mode: jsonc -*-
    {
        "layer": "top",
        "position": "top",
        "height": 44,
        "margin-top": 8,
        "margin-left": 12,
        "margin-right": 12,
        "spacing": 6,
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
        "hyprland/workspaces": {
            "format": "{id}"
        },
        "wlr/taskbar": {
            "icon-size": 18,
            "on-click": "activate",
            "on-click-right": "minimize",
            "format": "{icon}"
        },
        "tray": {
            "spacing": 8
        },
        "clock": {
            "timezone": "Asia/Tokyo",
            "format": "{:%H:%M}",
            "format-alt": "{:%Y-%m-%d}",
            "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
            "justify": "center"
        },
        "cpu": {
            "format": "󰘚 {usage}%",
            "tooltip": true,
            "justify": "center"
        },
        "memory": {
            "format": "󰍛 {percentage}%",
            "tooltip-format": "RAM {used:0.1f}G / {total:0.1f}G",
            "justify": "center"
        },
        "backlight": {
            "format": "{icon} {percent}%",
            "format-icons": ["󰃞", "󰃟", "󰃠"],
            "justify": "center"
        },
        "battery": {
            "states": {
                "warning": 35,
                "critical": 20
            },
            "format": "{icon} {capacity}%",
            "format-charging": "󰂄 {capacity}%",
            "format-plugged": "󰂄 {capacity}%",
            "format-icons": ["󰂎", "󰁼", "󰁾", "󰂀", "󰁹"],
            "justify": "center"
        },
        "network": {
            "format-wifi": "{icon}",
            "format-ethernet": "󰈀",
            "format-disconnected": "󰖪",
            "format-icons": ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"],
            "tooltip-format": "{ifname} via {gwaddr}",
            "tooltip-format-wifi": "{essid} ({signalStrength}%)",
            "tooltip-format-disconnected": "Disconnected",
            "justify": "center"
        },
        "pulseaudio": {
            "format": "{icon} {volume}%",
            "format-bluetooth": "{icon} {volume}%",
            "format-muted": "󰖁",
            "format-icons": {
                "default": ["󰕿", "󰖀", "󰕾"]
            },
            "on-click": "pavucontrol",
            "tooltip-format": "{volume}% {desc}",
            "justify": "center"
        },
        "custom/power": {
            "format": "󰐥",
            "justify": "center",
            "on-click": "wlogout"
        }
    }
  '';
  xdg.configFile."waybar/style.css".text = ''
    /* ===== Matcha Latte tokens (Material You) ===== */
    @define-color primary                 #A4BC7C;
    @define-color on_primary              #283418;
    @define-color primary_container       rgba(74, 96, 52, 0.75);
    @define-color on_primary_container    #C8DCA0;

    @define-color secondary               #CBBE96;
    @define-color on_secondary            #322A18;
    @define-color secondary_container     rgba(96, 88, 56, 0.70);
    @define-color on_secondary_container  #ECE0BC;

    @define-color tertiary                #88A860;
    @define-color on_tertiary             #1A2C10;
    @define-color tertiary_container      rgba(60, 80, 40, 0.70);
    @define-color on_tertiary_container   #D2E4A8;

    @define-color error                   #CC7059;
    @define-color on_error                #2A140E;
    @define-color error_container         rgba(92, 52, 40, 0.72);
    @define-color on_error_container      #F0C0B0;

    @define-color surface                 rgba(40, 47, 33, 0.82);
    @define-color surface_dim             rgba(31, 37, 26, 0.82);
    @define-color surface_container_low   rgba(44, 51, 36, 0.74);
    @define-color surface_container       rgba(52, 60, 43, 0.78);
    @define-color surface_container_high  rgba(64, 73, 53, 0.82);
    @define-color surface_variant         rgba(78, 88, 64, 0.70);
    @define-color on_surface              #ECE4CC;
    @define-color on_surface_variant      #C4CDA8;
    @define-color outline                 rgba(120, 134, 92, 0.55);
    @define-color shadow                  rgba(0, 0, 0, 0.30);

    @define-color warning_container       rgba(74, 66, 24, 0.72);
    @define-color on_warning_container    #E0CE8C;

    /* ===== General ===== */
    * {
      border: none;
      border-radius: 0;
      box-shadow: none;
      font-family: "Fira Code", "Symbols Nerd Font", "FontAwesome", monospace;
      font-size: 14px;
      min-height: 0;
      padding: 0;
      transition: background 150ms ease;
    }

    /* ===== Floating top bar ===== */
    window#waybar {
      background: @surface;
      color: @on_surface;
      border-radius: 16px;
    }

    window#waybar.hidden { opacity: 0.2; }

    /* ===== Shared module chip ===== */
    #clock,
    #battery,
    #cpu,
    #memory,
    #pulseaudio,
    #network,
    #backlight,
    #tray,
    #custom-power {
      background: @surface_container;
      color: @on_surface;
      border-radius: 999px;
      padding: 0 14px;
      margin: 6px 3px;
    }

    /* ===== Workspaces ===== */
    #workspaces {
      background: @surface_container_low;
      border-radius: 999px;
      padding: 0 4px;
      margin: 6px 3px;
    }

    #workspaces button {
      background: transparent;
      color: @on_surface;
      border-radius: 999px;
      margin: 4px 2px;
      padding: 0 12px;
      min-width: 24px;
    }

    #workspaces button:hover { background: @surface_container_high; }

    #workspaces button.active {
      background: @primary;
      color: @on_primary;
    }

    #workspaces button.urgent {
      background: @error_container;
      color: @on_error_container;
    }

    /* ===== Accent modules ===== */
    #clock {
      background: @secondary;
      color: @on_secondary;
      font-weight: 600;
    }

    #battery.warning {
      background: @warning_container;
      color: @on_warning_container;
    }

    #battery.critical {
      background: @error_container;
      color: @on_error_container;
    }

    #network.disconnected,
    #pulseaudio.muted {
      background: @error_container;
      color: @on_error_container;
    }

    /* ===== Taskbar ===== */
    #taskbar {
      background: @surface_container_low;
      border-radius: 999px;
      padding: 0 4px;
      margin: 6px 3px;
    }

    #taskbar button {
      background: transparent;
      border-radius: 999px;
      margin: 4px 2px;
      padding: 0 6px;
    }

    #taskbar button:hover { background: @surface_container_high; }

    #taskbar button.active {
      background: @secondary;
      color: @on_secondary;
    }

    #custom-power {
      background: @error_container;
      color: @on_error_container;
    }

    /* ===== Tooltip ===== */
    tooltip {
      background: @surface_variant;
      color: @on_surface;
      border-radius: 12px;
      border: 1px solid @outline;
      padding: 4px;
    }

    tooltip label {
      color: @on_surface;
      padding: 6px;
    }
  '';
}
