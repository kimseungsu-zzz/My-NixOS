{ lib, pkgs, ... }:

let
  ewwPath = lib.makeBinPath (with pkgs; [ eww alsa-utils brightnessctl playerctl networkmanagerapplet ffmpeg mpc wireplumber ]);
  startEwwWidgets = pkgs.writeShellScript "start-eww-widgets" ''
    export PATH="${ewwPath}:$PATH"
    ${pkgs.eww}/bin/eww --config "$HOME/.config/eww/bar" daemon
    ${pkgs.eww}/bin/eww --config "$HOME/.config/eww/leftbar" daemon
    for config in bar leftbar; do
      for _ in $(${pkgs.coreutils}/bin/seq 1 40); do
        if ${pkgs.eww}/bin/eww --config "$HOME/.config/eww/$config" ping >/dev/null 2>&1; then break; fi
        ${pkgs.coreutils}/bin/sleep 0.25
      done
    done
    ${pkgs.eww}/bin/eww --config "$HOME/.config/eww/bar" open bar --screen HDMI-A-1
    for window in main pfp song sys_usg song_prog song_ctl audio quote sys_tray time; do
      ${pkgs.eww}/bin/eww --config "$HOME/.config/eww/leftbar" open "$window" --screen HDMI-A-1
    done
  '';
  stopEwwWidgets = pkgs.writeShellScript "stop-eww-widgets" ''
    ${pkgs.eww}/bin/eww --config "$HOME/.config/eww/bar" kill || true
    ${pkgs.eww}/bin/eww --config "$HOME/.config/eww/leftbar" kill || true
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

  # Upstream widgets by saimoomedits, kept in their original layout and styling.
  xdg.configFile."eww/bar".source = ./home/eww-widgets/bar;
  xdg.configFile."eww/leftbar".source = ./home/eww-widgets/leftbar;

  # Keep Eww in a persistent user service. KDE's XDG-autostart units kill
  # child processes when their short-lived Exec script exits, which stopped
  # the daemon immediately after opening the widget.
  systemd.user.services.eww-desktop-widget = {
    Unit = {
      Description = "Eww widgets from saimoomedits/eww-widgets";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${startEwwWidgets}";
      ExecStop = "${stopEwwWidgets}";
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
