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
    kdePackages.dolphin
    kdePackages.kate
    vscode
    brave
    spotify
    vlc
    kicad
    vmwareWindowMcp
    xwayland-satellite
    alsa-utils
    brightnessctl
    ffmpeg
    mpc
    wireplumber
    grim
    slurp
    wl-clipboard
    (writeShellScriptBin "screenshot-region" ''
      set -eu
      output_dir="$HOME/Pictures/Screenshots"
      mkdir -p "$output_dir"
      geometry="$(slurp)"
      [ -n "$geometry" ] || exit 0
      image="$output_dir/screenshot-$(date +%Y%m%d-%H%M%S).png"
      grim -g "$geometry" "$image"
      wl-copy --type image/png < "$image"
    '')
  ];

}
