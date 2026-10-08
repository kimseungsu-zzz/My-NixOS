{ pkgs, ... }:
let
  vmwareMcpPython = pkgs.python3.withPackages (pythonPackages: [
    pythonPackages.mcp
    pythonPackages.dbus-next
  ]);
  vmwareWindowMcp = pkgs.writeShellScriptBin "vmware-window-mcp" ''
    export PATH="${pkgs.lib.makeBinPath [ pkgs.xdotool pkgs.gst_all_1.gstreamer ]}:$PATH"
    export GST_PLUGIN_SYSTEM_PATH_1_0="${pkgs.pipewire}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-good}/lib/gstreamer-1.0"
    exec ${vmwareMcpPython}/bin/python3 ${./vmware-window-mcp}/server.py "$@"
  '';
in
{
  # User-level GUI applications.
  home.packages = with pkgs; [
    kdePackages.kate
    vscode
    brave
    spotify
    vlc
    kicad
    vmwareWindowMcp
    vicinae
    eww
    alsa-utils
    brightnessctl
    ffmpeg
    mpc
    networkmanagerapplet
    wireplumber
  ];

}
