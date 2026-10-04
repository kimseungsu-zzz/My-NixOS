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
in
{
  environment.systemPackages = [ karousel ];
}
