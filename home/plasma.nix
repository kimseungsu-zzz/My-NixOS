{ ... }:

let
  # Horizontal resolution of the primary screen in pixels (the logical one if
  # display scaling is on). The top panel is sized from it.
  screenWidth = 1920;
in
{
  programs.plasma = {
    enable = true;

    # true: every Plasma setting not listed here is reset to its default on
    # activation, panels and wallpaper included. This file is the whole desktop.
    overrideConfig = true;

    # Panel size/position live here; resetting it changes the top bar.
    resetFilesExclude = [ "plasmashellrc" ];

    # Captured from the running desktop with
    #   nix run github:nix-community/plasma-manager
    # Only settings that differ from the Plasma defaults are kept: the shortcut
    # table was all defaults, and the Kate/Dolphin entries were session state.
    # Dark theme. kdeglobals is reset by overrideConfig, so the theme has to be
    # declared. The title bar colours captured earlier (39,44,49) are Breeze Dark.
    # Catppuccin Mocha (Mauve). The packages come from modules/theme.nix.
    workspace = {
      lookAndFeel = "Catppuccin-Mocha-Mauve";
      colorScheme = "CatppuccinMochaMauve";
      iconTheme = "Papirus-Dark";
      cursor = {
        theme = "catppuccin-mocha-mauve-cursors";
        size = 24;
      };
      windowDecorations = {
        library = "org.kde.kwin.aurorae";
        theme = "__aurorae__svg__CatppuccinMocha-Modern";
      };
      # Catppuccin Mocha "base" (#1e1e2e).
      wallpaperPlainColor = "30,30,46";
    };

    # Fonts: Pretendard (Korean + Latin) for the UI, JetBrains Mono Nerd Font for monospace.
    fonts = {
      general = { family = "Pretendard"; pointSize = 10; };
      menu = { family = "Pretendard"; pointSize = 10; };
      toolbar = { family = "Pretendard"; pointSize = 10; };
      small = { family = "Pretendard"; pointSize = 8; };
      windowTitle = { family = "Pretendard"; pointSize = 10; };
      fixedWidth = { family = "JetBrainsMono Nerd Font"; pointSize = 10; };
    };

    # Never dim, turn off the display or suspend (on AC and battery). overrideConfig resets
    # powerdevilrc, so it is declared here. Lid action is left at the Plasma default.
    powerdevil = {
      AC = {
        dimDisplay.enable = false;
        turnOffDisplay.idleTimeout = "never";
        autoSuspend.action = "nothing";
      };
      battery = {
        dimDisplay.enable = false;
        turnOffDisplay.idleTimeout = "never";
        autoSuspend.action = "nothing";
      };
      lowBattery = {
        dimDisplay.enable = false;
        turnOffDisplay.idleTimeout = "never";
        autoSuspend.action = "nothing";
      };
    };

    # Ctrl+Alt+T (the built-in shortcut belonged to Konsole).
    hotkeys.commands."launch-terminator" = {
      name = "Launch Terminator";
      key = "Ctrl+Alt+T";
      command = "terminator";
    };

    # Top bar: floating, 58px high, two thirds of the screen
    # width, centred. Widgets are the Plasma defaults.
    panels = [
      {
        location = "top";
        floating = true;
        height = 58;
        alignment = "center";
        lengthMode = "custom";
        minLength = screenWidth * 2 / 3;
        maxLength = screenWidth * 2 / 3;
      }
    ];

    configFile = {
      # Touchpad. The section name is hardware-specific (vendor/product/name).
      kcminputrc."Libinput/5349/25870/ZNT0001:00 14E5:650E Touchpad".NaturalScroll = true;

      # No automatic screen lock.
      kscreenlockerrc.Daemon.Autolock = false;
      kscreenlockerrc.Daemon.LockOnResume = false;
      kscreenlockerrc.Daemon.Timeout = 0;

      # KWallet off.
      kwalletrc.Wallet.Enabled = false;
      kwalletrc.Wallet."First Use" = false;

      kdeglobals.KDE.AnimationDurationFactor = 1.414213562373095;
      kwinrc.Xwayland.Scale = 1;
      plasma-localerc.Formats.LANG = "en_US.UTF-8";

      # KWin scripts/effects. Karousel is the scrollable tiling script (shortcuts: Meta+A/D to
      # move focus, Meta+Shift+A/D to move a window, Meta+R to cycle widths, Meta+Space to
      # toggle floating for the focused window). overrideConfig resets kwinrc, so declare it.
      kwinrc.Plugins.karouselEnabled = true;
      kwinrc.Plugins.kwin4_effect_geometry_changeEnabled = true;

      # Default terminal for Dolphin / "Open terminal here" etc.
      kdeglobals.General.TerminalApplication = "terminator";
      kdeglobals.General.TerminalService = "terminator.desktop";

      # Korean keyboard. Plasma on Wayland reads the layout from kxkbrc (the NixOS
      # xkb options only reach SDDM/X11). Right Alt = Hangul, Right Ctrl = Hanja
      # for keyboards without dedicated keys. overrideConfig resets this file, so it
      # has to be declared here.
      kxkbrc.Layout = {
        Use = true;
        LayoutList = "kr";
        VariantList = "kr104";
        Options = "korean:ralt_hangul,korean:rctrl_hanja";
        ResetOldOptions = true;
      };

      # IBus input method on the Wayland session (ibus-hangul comes from the hnc module).
      kwinrc.Wayland.InputMethod = "/run/current-system/sw/share/applications/org.freedesktop.IBus.Panel.Wayland.Gtk3.desktop";
    };

    # Add more as you change them, e.g. via the plasma-manager options:
    # https://nix-community.github.io/plasma-manager/options.html
    # workspace = { ... };   # theme, cursor, icons, wallpaper
    # panels = [ ... ];      # panel layout and widgets
    # shortcuts = { ... };   # keyboard shortcuts
  };
}
