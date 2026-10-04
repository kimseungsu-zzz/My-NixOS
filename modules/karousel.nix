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

  kw = "${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kwinrc --group Plugins --key karouselEnabled";
  kwinReconfigure = "${pkgs.systemd}/bin/busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure";

  # Reload the script the way System Settings does it (switch the plugin off and on and let KWin
  # reconfigure). Loading the QML file by hand leaves the script half-working.
  karouselReload = pkgs.writeShellScriptBin "karousel-reload" ''
    ${kw} false && ${kwinReconfigure}
    sleep 2
    ${kw} true && ${kwinReconfigure}
    echo "reloaded: ${karousel}"
  '';

  # Where is the active window? (HDMI is above the laptop panel: y < 1440 is HDMI, y >= 1440 is the laptop.)
  karouselWhere = pkgs.writeShellScriptBin "karousel-where" ''
    ${pkgs.kdotool}/bin/kdotool getactivewindow getwindowgeometry
  '';
in
{
  environment.systemPackages = [ karousel karouselReload karouselWhere ];
}
