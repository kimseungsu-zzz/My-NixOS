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
      cp "$real" $out/bin/orca-slicer
      chmod u+w,+x $out/bin/orca-slicer
      # The wrapper is a compiled binary (makeBinaryWrapper), so editing a line is not possible:
      # rename the variable in place (same length) so it sets an unused name instead.
      LC_ALL=C sed -i 's/WEBKIT_DISABLE_COMPOSITING_MODE/WEBKIT_DISABLE_COMPOSITING_MODX/g' $out/bin/orca-slicer
      if LC_ALL=C grep -q WEBKIT_DISABLE_COMPOSITING_MODE $out/bin/orca-slicer; then
        echo "orca-slicer wrapper still sets WEBKIT_DISABLE_COMPOSITING_MODE" >&2; exit 1
      fi
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
