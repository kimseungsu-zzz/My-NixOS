{ ... }:

{
  home.stateVersion = "26.05";

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
    workspace = {
      lookAndFeel = "org.kde.breezedark.desktop";
      colorScheme = "BreezeDark";
    };

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
    };

    # Add more as you change them, e.g. via the plasma-manager options:
    # https://nix-community.github.io/plasma-manager/options.html
    # workspace = { ... };   # theme, cursor, icons, wallpaper
    # panels = [ ... ];      # panel layout and widgets
    # shortcuts = { ... };   # keyboard shortcuts
  };
}
