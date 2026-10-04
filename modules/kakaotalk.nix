# KakaoTalk on Wine. Package: github.com/kimseungsu-zzz/nixos-kakaotalk
# The upstream flake keeps the Wine prefix in $PWD/.wine (it is a dev environment), so the
# commands are wrapped here to default the prefix to a fixed per-user directory.
kakaotalk:
{ pkgs, ... }:

let
  upstream = kakaotalk.packages.${pkgs.stdenv.hostPlatform.system};

  prefix = ''export WINEPREFIX="''${WINEPREFIX:-$HOME/.local/share/kakaotalk}"'';

  run = pkgs.writeShellScriptBin "kakaotalk" ''
    ${prefix}
    exec ${upstream.kakaotalk}/bin/kakaotalk "$@"
  '';

  install = pkgs.writeShellScriptBin "kakaotalk-install" ''
    ${prefix}
    exec ${upstream.kakaotalk-install}/bin/kakaotalk-install "$@"
  '';

  desktop = pkgs.makeDesktopItem {
    name = "kakaotalk";
    desktopName = "KakaoTalk";
    exec = "kakaotalk";
    categories = [ "Network" "InstantMessaging" ];
    terminal = false;
  };
in
{
  environment.systemPackages = [ run install desktop upstream.kakaotalk-window-info ];

  # The wrapper runs with LANG/LC_ALL=ko_KR.UTF-8.
  i18n.extraLocales = [ "ko_KR.UTF-8/UTF-8" ];
}
