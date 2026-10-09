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
  # Puts an image on the clipboard as PNG and BMP (Wine programs paste the BMP).
  copyImage = pkgs.callPackage ./copy-image { };
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
    xwayland-satellite
    alsa-utils
    brightnessctl
    ffmpeg
    mpc
    wireplumber
    grim
    slurp
    wl-clipboard
    copyImage
    (writeShellScriptBin "screenshot-region" ''
      set -eu
      output_dir="$HOME/Pictures/Screenshots"
      mkdir -p "$output_dir"
      geometry="$(slurp)"
      [ -n "$geometry" ] || exit 0
      image="$output_dir/screenshot-$(date +%Y%m%d-%H%M%S).png"
      grim -g "$geometry" "$image"
      ${copyImage}/bin/copy-image "$image"
    '')
  ];

}
