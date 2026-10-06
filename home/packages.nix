{ pkgs, spotifast, ... }:
{
  # User-level GUI applications.
  home.packages = with pkgs; [
    kdePackages.kate
    vscode
    brave
    spotifast.packages.${pkgs.stdenv.hostPlatform.system}.default
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
