# copy-image IMAGE: put an image on the Wayland clipboard as PNG and BMP, plus the file itself.
#
# wl-copy offers one MIME type. Wine turns image/bmp into CF_DIB but does not paste image/png into
# Windows programs such as KakaoTalk; xwayland-satellite passes every offered type on to X11.
{ stdenv, lib, symlinkJoin, writeShellScriptBin, coreutils, pkg-config, wayland, wayland-scanner
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
    image="$(${coreutils}/bin/realpath "$1")"
    tmp="$(${coreutils}/bin/mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT

    # Percent-encode a path for a file:// URI.
    uri_encode() {
      local LC_ALL=C s="$1" out="" c hex i
      for ((i = 0; i < ''${#s}; i++)); do
        c="''${s:i:1}"
        case "$c" in
          [a-zA-Z0-9._~/-]) out+="$c" ;;
          *) printf -v hex '%%%02X' "'$c"; out+="$hex" ;;
        esac
      done
      printf '%s' "$out"
    }
    uri="file://$(uri_encode "$image")"

    # BMP3: 24-bit without alpha, what Windows programs expect from CF_DIB.
    ${imagemagick}/bin/magick "$image" BMP3:"$tmp/image.bmp"
    # File managers paste files, not pixels: also offer the file itself (Thunar reads
    # x-special/gnome-copied-files, other toolkits text/uri-list).
    printf '%s\r\n' "$uri" > "$tmp/uri-list"
    printf 'copy\n%s' "$uri" > "$tmp/gnome-copied-files"

    ${wlCopyTypes}/bin/wl-copy-types \
      image/png="$image" image/bmp="$tmp/image.bmp" \
      text/uri-list="$tmp/uri-list" x-special/gnome-copied-files="$tmp/gnome-copied-files"
  '';
in
symlinkJoin {
  name = "copy-image";
  paths = [ copyImage wlCopyTypes ];
}
