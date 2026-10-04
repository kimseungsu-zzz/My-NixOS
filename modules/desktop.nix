{ pkgs, ... }:

{
  # KDE Plasma on the Wayland session (X server kept for XWayland apps).
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Log in automatically at boot (no SDDM password prompt). The screen lock is already
  # disabled in home/plasma.nix (kscreenlockerrc).
  services.displayManager.autoLogin = {
    enable = true;
    user = "linux";
  };
  services.displayManager.defaultSession = "plasma";

  services.xserver.xkb = {
    layout = "kr";
    variant = "kr104";
    options = "korean:ralt_hangul,korean:rctrl_hanja";
  };

  services.printing.enable = true;

  # Scrollable tiling (niri / PaperWM style) for KWin, plus the animation for windows that a
  # script moves or resizes. Enabled in home/plasma.nix (kwinrc Plugins).
  environment.systemPackages = [
    pkgs.kdePackages.karousel
    pkgs.kwin-script-geometry-change
  ];

  # Bluetooth. The Plasma 6 session brings the BlueDevil tray applet/settings page.
  # linux-firmware is needed for the controller (Intel Bluetooth loads firmware from it).
  hardware.enableRedistributableFirmware = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Korean input: install the engine here instead of relying on the hnc module.
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = with pkgs.ibus-engines; [ hangul ];
    # Plasma Wayland: KWin starts IBus itself (kwinrc InputMethod in home/plasma.nix) and
    # talks to apps over the Wayland text-input protocol, so GTK_IM_MODULE/QT_IM_MODULE
    # must stay unset. XMODIFIERS (XWayland/Wine) is still set.
    ibus.waylandFrontend = true;
  };

  # Needed for home-manager dconf.settings (ibus-hangul keys).
  programs.dconf.enable = true;

  # Sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
