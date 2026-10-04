{ pkgs, karouselMultimonitor, ... }:

let
  # Fork with one scrolling grid per screen and virtual desktop (github.com/kimseungsu-zzz/
  # karousel-multimonitor). Built like nixpkgs' karousel, but its Makefile/run-ts.sh call
  # `pnpm exec tsc`, which is replaced by the plain `tsc` from nixpkgs.
  karousel = pkgs.stdenv.mkDerivation {
    pname = "karousel-multimonitor";
    version = "git";
    src = karouselMultimonitor;

    nativeBuildInputs = [
      pkgs.kdePackages.kpackage
      pkgs.nodejs
      pkgs.typescript
    ];
    buildInputs = [ pkgs.kdePackages.kwin ];
    dontWrapQtApps = true;

    postPatch = ''
      patchShebangs run-ts.sh
      substituteInPlace run-ts.sh --replace-fail "pnpm exec tsc" "tsc"
    '';

    buildPhase = ''
      runHook preBuild
      tsc -p ./src/main --outFile ./package/contents/code/main.js
      mkdir -p ./package/contents/config
      ./run-ts.sh ./src/generators/config > ./package/contents/config/main.xml
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      kpackagetool6 --type=KWin/Script --install=./package --packageroot=$out/share/kwin/scripts
      runHook postInstall
    '';
  };

  busctl = "${pkgs.systemd}/bin/busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting";

  # Reload the script without logging out (KWin keeps the version it loaded at login in memory).
  karouselReload = pkgs.writeShellScriptBin "karousel-reload" ''
    ${busctl} unloadScript s karousel
    ${busctl} loadDeclarativeScript ss ${karousel}/share/kwin/scripts/karousel/contents/ui/main.qml karousel
    ${busctl} start
    echo "loaded: ${karousel}"
  '';

  # Where is the active window? (HDMI is above the laptop panel: y < 1440 is HDMI, y >= 1440 is the laptop.)
  karouselWhere = pkgs.writeShellScriptBin "karousel-where" ''
    ${pkgs.kdotool}/bin/kdotool getactivewindow getwindowgeometry
  '';
in
{
  environment.systemPackages = [ karousel karouselReload karouselWhere ];
}
