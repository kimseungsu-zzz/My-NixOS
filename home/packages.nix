{ pkgs, ... }:
let
  vmwareMcpPython = pkgs.python3.withPackages (pythonPackages: [ pythonPackages.mcp ]);
  vmwareWindowMcp = pkgs.writeShellScriptBin "vmware-window-mcp" ''
    export PATH="${pkgs.lib.makeBinPath [ pkgs.xdotool pkgs.grim ]}:$PATH"
    exec ${vmwareMcpPython}/bin/python3 ${./vmware-window-mcp/server.py} "$@"
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
