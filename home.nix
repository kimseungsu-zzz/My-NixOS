{ ... }:

{
  imports = [
    ./home/plasma.nix
    ./home/packages.nix
  ];

  home.stateVersion = "26.05";

  # ibus-hangul: switch between Korean and English with the Hangul key (it reaches
  # the compositor as the Hangul keysym, see xkb options in home/plasma.nix).
  # Register the engine so ibus actually switches to it (only preloaded engines are used).
  dconf.settings."org/freedesktop/ibus/general" = {
    preload-engines = [ "hangul" ];
    engines-order = [ "hangul" ];
  };

  dconf.settings."org/freedesktop/ibus/engine/hangul" = {
    switch-keys = "Hangul,Shift+space";
  };
}
