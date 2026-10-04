{ pkgs, ... }:

{
  # User-level GUI applications.
  # (OrcaSlicer is a Flatpak, declared in modules/desktop.nix: the nixpkgs build crashes on webkitgtk 2.54.)
  home.packages = with pkgs; [
    kdePackages.kate
    vscode
    brave
    spotify
    vlc
    kicad
    vicinae
  ];
}
