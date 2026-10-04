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

  # Per-monitor tiling for KWin (Krohnkite), plus the animation for windows that a
  # script moves or resizes. Enabled in home/plasma.nix (kwinrc Plugins).
  environment.systemPackages = [
    pkgs.kdePackages.krohnkite
    pkgs.kwin-script-geometry-change
  ];

  # Bluetooth. The Plasma 6 session brings the BlueDevil tray applet/settings page.
  # linux-firmware is needed for the controller (Intel Bluetooth loads firmware from it).
  hardware.enableRedistributableFirmware = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General.FastConnectable = true;
      # Re-establish a dropped link to a paired device a few times.
      Policy = {
        AutoEnable = true;
        ReconnectAttempts = 7;
        ReconnectIntervals = "1,2,4,8,16,32,64";
      };
    };
  };

  # BlueZ does not dial out to paired devices by itself after boot (it waits for the device to
  # connect). Connect every paired device once Bluetooth is up; ones that are off just time out.
  systemd.services.bluetooth-autoconnect = {
    description = "Connect paired Bluetooth devices at boot";
    after = [ "bluetooth.service" ];
    wants = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.bluez pkgs.coreutils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      sleep 5
      bluetoothctl power on
      for dev in $(bluetoothctl devices Paired | cut -d' ' -f2); do
        bluetoothctl trust "$dev"
        timeout 25 bluetoothctl connect "$dev" &
      done
      wait
    '';
  };

  # Flatpak, managed declaratively by nix-flatpak (flake input): Flathub is added and the apps below
  # are installed on activation. OrcaSlicer comes from Flatpak because the nixpkgs build crashes
  # on webkitgtk 2.54 (its own WebKit is bundled in the Flatpak runtime).
  services.flatpak = {
    enable = true;
    packages = [ "com.orcaslicer.OrcaSlicer" ];
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
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
