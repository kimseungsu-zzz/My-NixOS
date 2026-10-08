{ pkgs, nix-packages, ... }:

{
  home.packages = [ nix-packages.packages.${pkgs.stdenv.hostPlatform.system}.fusion360 ];
}
