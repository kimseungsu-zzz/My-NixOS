{ pkgs, nix-packages, ... }:

{
  home.packages = [ nix-packages.packages.${pkgs.system}.fusion360 ];
}
