#!/usr/bin/env bash
# Autodesk Fusion 360 on NixOS, in an Ubuntu distrobox that is kept apart from
# the host as far as distrobox allows.
#
# Isolation:
#   - The container gets its own HOME ($BOX_HOME), so your real home (documents,
#     ssh keys, browser profiles, ~/.config ...) is not mounted into it. Fusion,
#     the Wine prefix and the container's Firefox all live under $BOX_HOME.
#   - --unshare-process hides the host's processes from the container.
#   - Nothing is installed on or written to the NixOS side except the menu entry.
#   Not blocked (distrobox always does this): the host root is reachable at
#   /run/host, and the display, audio and GPU sockets are shared. This keeps
#   Fusion off your files by default, it is not a security sandbox. For that,
#   run it in a VM.
#
# Firefox is installed inside the container on purpose: the Autodesk sign-in
# callback has to reach the Wine process, and a host browser does not reliably
# do that.
#
# Usage:
#   ./setup.sh              # create container + install everything
#   ./setup.sh launch       # launch Fusion 360 (after setup)
#   ./setup.sh fix-browser  # sign-in link does not open Firefox
#   ./setup.sh uninstall    # remove the container (keeps $BOX_HOME)
#   ./setup.sh purge        # remove the container AND $BOX_HOME (several GB)

set -euo pipefail

CONTAINER_NAME="fusion360"
CONTAINER_IMAGE="ubuntu:24.04"
INSTALLER_URL="https://codeberg.org/cryinkfly/Autodesk-Fusion-360-on-Linux/raw/branch/main/files/setup/autodesk_fusion_installer_x86-64.sh"

# The container's HOME. distrobox mounts it at the same path inside, so every
# path below is valid on both sides.
BOX_HOME="${FUSION360_HOME:-$HOME/.local/share/fusion360-box}"
INSTALL_DIR="$BOX_HOME/fusion360-installer"
WINEPREFIX_PATH="$BOX_HOME/.autodesk_fusion/wineprefixes/default"
WINE_BUILD_DIR="$BOX_HOME/fusion-wine-build"
BIN_DIR="$BOX_HOME/.local/share/fusion360-bin"

log() { echo -e "\033[1;32m[setup]\033[0m $*"; }

for cmd in distrobox podman; do
  command -v "$cmd" >/dev/null || {
    echo "$cmd not found. Enable it in configuration.nix (see fusion360/README.md)." >&2
    exit 1
  }
done

# Plasma 6 on Wayland starts XWayland on demand; a terminal opened before that
# can lack DISPLAY even though the :0 socket is there.
if [ -z "${DISPLAY:-}" ] && [ -S /tmp/.X11-unix/X0 ]; then
  export DISPLAY=:0
fi
if [ -z "${DISPLAY:-}" ]; then
  echo "DISPLAY is not set and no X socket was found. Run this from Konsole in the KDE session (not over ssh or a TTY)." >&2
  exit 1
fi

# Passed into the container; distrobox shares the host's /run/user and /tmp/.X11-unix.
ENV_ARGS=(env "DISPLAY=$DISPLAY")
if [ -n "${XAUTHORITY:-}" ]; then
  ENV_ARGS+=("XAUTHORITY=$XAUTHORITY")
elif [ -f "$HOME/.Xauthority" ]; then
  ENV_ARGS+=("XAUTHORITY=$HOME/.Xauthority")
fi

in_box() { distrobox enter "$CONTAINER_NAME" -- "$@"; }
in_box_env() { distrobox enter "$CONTAINER_NAME" -- "${ENV_ARGS[@]}" "$@"; }

# The container's xdg-open is a distrobox shim that hands URLs to the HOST, so
# the sign-in link Wine opens never reaches the Firefox installed in the
# container (or opens nothing at all). This wrapper sits first in PATH for the
# Fusion launcher and opens web links with the container's Firefox instead.
install_browser_wrapper() {
  mkdir -p "$BIN_DIR"
  cat > "$BIN_DIR/xdg-open" <<'WRAP'
#!/bin/sh
case "$1" in
  http://*|https://*) exec firefox "$1" ;;
  *) exec /usr/bin/xdg-open "$@" ;;
esac
WRAP
  # Runs inside the container, where HOME is $BOX_HOME.
  cat > "$BIN_DIR/fusion-launch" <<'WRAP'
#!/bin/sh
export BROWSER=firefox
export PATH="$HOME/.local/share/fusion360-bin:$PATH"
exec "$HOME/.autodesk_fusion/bin/autodesk_fusion_launcher.sh" "$@"
WRAP
  chmod +x "$BIN_DIR/xdg-open" "$BIN_DIR/fusion-launch"
}

