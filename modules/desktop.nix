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

  # Scrollable tiling (niri / PaperWM style, multi-monitor fork, source in the nix-packages repo) comes
  # from the karousel module there and is enabled in home/plasma.nix (kwinrc Plugins).

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

  # Chromium/Electron apps (Brave, VS Code, Claude, ChatGPT, Spotify, ...) run through XWayland
  # by default, where they get no input method. This makes them use native Wayland, which
  # includes the text-input protocol (--enable-wayland-ime) that KWin forwards to IBus.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

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
