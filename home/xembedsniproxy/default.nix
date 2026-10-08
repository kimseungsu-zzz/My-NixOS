# KDE's XEmbed -> StatusNotifierItem tray bridge, built on its own from plasma-workspace, so
# X11 tray icons (Wine apps such as KakaoTalk) show up in Noctalia's bar.
#
# The patch gives the bridge's invisible container window a WM_CLASS: KWin hides it through
# _NET_WM_WINDOW_OPACITY, but xwayland-satellite ignores that and maps it as an ordinary
# window with no app-id, which niri rules cannot match (see home/niri.nix).
{ kdePackages }:

kdePackages.plasma-workspace.overrideAttrs (old: {
  pname = "xembedsniproxy";
  patches = (old.patches or [ ]) ++ [ ./wm-class.patch ];
  outputs = [ "out" ];

  buildPhase = ''
    runHook preBuild
    cmake --build . --target xembedsniproxy --parallel "$NIX_BUILD_CORES"
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    install -Dm755 bin/xembedsniproxy $out/bin/xembedsniproxy
    runHook postInstall
  '';
  postInstall = "";
  postFixup = "";
  doCheck = false;
  doInstallCheck = false;
  separateDebugInfo = false;
})
