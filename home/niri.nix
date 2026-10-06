{ pkgs, ... }:

let
  config = pkgs.writeText "niri-config.kdl" ''
    input {
        keyboard {
            xkb {
                layout "kr"
                variant "kr104"
                options "korean:ralt_hangul,korean:rctrl_hanja"
            }
        }
        touchpad {
            natural-scroll
        }
        mouse {
            accel-profile "flat"
            accel-speed 0.0
        }
    }

    cursor {
        xcursor-theme "catppuccin-mocha-mauve-cursors"
        xcursor-size 24
    }

    environment {
        QT_QPA_PLATFORM "wayland"
        NIXOS_OZONE_WL "1"
    }

    // Let Niri launch Xwayland on demand for Proton-based Fusion.
    xwayland-satellite {
        path "${pkgs.xwayland-satellite}/bin/xwayland-satellite"
    }

    spawn-at-startup "noctalia"

    // Persist the display layout currently active in this Niri session.
    output "HDMI-A-1" {
        mode "3440x1440@100"
        scale 1.0
        transform "normal"
        position x=2680 y=-1440
    }

    output "eDP-1" {
        mode "1920x1080@59.997"
        scale 1.0
        transform "normal"
        position x=3440 y=0
    }

    window-rule {
        geometry-corner-radius 16
        clip-to-geometry true
    }

    window-rule {
        match app-id="dev.noctalia.Noctalia"
        open-floating true
        default-column-width { fixed 1080; }
        default-window-height { fixed 900; }
    }

    // Keep every KakaoTalk window floating so it can be moved freely.
    window-rule {
        match app-id=r"^kakaotalk\.exe$"
        open-floating true
        open-fullscreen false
        open-maximized-to-edges false
    }

    // Give conversation windows a sensible initial size without locking resizing.
    window-rule {
        match app-id=r"^kakaotalk\.exe$"
        exclude title="^카카오톡$"
        open-floating true
        open-fullscreen false
        open-maximized-to-edges false
        default-column-width { fixed 900; }
        default-window-height { fixed 700; }
    }

    window-rule {
        match app-id=r"(?i).*fusion.*"
        open-floating true
    }

    window-rule {
        match title=r"(?i).*autodesk fusion.*"
        open-floating true
    }

    // Fusion windows arrive from Proton with this app-id, including auxiliary dialogs.
    window-rule {
        match app-id=r"^steam_proton$"
        open-floating true
        open-fullscreen false
        open-maximized-to-edges false
    }

    debug {
        honor-xdg-activation-with-invalid-serial
    }

    layout {
        gaps 8
        background-color "#1e1e2e"
        center-focused-column "never"
        default-column-width { proportion 0.5; }
        border {
            width 2
            active-color "#cba6f7"
            inactive-color "#45475a"
        }
        focus-ring { off; }
    }

    overview {
        backdrop-color "#181825"
    }

    layer-rule {
        match namespace="^noctalia-"
        background-effect {
            xray false
        }
    }

    blur {
        passes 2
        offset 3.0
        saturation 1.0
    }

    binds {
        Mod+Return { spawn "terminator"; }
        Mod+Space { spawn-sh "noctalia msg panel-toggle launcher"; }
        Mod+S { spawn-sh "noctalia msg panel-toggle control-center"; }
        Mod+Comma { spawn-sh "noctalia msg settings-toggle"; }
        Mod+Shift+D { spawn-sh "noctalia msg panel-toggle raycursive/niri-displays:panel"; }
        Print { spawn "screenshot-region"; }
        Mod+Shift+S { spawn "screenshot-region"; }
        Alt+Tab { spawn-sh "noctalia msg window-switcher hold"; }
        Super+Alt+L { spawn "noctalia" "msg" "session" "lock"; }
        Mod+Q { close-window; }
        Mod+O { toggle-overview; }
        Mod+F { maximize-column; }
        Mod+V { toggle-window-floating; }
        Mod+R { switch-preset-column-width; }

        Mod+H { focus-column-left; }
        Mod+J { focus-window-down; }
        Mod+K { focus-window-up; }
        Mod+L { focus-column-right; }
        Mod+Shift+H { move-column-left; }
        Mod+Shift+J { move-window-down; }
        Mod+Shift+K { move-window-up; }
        Mod+Shift+L { move-column-right; }

        Mod+Left { focus-column-left; }
        Mod+Down { focus-window-down; }
        Mod+Up { focus-window-up; }
        Mod+Right { focus-column-right; }
        Mod+Shift+Left { move-column-left; }
        Mod+Shift+Down { move-window-down; }
        Mod+Shift+Up { move-window-up; }
        Mod+Shift+Right { move-column-right; }

        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }
        Mod+Shift+1 { move-window-to-workspace 1; }
        Mod+Shift+2 { move-window-to-workspace 2; }
        Mod+Shift+3 { move-window-to-workspace 3; }
        Mod+Shift+4 { move-window-to-workspace 4; }
        Mod+Shift+5 { move-window-to-workspace 5; }
        Mod+Shift+6 { move-window-to-workspace 6; }
        Mod+Shift+7 { move-window-to-workspace 7; }
        Mod+Shift+8 { move-window-to-workspace 8; }
        Mod+Shift+9 { move-window-to-workspace 9; }

        Mod+Alt+Left { focus-monitor-left; }
        Mod+Alt+Right { focus-monitor-right; }
        Mod+Shift+Alt+Left { move-column-to-monitor-left; }
        Mod+Shift+Alt+Right { move-column-to-monitor-right; }

        // Floating windows belong to one monitor's workspace. Move the whole
        // focused window to another monitor explicitly instead of dragging it
        // past the edge, where it can appear to disappear.
        Mod+Ctrl+Shift+Left { move-window-to-monitor-left; focus-monitor-left; }
        Mod+Ctrl+Shift+Right { move-window-to-monitor-right; focus-monitor-right; }
        Mod+Ctrl+Shift+Up { move-window-to-monitor-up; focus-monitor-up; }
        Mod+Ctrl+Shift+Down { move-window-to-monitor-down; focus-monitor-down; }

        XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "noctalia msg volume-up"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn-sh "noctalia msg volume-down"; }
        XF86AudioMute allow-when-locked=true { spawn-sh "noctalia msg volume-mute"; }
        XF86MonBrightnessUp allow-when-locked=true { spawn-sh "noctalia msg brightness-up"; }
        XF86MonBrightnessDown allow-when-locked=true { spawn-sh "noctalia msg brightness-down"; }

        Mod+Shift+E { quit; }
    }
  '';
in
{
  xdg.configFile."niri/config.kdl".source = config;
}
