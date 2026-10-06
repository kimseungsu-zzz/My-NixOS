{ lib, pkgs, ... }:

let
  startEwwDesktopWidget = pkgs.writeShellScript "start-eww-desktop-widget" ''
    ${pkgs.eww}/bin/eww daemon >/dev/null 2>&1 || true
    for _ in $(${pkgs.coreutils}/bin/seq 1 20); do
      if ${pkgs.eww}/bin/eww open dashboard >/dev/null 2>&1; then
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 0.25
    done
    exit 0
  '';
in

{
  imports = [
    ./home/plasma.nix
    ./home/packages.nix
  ];

  home.stateVersion = "26.05";

  # Use Zen for browser links (including Fusion sign-in callbacks).
  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;
  };

  # Eww is an independent widget layer, not a Plasma desktop shortcut. Keep a
  # single small system-and-clock card over the otherwise clear desktop.
  xdg.configFile."eww/eww.yuck".text = ''
    (defpoll clock :interval "1s" :initial "00:00:00" `date '+%H:%M:%S'`)
    (defpoll calendar :interval "1m" :initial "Loading date…" `date '+%A, %B %-d'`)

    (defwidget desktop-card []
      (box :class "card" :orientation "vertical" :spacing 8
        (label :class "eyebrow" :text "ELKOWAR'S WACKY WIDGETS")
        (label :class "clock" :halign "start" :text clock)
        (label :class "calendar" :halign "start" :text calendar)
        (box :class "stats" :orientation "horizontal" :spacing 8
          (label :class "stat-label" :text "CPU")
          (label :class "stat-value" :text {round(EWW_CPU.avg, 0)})
          (label :class "stat-label" :text "%")
          (label :class "spacer" :hexpand true)
          (label :class "stat-label" :text "RAM")
          (label :class "stat-value" :text {round(EWW_RAM.used_mem / 1048576, 0)}))))

    (defwindow dashboard
      :monitor 0
      :geometry (geometry :x "32px" :y "84px" :width "330px" :height "190px" :anchor "top left")
      :stacking "bottom"
      :exclusive false
      :focusable "none"
      :namespace "eww-desktop-widget"
      (desktop-card))
  '';

  xdg.configFile."eww/eww.scss".text = ''
    * {
      all: unset;
      font-family: Pretendard, sans-serif;
    }

    .card {
      background-color: rgba(30, 30, 46, 0.92);
      border: 1px solid #45475a;
      border-radius: 18px;
      padding: 20px 22px;
    }

    .eyebrow {
      color: #a6adc8;
      font-size: 10px;
      font-weight: 700;
      letter-spacing: 1px;
    }

    .clock {
      color: #cdd6f4;
      font-size: 38px;
      font-weight: 700;
    }

    .calendar {
      color: #bac2de;
      font-size: 13px;
    }

    .stats {
      margin-top: 5px;
    }

    .stat-label {
      color: #a6adc8;
      font-size: 11px;
    }

    .stat-value {
      color: #94e2d5;
      font-size: 11px;
      font-weight: 700;
    }

    .spacer {
      min-width: 12px;
    }
  '';

  xdg.configFile."autostart/eww-desktop-widget.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Eww desktop widget
    Comment=Open the clock and system status widget on the clear desktop
    Exec=${startEwwDesktopWidget}
    Terminal=false
    OnlyShowIn=KDE;
    X-KDE-autostart-after=panel
  '';

  # IBus keeps its settings under /desktop/ibus/ in dconf (not /org/freedesktop/ibus).
  # Register the Hangul engine; only preloaded engines are used for switching.
  dconf.settings."desktop/ibus/general" = {
    preload-engines = [ "hangul" ];
    engines-order = [ "hangul" ];
  };

  # KDE caches the KWin script / service lookups under ~/.cache. The Nix profile directories have a constant
  # modification time, so those caches are never invalidated and KWin kept running an old Karousel after the
  # script had been rebuilt. Clear them on every activation (they are rebuilt automatically).
  home.activation.clearKdeCaches = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    rm -f "$HOME"/.cache/ksycoca6_*
    rm -rf "$HOME/.cache/kwin" "$HOME/.cache/qmlcache"
    ${pkgs.desktop-file-utils}/bin/update-desktop-database "$HOME/.nix-profile/share/applications" >/dev/null 2>&1 || true
    ${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
    ${pkgs.vicinae}/bin/vicinae server --replace >/dev/null 2>&1 &
  '';

  # IBus' default trigger is Super+Space (switch input method). There is only one engine, so it is
  # not needed, and it swallows Meta+Space before it reaches Karousel's "toggle floating".
  dconf.settings."desktop/ibus/general/hotkey" = {
    triggers = lib.hm.gvariant.mkEmptyArray lib.hm.gvariant.type.string;
  };

  # With the KWin-managed ibus-daemon (--panel disable) nobody selects an engine after login ("No global
  # engine" in the ibus log), so XIM clients such as Hancom Office only ever get Latin letters. Select the
  # Hangul engine once ibus is up; it keeps the Latin/Hangul toggle (Hangul key, Shift+Space) of the engine.
  xdg.configFile."autostart/ibus-select-hangul.desktop".text = let
    script = pkgs.writeShellScript "ibus-select-hangul" ''
      for _ in $(seq 1 40); do
        if ${pkgs.ibus}/bin/ibus engine hangul >/dev/null 2>&1; then exit 0; fi
        sleep 1
      done
    '';
  in ''
    [Desktop Entry]
    Type=Application
    Name=Select the Hangul engine in ibus
    Exec=${script}
    X-KDE-autostart-after=panel
  '';

  # Switch Korean/English with the Hangul key (it reaches the compositor as the
  # Hangul keysym, see the xkb options in home/plasma.nix) or Shift+Space.
  dconf.settings."desktop/ibus/engine/hangul" = {
    switch-keys = "Hangul,Shift+space";
    # Start in Hangul mode instead of Latin (the engine's default), so a freshly selected engine types Korean.
    initial-input-mode = "hangul";
  };
  # Vicinae launcher: Catppuccin Mocha. The daemon is started with the session; Alt+Space (set in
  # home/plasma.nix) runs `vicinae toggle`.
  xdg.configFile."vicinae/settings.json".text = builtins.toJSON {
    theme = {
      light = { name = "catppuccin-mocha"; icon_theme = "auto"; };
      dark = { name = "catppuccin-mocha"; icon_theme = "auto"; };
    };
  };
  xdg.configFile."autostart/vicinae.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Vicinae
    Exec=vicinae server --replace
    X-KDE-autostart-after=panel
  '';

  # Terminator with the Catppuccin Mocha palette. The file is a read-only symlink into the
  # store, so changes made in Terminator's preferences window are not saved; edit it here.
  xdg.configFile."terminator/config" = {
    force = true;
    text = ''
      [global_config]
        title_transmit_fg_color = "#cdd6f4"
        title_transmit_bg_color = "#313244"
        title_inactive_fg_color = "#a6adc8"
        title_inactive_bg_color = "#181825"
        title_receive_fg_color = "#1e1e2e"
        title_receive_bg_color = "#cba6f7"
        suppress_multiple_term_dialog = True
      [keybindings]
      [profiles]
        [[default]]
          use_system_font = False
          font = JetBrainsMono Nerd Font 11
          background_color = "#1e1e2e"
          foreground_color = "#cdd6f4"
          cursor_color = "#f5e0dc"
          palette = "#45475a:#f38ba8:#a6e3a1:#f9e2af:#89b4fa:#f5c2e7:#94e2d5:#bac2de:#585b70:#f38ba8:#a6e3a1:#f9e2af:#89b4fa:#f5c2e7:#94e2d5:#a6adc8"
          scrollback_infinite = True
          scrollbar_position = hidden
          show_titlebar = False
      [layouts]
        [[default]]
          [[[window0]]]
            type = Window
            parent = ""
          [[[terminal1]]]
            type = Terminal
            parent = window0
            profile = default
      [plugins]
    '';
  };
}
