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

  # Prints what KWin itself reports about screens, the pointer and the windows (put on the clipboard and
  # printed), to see which values Karousel is given.
  kwinDumpJs = pkgs.writeText "kwin-dump.js" ''
    var out = [];
    var scr = workspace.screens;
    for (var i = 0; i < scr.length; i++) {
        var g = scr[i].geometry;
        out.push("screen" + i + " " + scr[i].name + " " + g.x + "," + g.y + " " + g.width + "x" + g.height);
    }
    out.push("cursor " + Math.round(workspace.cursorPos.x) + "," + Math.round(workspace.cursorPos.y));
    out.push("activeScreen " + workspace.activeScreen.name);
    var ws = workspace.windowList ? workspace.windowList() : workspace.windows;
    for (var j = 0; j < ws.length; j++) {
        var w = ws[j];
        if (!w.normalWindow) continue;
        var f = w.frameGeometry;
        out.push("win[" + String(w.caption).substring(0, 14) + "] frame " + Math.round(f.x) + "," + Math.round(f.y) + " " + Math.round(f.width) + "x" + Math.round(f.height) + " output=" + (w.output ? w.output.name : "none"));
    }
    callDBus("org.kde.klipper", "/klipper", "org.kde.klipper.klipper", "setClipboardContents", out.join(" || "));
  '';

  karouselDump = pkgs.writeShellScriptBin "kwin-dump" ''
    ${busctl} unloadScript s kwin-dump >/dev/null 2>&1 || true
    ${busctl} loadScript ss ${kwinDumpJs} kwin-dump >/dev/null
    ${busctl} start >/dev/null
    sleep 1
    ${pkgs.systemd}/bin/busctl --user call org.kde.klipper /klipper org.kde.klipper.klipper getClipboardContents | tr '|' '
' | sed 's/^ *//'
    ${busctl} unloadScript s kwin-dump >/dev/null 2>&1 || true
  '';

  # Same as kwin-dump but run as a QML script, i.e. in the environment Karousel itself runs in (the
  # screens list can look different there). The values are computed once when the script is created.
  kwinDumpQml = pkgs.writeText "kwin-dump.qml" ''
    import QtQuick 6.0
    import org.kde.kwin 3.0

    Item {
        function info() {
            var out = [];
            var s = Workspace.screens;
            out.push("len=" + s.length + " isArray=" + Array.isArray(s) + " find=" + (typeof s.find) + " map=" + (typeof s.map));
            for (var i = 0; i < s.length; i++) {
                out.push(s[i].name + " " + s[i].geometry.x + "," + s[i].geometry.y + " " + s[i].geometry.width + "x" + s[i].geometry.height);
            }
            var c = Workspace.cursorPos;
            out.push("cursor " + Math.round(c.x) + "," + Math.round(c.y));
            out.push("active=" + Workspace.activeScreen.name);
            var w = Workspace.windows;
            out.push("windows=" + (w ? w.length : -1));
            return out.join(" | ");
        }

        DBusCall {
            service: "org.kde.klipper"
            path: "/klipper"
            dbusInterface: "org.kde.klipper.klipper"
            method: "setClipboardContents"
            arguments: [info()]
            Component.onCompleted: call()
        }
    }
  '';

  karouselDumpQml = pkgs.writeShellScriptBin "kwin-dump-qml" ''
    ${busctl} unloadScript s kwin-dump-qml >/dev/null 2>&1 || true
    ${busctl} loadDeclarativeScript ss ${kwinDumpQml} kwin-dump-qml >/dev/null
    ${busctl} start >/dev/null
    sleep 1
    ${pkgs.systemd}/bin/busctl --user call org.kde.klipper /klipper org.kde.klipper.klipper getClipboardContents | tr '|' '
'
    ${busctl} unloadScript s kwin-dump-qml >/dev/null 2>&1 || true
  '';
in
{
  environment.systemPackages = [ karousel karouselReload karouselWhere karouselDump karouselDumpQml ];
}