# The installer's own shortcut lands in $BOX_HOME, which the host menu does not
# read, so write one on the host that enters the container. No DISPLAY or
# XAUTHORITY here: a desktop launcher starts inside the session.
write_menu_entry() {
  local distrobox_bin; distrobox_bin="$(command -v distrobox)"
  local dir="$HOME/.local/share/applications"
  mkdir -p "$dir"
  cat > "$dir/autodesk-fusion-360.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Autodesk Fusion 360
Comment=Fusion 360 in the isolated distrobox '$CONTAINER_NAME'
Exec=$distrobox_bin enter $CONTAINER_NAME -- $BIN_DIR/fusion-launch
Icon=applications-engineering
Categories=Graphics;Engineering;
Terminal=false
StartupNotify=true
EOF
  update-desktop-database "$dir" 2>/dev/null || true
}

case "${1:-install}" in

install)
  mkdir -p "$BOX_HOME"
  CREATE_ARGS=(
    --name "$CONTAINER_NAME" --image "$CONTAINER_IMAGE" --yes
    --home "$BOX_HOME"      # own HOME: the real home is not mounted
    --unshare-process       # host processes are not visible
    --no-entry              # no auto-generated host menu entry for the container
  )
  if [ -e /dev/nvidiactl ]; then
    log "NVIDIA GPU detected; creating the container with --nvidia."
    CREATE_ARGS+=(--nvidia)
  fi

  log "Creating distrobox container '$CONTAINER_NAME' ($CONTAINER_IMAGE), HOME=$BOX_HOME ..."
  distrobox create "${CREATE_ARGS[@]}"

  log "Verifying glibc version inside the container (need >= 2.38 for the fix runtime)..."
  in_box ldd --version | head -1

  log "Installing base dependencies..."
  in_box sudo apt-get update
  in_box sudo apt-get install -y curl wget mokutil gettext-base

  log "Installing real (non-snap) Firefox from Mozilla's apt repo, INSIDE the container..."
  in_box bash -c '
    sudo install -d -m 0755 /etc/apt/keyrings
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list
    printf "Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n" | sudo tee /etc/apt/preferences.d/mozilla
    sudo apt-get update
    sudo apt-get install -y firefox
  '

  log "Downloading the Fusion 360 installer script..."
  in_box mkdir -p "$INSTALL_DIR"
  in_box bash -c "
    cd '$INSTALL_DIR' &&
    curl -L '$INSTALLER_URL' -o autodesk_fusion_installer_x86-64.sh &&
    chmod +x autodesk_fusion_installer_x86-64.sh
  "

  log "Running the installer with the Wine Z-window fix runtime (--install-fix)..."
  log "This downloads a prebuilt Wine runtime + Fusion 360 + WebView2 (~2GB); it will take a while."
  in_box_env bash -c "cd '$INSTALL_DIR' && ./autodesk_fusion_installer_x86-64.sh --install-fix --default"

  log "Installing DXVK into the Fusion Wine prefix..."
  in_box env \
    WINEPREFIX="$WINEPREFIX_PATH" \
    WINE="$WINE_BUILD_DIR/bin/wine" \
    WINESERVER="$WINE_BUILD_DIR/bin/wineserver" \
    PATH="$WINE_BUILD_DIR/bin:$PATH" \
    "$BOX_HOME/.autodesk_fusion/bin/winetricks" -q dxvk

  log "Wiring the container's Firefox in as the browser, and adding the menu entry..."
  install_browser_wrapper
  write_menu_entry

  log "Done. Start 'Autodesk Fusion 360' from the KDE menu or run '$0 launch'."
  ;;

launch)
  log "Launching Fusion 360 inside '$CONTAINER_NAME'..."
  install_browser_wrapper
  in_box_env "$BIN_DIR/fusion-launch"
  ;;

fix-browser)
  log "Installing the xdg-open wrapper and updating the menu entry..."
  install_browser_wrapper
  write_menu_entry
  log "Done. Start Fusion with '$0 launch' and try the sign-in again."
  ;;

uninstall)
  log "Removing distrobox container '$CONTAINER_NAME'..."
  distrobox rm --force "$CONTAINER_NAME"
  rm -f "$HOME/.local/share/applications/autodesk-fusion-360.desktop"
  log "$BOX_HOME (Fusion install, Wine prefix, Firefox profile) was NOT removed."
  log "For a full cleanup run '$0 purge'."
  ;;

purge)
  distrobox rm --force "$CONTAINER_NAME" 2>/dev/null || true
  rm -f "$HOME/.local/share/applications/autodesk-fusion-360.desktop"
  case "$BOX_HOME" in
    "$HOME"/*) rm -rf "$BOX_HOME"; log "Removed $BOX_HOME." ;;
    *) echo "Refusing to delete $BOX_HOME: it is not inside $HOME." >&2; exit 1 ;;
  esac
  ;;

*)
  echo "Usage: $0 [install|launch|fix-browser|uninstall|purge]"
  exit 1
  ;;
esac
