# copy-image IMAGE: put an image on the Wayland clipboard as PNG and BMP at once.
#
# wl-copy offers one MIME type. Wine turns image/bmp into CF_DIB but does not paste image/png into
# Windows programs such as KakaoTalk; xwayland-satellite passes every offered type on to X11.
{ stdenv, lib, symlinkJoin, writeShellScriptBin, pkg-config, wayland, wayland-scanner
, wayland-protocols, imagemagick }:

let
  wlCopyTypes = stdenv.mkDerivation {
    name = "wl-copy-types";
    src = ./wl-copy-types.c;
    dontUnpack = true;
    nativeBuildInputs = [ pkg-config wayland-scanner ];
    buildInputs = [ wayland ];
    buildPhase = ''
      xml=${wayland-protocols}/share/wayland-protocols/staging/ext-data-control/ext-data-control-v1.xml
      wayland-scanner client-header $xml ext-data-control-v1-client-protocol.h
      wayland-scanner private-code $xml ext-data-control-v1-protocol.c
      $CC -O2 -Wall -Werror -I. -o wl-copy-types $src ext-data-control-v1-protocol.c \
        $(pkg-config --cflags --libs wayland-client)
    '';
    installPhase = "install -Dm755 wl-copy-types $out/bin/wl-copy-types";
  };

  copyImage = writeShellScriptBin "copy-image" ''
    set -eu
    image="$1"
    bmp="$(mktemp --suffix=.bmp)"
    trap 'rm -f "$bmp"' EXIT
    # BMP3: 24-bit without alpha, what Windows programs expect from CF_DIB.
    ${imagemagick}/bin/magick "$image" BMP3:"$bmp"
    ${wlCopyTypes}/bin/wl-copy-types image/png="$image" image/bmp="$bmp"
  '';
in
symlinkJoin {
  name = "copy-image";
  paths = [ copyImage wlCopyTypes ];
}
