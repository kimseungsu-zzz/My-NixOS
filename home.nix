{ lib, pkgs, ... }:

let
  startEwwDesktopWidget = pkgs.writeShellScript "start-eww-desktop-widget" ''
    ${pkgs.eww}/bin/eww daemon || true
    for _ in $(${pkgs.coreutils}/bin/seq 1 20); do
      if ${pkgs.eww}/bin/eww open dashboard; then
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
  # Eww dashboard layout adapted to the compact clock and system modules in
  # https://github.com/saimoomedits/eww-widgets, arranged as three matching tiles.
  xdg.configFile."eww/eww.yuck".text = ''
    (defpoll clock :interval "1s" :initial "00:00" `date '+%-I:%M'`)
    (defpoll period :interval "1m" :initial "AM" `date '+%p'`)
    (defpoll today :interval "1m" :initial "Loading date" `date '+%A, %B %-d'`)
    (defpoll uptime :interval "1m" :initial "Checking uptime" `uptime -p | sed 's/^up //'`)

    (defwidget launch-tile [symbol name command icon-class]
      (button :class "launch-tile" :onclick command
        (box :orientation "vertical" :spacing 10 :halign "center" :valign "center"
          (label :class icon-class :text symbol)
          (label :class "launch-name" :text name))))

    (defwidget metric-tile [name value progress-class]
      (box :orientation "vertical" :spacing 8
        (box :orientation "horizontal" :spacing 8
          (label :class "metric-name" :text name)
          (label :class "metric-value" :hexpand true :halign "end" :text {round(value, 0)})
          (label :class "metric-name" :text "%"))
        (progress :class progress-class :value value)))

    (defwidget dashboard-content []
      (box :class "dashboard" :orientation "horizontal" :spacing 16 :halign "center" :valign "center"
        (box :class "tile clock-tile" :orientation "vertical" :spacing 14
          (box :orientation "horizontal" :spacing 14 :valign "center"
            (label :class "clock" :text clock)
            (box :orientation "vertical" :spacing 3 :valign "center"
              (label :class "period" :text period)
              (label :class "date" :text today)))
          (box :class "divider")
          (label :class "tile-caption" :halign "start" :text "UPTIME")
          (label :class "uptime" :halign "start" :text uptime))
        (box :orientation "vertical" :spacing 16
          (box :class "tile welcome-tile" :orientation "vertical" :spacing 12
            (label :class "eyebrow" :halign "start" :text "ELKOWAR'S WACKY WIDGETS")
            (label :class "welcome-title" :halign "start" :text "Your desktop, at a glance")
            (label :class "welcome-copy" :halign "start" :text "Time, system status, and quick access."))
          (box :class "launch-row" :orientation "horizontal" :spacing 12
            (launch-tile :symbol "◉" :name "Browser" :command "zen" :icon-class "icon-blue")
            (launch-tile :symbol "F" :name "Fusion 360" :command "fusion360" :icon-class "icon-orange")
            (launch-tile :symbol "▣" :name "Files" :command "dolphin" :icon-class "icon-green")
            (launch-tile :symbol ">_" :name "Terminal" :command "terminator" :icon-class "icon-yellow")))
        (box :class "tile system-tile" :orientation "vertical" :spacing 20
          (label :class "tile-caption" :halign "start" :text "SYSTEM")
          (metric-tile :name "CPU" :value {EWW_CPU.avg} :progress-class "cpu-progress")
          (metric-tile :name "MEMORY" :value {EWW_RAM.used_mem_perc} :progress-class "ram-progress")
          (label :class "system-footnote" :halign "start" :text "Intel Arc graphics"))))

    (defwindow dashboard
      :monitor "[\"HDMI-A-1\", \"eDP-1\", 0]"
      :geometry (geometry :width "1600px" :height "740px" :anchor "center")
      :stacking "bottom"
      :exclusive false
      :focusable "ondemand"
      :windowtype "desktop"
      :namespace "eww-desktop-widget"
      (dashboard-content))
  '';

  xdg.configFile."eww/eww.scss".text = ''
    * {
      all: unset;
      font-family: Pretendard, sans-serif;
    }

    .dashboard { padding: 24px; }
    .tile {
      background-color: rgba(30, 32, 44, 0.90);
      border-radius: 11px;
      padding: 22px;
      box-shadow: 0 5px 16px rgba(8, 10, 18, 0.18);
    }
    .clock-tile { min-width: 340px; min-height: 260px; }
    .system-tile { min-width: 300px; min-height: 260px; }
    .welcome-tile { min-width: 690px; min-height: 155px; }
    .clock { color: #89b4fa; font-size: 78px; font-weight: 700; }
    .period { color: #a6e3a1; font-size: 28px; font-weight: 700; }
    .date { color: #f9e2af; font-size: 16px; }
    .divider { min-height: 1px; background-color: rgba(205, 214, 244, 0.12); margin: 4px 0; }
    .tile-caption { color: #a6adc8; font-size: 12px; font-weight: 700; letter-spacing: 1.5px; }
    .uptime { color: #cdd6f4; font-size: 21px; }
    .eyebrow { color: #a6adc8; font-size: 12px; font-weight: 700; letter-spacing: 1.5px; }
    .welcome-title { color: #cdd6f4; font-size: 32px; font-weight: 700; }
    .welcome-copy { color: #bac2de; font-size: 16px; }
    .launch-row { min-height: 130px; }
    .launch-tile {
      min-width: 126px;
      min-height: 120px;
      padding: 14px;
      border-radius: 9px;
      background-color: rgba(39, 42, 56, 0.96);
      box-shadow: 0 3px 10px rgba(8, 10, 18, 0.14);
    }
    .launch-tile:hover { background-color: rgba(69, 71, 90, 0.98); }
    .launch-name { color: #cdd6f4; font-size: 15px; font-weight: 700; }
    .icon-blue { color: #89b4fa; font-size: 38px; font-weight: 700; }
    .icon-orange { color: #fab387; font-size: 38px; font-weight: 700; }
    .icon-green { color: #a6e3a1; font-size: 38px; font-weight: 700; }
    .icon-yellow { color: #f9e2af; font-size: 34px; font-weight: 700; }
    .metric-name { color: #bac2de; font-size: 14px; font-weight: 700; }
    .metric-value { color: #cdd6f4; font-size: 14px; font-weight: 700; }
    progress, progress trough, progress progress {
      min-height: 12px;
      border-radius: 8px;
      background-color: rgba(205, 214, 244, 0.12);
    }
    .cpu-progress progress { background-color: #f38ba8; }
    .ram-progress progress { background-color: #a6e3a1; }
    .system-footnote { color: #a6adc8; font-size: 14px; }
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
