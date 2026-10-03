{ ... }:

{
  home.stateVersion = "26.05";

  programs.plasma = {
    enable = true;

    # false: only the settings listed here are enforced; everything else stays
    # as the GUI left it. true would reset every unlisted Plasma setting to its
    # default on activation, panels and wallpaper included.
    overrideConfig = false;

    # Captured from the running desktop with
    #   nix run github:nix-community/plasma-manager
    # Only settings that differ from the Plasma defaults are kept: the shortcut
    # table was all defaults, and the Kate/Dolphin entries were session state.
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
