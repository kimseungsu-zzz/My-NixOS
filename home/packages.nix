{ pkgs, ... }:

{
  # User-level GUI applications.
  home.packages = with pkgs; [
    kdePackages.kate
    vscode
    brave
    spotify
    vlc
    kicad
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
