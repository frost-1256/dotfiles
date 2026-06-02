# modules/hyprlock.nix
{ ... }: {
  programs.hyprlock = {
    enable = true;
  };
  xdg.configFile."hypr/hyprlock.conf".text = ''
    # sample hyprlock.conf
    # for more configuration options, refer https://wiki.hyprland.org/Hypr-Ecosystem/hyprlock
    #
    # rendered text in all widgets supports pango markup (e.g. <b> or <i> tags)
    # ref. https://wiki.hyprland.org/Hypr-Ecosystem/hyprlock/#general-remarks
    #
    # shortcuts to clear password buffer: ESC, Ctrl+U, Ctrl+Backspace
    #
    # you can get started by copying this config to ~/.config/hypr/hyprlock.conf
    #

    $font = Monospace

    general {
        hide_cursor = false
    }

    # uncomment to enable fingerprint authentication
    auth {
        fingerprint {
          enabled = true
            ready_message = Scan fingerprint to unlock
            present_message = Scanning...
            retry_delay = 250 # in milliseconds
        }
    }

    animations {
        enabled = true
        bezier = linear, 1, 1, 0, 0
        animation = fadeIn, 1, 5, linear
        animation = fadeOut, 1, 5, linear
        animation = inputFieldDots, 1, 2, linear
    }

    background {
        monitor =
        path = screenshot
        blur_passes = 3
    }

    input-field {
        monitor =
        size = 280, 56
        outline_thickness = 2
        inner_color = rgba(40, 47, 33, 200)

        outer_color = rgba(164, 188, 124, 220)
        check_color = rgba(136, 168, 96, 220)
        fail_color = rgba(204, 112, 89, 220)

        font_color = rgb(236, 228, 204)
        fade_on_empty = false
        rounding = 16

        font_family = $font
        placeholder_text = <i>パスワードを入力...</i>
        fail_text = <span color="##D06858">$PAMFAIL</span>

        dots_spacing = 0.3
        dots_center = true

        position = 0, -20
        halign = center
        valign = center
    }

    # TIME
    label {
        monitor =
        text = $TIME # ref. https://wiki.hyprland.org/Hypr-Ecosystem/hyprlock/#variable-substitution
        font_size = 90
        font_family = $font
        color = rgba(236, 228, 204, 1.0)

        position = -30, 0
        halign = right
        valign = top
    }

    # DATE
    label {
        monitor =
        text = cmd[update:60000] date +"%A, %d %B %Y" # update every 60 seconds
        font_size = 25
        font_family = $font
        color = rgba(236, 228, 204, 1.0)

        position = -30, -150
        halign = right
        valign = top
    }

    label {
        monitor =
        text = $LAYOUT[en,ru]
        font_size = 24
        onclick = hyprctl switchxkblayout all next

        position = 250, -20
        halign = center
        valign = center
    }
  '';
}
