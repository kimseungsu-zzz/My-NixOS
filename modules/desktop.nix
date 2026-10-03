{ pkgs, ... }:

{
  # KDE Plasma on the Wayland session (X server kept for XWayland apps).
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.xserver.xkb = {
    layout = "kr";
    variant = "kr104";
    options = "korean:ralt_hangul,korean:rctrl_hanja";
  };

  services.printing.enable = true;

  # Korean input: install the engine here instead of relying on the hnc module.
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = with pkgs.ibus-engines; [ hangul ];
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
