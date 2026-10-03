{ ... }:

{
  imports = [
    ./home/plasma.nix
    ./home/packages.nix
  ];

  home.stateVersion = "26.05";

  # ibus-hangul: switch between Korean and English with the Hangul key (it reaches
  # the compositor as the Hangul keysym, see xkb options in home/plasma.nix).
  dconf.settings."org/freedesktop/ibus/engine/hangul" = {
    switch-keys = "Hangul,Shift+space";
  };
}
