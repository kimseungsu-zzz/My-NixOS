# Host configuration for linux. The settings live in ./modules.
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/system.nix
    ./modules/desktop.nix
    ./modules/apps.nix
  ];
}
