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
    exit 1
  '';
  stopEwwDesktopWidget = pkgs.writeShellScript "stop-eww-desktop-widget" ''
    ${pkgs.eww}/bin/eww kill >/dev/null 2>&1 || true
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

  # Eww is an independent dashboard layer over the empty Plasma desktop.
  xdg.configFile."eww/eww.yuck".text = ''
    (defpoll clock :interval "1s" :initial "00:00" `date '+%-I:%M'`)
    (defpoll period :interval "1s" :initial "AM" `date '+%p'`)
    (defpoll weekday :interval "1m" :initial "Loading…" `date '+%A'`)
    (defpoll calendar :interval "1m" :initial "" `date '+%B %-d, %Y'`)

    (defwidget launch-tile [symbol name command style]
      (button :class "launch-tile" :onclick command
        (box :orientation "vertical" :spacing 12
          (label :class style :text symbol)
          (label :class "launch-name" :text name))))

    (defwidget dashboard-content []
      (box :class "dashboard" :orientation "horizontal" :spacing 18
        (box :class "column left-column" :orientation "vertical" :spacing 18
          (box :class "tile profile-tile" :orientation "vertical" :spacing 16
            (label :class "profile-avatar" :text "L")
            (label :class "profile-name" :text "linux")
            (label :class "profile-subtitle" :text "NixOS  ·  KDE Plasma"))
          (box :class "tile meters-tile" :orientation "vertical" :spacing 18
            (label :class "section-heading" :text "SYSTEM LOAD")
            (box :class "meter-row" :orientation "vertical" :spacing 7
              (box :orientation "horizontal" :spacing 8
                (label :class "meter-name" :text "CPU")
                (label :class "meter-value cpu-value" :hexpand true :halign "end" :text {round(EWW_CPU.avg, 0)})
                (label :class "meter-name" :text "%"))
              (progress :class "cpu-progress" :value {EWW_CPU.avg}))
            (box :class "meter-row" :orientation "vertical" :spacing 7
              (box :orientation "horizontal" :spacing 8
                (label :class "meter-name" :text "MEMORY")
                (label :class "meter-value ram-value" :hexpand true :halign "end" :text {round(EWW_RAM.used_mem / 1073741824, 1)})
                (label :class "meter-name" :text "GB"))
              (progress :class "ram-progress" :value {EWW_RAM.used_mem_perc}))
            (label :class "small-note" :halign "start" :text "Intel Arc graphics")))
        (box :class "column main-column" :orientation "vertical" :spacing 18
          (box :orientation "horizontal" :spacing 18
            (box :class "tile clock-tile" :orientation "horizontal" :spacing 20
              (label :class "clock" :valign "center" :text clock)
              (box :class "time-meta" :orientation "vertical" :valign "center" :spacing 2
                (label :class "period" :text period)
                (label :class "weekday" :text weekday)))
            (box :class "tile date-tile" :orientation "vertical" :valign "center" :spacing 10
              (label :class "section-heading" :text "TODAY")
              (label :class "date" :halign "start" :text calendar)
              (label :class "small-note" :halign "start" :text "Your desktop, at a glance")))
          (box :class "tile welcome-tile" :orientation "vertical" :spacing 14
            (label :class "section-heading" :halign "start" :text "ELKOWAR'S WACKY WIDGETS")
            (label :class "welcome-title" :halign "start" :text "A calmer workspace.")
            (label :class "welcome-subtitle" :halign "start" :text "A little time, a little system status, and your everyday apps.")
            (box :class "status-line" :orientation "horizontal" :spacing 10
              (label :class "status-dot" :text "●")
              (label :class "status-text" :text "Wayland session  ·  Proton ready")))
          (box :class "launch-row" :orientation "horizontal" :spacing 14
            (launch-tile "◉" "Browser" "zen" "icon-blue")
            (launch-tile "F" "Fusion 360" "fusion360" "icon-orange")
            (launch-tile "▣" "Files" "dolphin" "icon-green")
            (launch-tile ">_" "Terminal" "terminator" "icon-yellow")))
        (box :class "column right-column" :orientation "vertical" :spacing 18
          (box :class "tile info-tile" :orientation "vertical" :spacing 16
            (label :class "section-heading" :halign "start" :text "WORKSTATION")
            (label :class "info-title" :halign "start" :text "Intel Arc")
            (label :class "small-note" :halign "start" :text "Dedicated graphics selected")
            (box :class "separator" :hexpand true)
            (label :class "section-heading" :halign "start" :text "DESKTOP")
            (label :class "info-title" :halign "start" :text "Breeze Dark")
            (label :class "small-note" :halign "start" :text "Soft Flow wallpaper"))
          (box :class "tile footer-tile" :orientation "vertical" :spacing 10
            (label :class "footer-brand" :halign "start" :text "NIXOS")
            (label :class "small-note" :halign "start" :text "Made for your desktop")))))

    (defwindow dashboard
      :monitor 0
      :geometry (geometry :width "1660px" :height "840px" :anchor "center")
      :stacking "bottom"
      :exclusive false
      :focusable "ondemand"
      :namespace "eww-desktop-widget"
      (dashboard-content))
  '';

  xdg.configFile."eww/eww.scss".text = ''
    * {
      all: unset;
      font-family: Pretendard, sans-serif;
    }

    .dashboard {
      padding: 34px;
    }

    .left-column { min-width: 300px; }
    .main-column { min-width: 900px; }
    .right-column { min-width: 300px; }

    .tile {
      background-color: rgba(30, 32, 44, 0.90);
      border: 1px solid rgba(205, 214, 244, 0.07);
      border-radius: 18px;
      padding: 28px;
      box-shadow: 0 7px 18px rgba(8, 10, 18, 0.22);
    }

    .profile-tile {
      min-height: 330px;
      halign: center;
      justify-content: center;
      background-color: rgba(39, 42, 56, 0.94);
    }

    .profile-avatar {
      min-width: 136px;
      min-height: 136px;
      border-radius: 100%;
      background-color: rgba(137, 180, 250, 0.16);
      color: #89b4fa;
      font-size: 72px;
      font-weight: 700;
    }

    .profile-name { color: #f5c2e7; font-size: 34px; font-weight: 700; }
    .profile-subtitle { color: #94e2d5; font-size: 19px; }
    .meters-tile { min-height: 330px; }

    .section-heading {
      color: #a6adc8;
      font-size: 14px;
      font-weight: 700;
      letter-spacing: 2px;
    }

    .meter-row { }
    .meter-name { color: #bac2de; font-size: 15px; font-weight: 700; }
    .meter-value { color: #cdd6f4; font-size: 16px; font-weight: 700; }
    .cpu-value { color: #f38ba8; }
    .ram-value { color: #a6e3a1; }
    progress { min-height: 18px; border-radius: 12px; background-color: rgba(205, 214, 244, 0.12); }
    progress trough { min-height: 18px; border-radius: 12px; background-color: rgba(205, 214, 244, 0.12); }
    progress progress { min-height: 18px; border-radius: 12px; }
    .cpu-progress progress { background-color: #f38ba8; }
    .ram-progress progress { background-color: #a6e3a1; }
    .small-note { color: #a6adc8; font-size: 16px; }

    .clock-tile { min-width: 495px; min-height: 150px; }
    .date-tile { min-width: 365px; min-height: 150px; }
    .clock { color: #89b4fa; font-size: 78px; font-weight: 700; }
    .time-meta { margin-left: 8px; }
    .period { color: #a6e3a1; font-size: 36px; font-weight: 700; }
    .weekday { color: #f9e2af; font-size: 22px; }
    .date { color: #cdd6f4; font-size: 36px; font-weight: 700; }

    .welcome-tile { min-height: 290px; justify-content: center; }
    .welcome-title { color: #cdd6f4; font-size: 46px; font-weight: 700; }
    .welcome-subtitle { color: #bac2de; font-size: 18px; }
    .status-line { margin-top: 16px; }
    .status-dot { color: #a6e3a1; font-size: 16px; }
    .status-text { color: #a6adc8; font-size: 16px; }

    .launch-row { min-height: 175px; }
    .launch-tile {
      min-width: 190px;
      min-height: 160px;
      padding: 16px;
      border-radius: 16px;
      background-color: rgba(39, 42, 56, 0.96);
      border: 1px solid rgba(205, 214, 244, 0.07);
      box-shadow: 0 5px 13px rgba(8, 10, 18, 0.18);
    }
    .launch-tile:hover { background-color: rgba(69, 71, 90, 0.98); }
    .launch-tile:active { background-color: rgba(88, 91, 112, 0.98); }
    .launch-name { color: #cdd6f4; font-size: 18px; font-weight: 700; }
    .icon-blue { color: #89b4fa; font-size: 50px; font-weight: 700; }
    .icon-orange { color: #fab387; font-size: 50px; font-weight: 700; }
    .icon-green { color: #a6e3a1; font-size: 50px; font-weight: 700; }
    .icon-yellow { color: #f9e2af; font-size: 42px; font-weight: 700; }

    .info-tile { min-height: 555px; justify-content: center; }
    .info-title { color: #cdd6f4; font-size: 32px; font-weight: 700; }
    .separator { min-height: 1px; background-color: rgba(205, 214, 244, 0.16); margin: 12px 0; }
    .footer-tile { min-height: 135px; justify-content: center; }
    .footer-brand { color: #f5c2e7; font-size: 26px; font-weight: 700; letter-spacing: 4px; }
  '';

  # Keep Eww in a persistent user service. KDE's XDG-autostart units kill
  # child processes when their short-lived Exec script exits, which stopped
  # the daemon immediately after opening the widget.
  systemd.user.services.eww-desktop-widget = {
    Unit = {
      Description = "Eww desktop widget";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${startEwwDesktopWidget}";
      ExecStop = "${stopEwwDesktopWidget}";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

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
  # Keep the Vicinae daemon under systemd so it is restarted reliably after every HM activation.
  programs.vicinae = {
    enable = true;
    package = pkgs.vicinae;
    systemd.enable = true;
  };

  # Vicinae launcher: Catppuccin Mocha. Alt+Space (set in home/plasma.nix) runs `vicinae toggle`.
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
