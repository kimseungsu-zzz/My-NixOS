{ ... }:

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
        library = "org.kde.breeze";
        theme = "Breeze";
      };
      # No splash screen: the plain base colour below shows straight away.
      splashScreen.theme = "None";
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

    # Top bar: floating, auto-hides (slides in when the pointer hits the top edge), 58px high, filling the width of each screen (so it adapts to
    # whatever monitor it is on). Widgets are the Plasma defaults.
    panels = [
      {
        location = "top";
        # Show the panel on every monitor.
        screen = "all";
        floating = true;
        height = 58;
        alignment = "center";
        # Fixed 1280px, centred (same on every monitor).
        lengthMode = "custom";
        minLength = 1280;
        maxLength = 1280;
        # Hidden until the pointer touches the top edge (dodgewindows made plasmashell segfault).
        hiding = "autohide";
      }
    ];

    # Alt+Space: Vicinae launcher (Spotlight / Raycast style). KRunner keeps only Alt+F2.
    hotkeys.commands."vicinae" = {
      name = "Vicinae launcher";
      key = "Alt+Space";
      command = "vicinae toggle";
    };
    shortcuts."services/org.kde.krunner.desktop"."_launch" = "Alt+F2";

    # Karousel's toggle floating: Meta+Space plus Meta+F as a fallback in case Meta+Space is grabbed.
    shortcuts.kwin."karousel-window-toggle-floating" = [ "Meta+Space" "Meta+F" ];

    # Print / Meta+Shift+S: region screenshot with Spectacle.
    hotkeys.commands."screenshot-region" = {
      name = "Region screenshot";
      key = "Meta+Shift+S";
      command = "spectacle --region";
    };

    configFile = {
      # Window shadows (Breeze decoration): medium size, 80% strength.
      "breezerc"."Common"."ShadowSize" = "ShadowMedium";
      "breezerc"."Common"."ShadowStrength" = 200;
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
      # New windows open on the screen the mouse is on (the default follows the last focused window).
      # Karousel puts a window into the grid of the screen KWin placed it on.
      kwinrc.Windows.ActiveMouseScreen = true;
      plasma-localerc.Formats.LANG = "en_US.UTF-8";

      # KWin scripts/effects. Karousel is the scrollable tiling script (shortcuts: Meta+A/D to
      # move focus, Meta+Shift+A/D to move a window, Meta+R to cycle widths, Meta+Space to
      # toggle floating for the focused window). overrideConfig resets kwinrc, so declare it.
      kwinrc.Plugins.karouselEnabled = true;
      # Karousel tiles every normal window, which breaks Wine apps (Fusion 360, KakaoTalk): their
      # windows get resized/stolen. Wine windows have the .exe name as class, so keep them floating.
      # This replaces the built-in rule list, so the defaults are repeated (with [.] for the dot).
      kwinrc."Script-karousel".windowRules = builtins.toJSON [
        { class = ".*[.]exe"; tile = false; }
        { class = "spotify"; tile = false; }
        { class = "(org[.]kde[.])?plasmashell"; tile = false; }
        { class = "(org[.]kde[.])?polkit-kde-authentication-agent-1"; tile = false; }
        { class = "(org[.]kde[.])?kded6"; tile = false; }
        { class = "(org[.]kde[.])?kcalc"; tile = false; }
        { class = "(org[.]kde[.])?kfind"; tile = true; }
        { class = "(org[.]kde[.])?kruler"; tile = false; }
        { class = "(org[.]kde[.])?krunner"; tile = false; }
        { class = "(org[.]kde[.])?yakuake"; tile = false; }
        { class = "(org[.]kde[.])?spectacle"; tile = false; }
        { class = "wl-copy|wl-paste"; caption = "wl-clipboard"; tile = false; }
        { class = "steam"; caption = "Steam Big Picture Mode"; tile = false; }
        { class = "zoom"; caption = "Zoom Cloud Meetings|zoom|zoom <2>"; tile = false; }
        { class = "jetbrains-.*"; caption = "splash"; tile = false; }
        { class = "jetbrains-.*"; caption = "Unstash Changes|Paths Affected by stash@.*"; tile = true; }
      ];
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
