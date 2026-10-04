{ pkgs, ... }:

let
  # nixpkgs wraps OrcaSlicer with WEBKIT_DISABLE_COMPOSITING_MODE=1. With webkitgtk 2.54 that
  # makes the embedded web pages (the Home/login pages) abort in
  # NonCompositedFrameRenderer -> FrameRenderer::graphicsLayerFactory as soon as a page needs
  # compositing. Drop that line from the wrapper instead of rebuilding OrcaSlicer.
  orca-slicer = pkgs.symlinkJoin {
    name = "orca-slicer-webkit-fix";
    paths = [ pkgs.orca-slicer ];
    postBuild = ''
      real="$(readlink -f $out/bin/orca-slicer)"
      rm $out/bin/orca-slicer
      grep -v WEBKIT_DISABLE_COMPOSITING_MODE "$real" > $out/bin/orca-slicer
      chmod +x $out/bin/orca-slicer
    '';
  };
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
    orca-slicer
    vicinae
  ];
}
