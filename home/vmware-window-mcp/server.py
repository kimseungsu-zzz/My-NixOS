#!/usr/bin/env python3
"""A narrowly scoped MCP bridge for visible VMware Workstation XWayland windows."""

from __future__ import annotations

import os
import re
import subprocess
from dataclasses import asdict, dataclass
from typing import Literal

from mcp.server.fastmcp import FastMCP, Image
from pipewire_capture import capture_pipewire_window


server = FastMCP("vmware-window")
MAX_TEXT_LENGTH = 2000
MAX_KEY_LENGTH = 64


@dataclass(frozen=True)
class VMwareWindow:
    window_id: str
    title: str
    window_class: str
    pid: int
    x: int
    y: int
    width: int
    height: int


def _run(args: list[str], *, timeout: float = 8, input_bytes: bytes | None = None) -> bytes:
    try:
        result = subprocess.run(
            args,
            input=input_bytes,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise RuntimeError(f"Could not run {os.path.basename(args[0])}: {exc}") from exc
    if result.returncode:
        detail = result.stderr.decode("utf-8", "replace").strip()
        raise RuntimeError(detail or f"{os.path.basename(args[0])} exited {result.returncode}")
    return result.stdout


def _window_geometry(window_id: str) -> tuple[int, int, int, int]:
    output = _run(["xdotool", "getwindowgeometry", "--shell", window_id]).decode()
    values = dict(re.findall(r"^(X|Y|WIDTH|HEIGHT)=(-?\d+)$", output, re.MULTILINE))
    if len(values) != 4:
        raise RuntimeError("xdotool did not return valid VMware window geometry")
    x, y, width, height = (int(values[key]) for key in ("X", "Y", "WIDTH", "HEIGHT"))
    if width < 1 or height < 1 or width > 16384 or height > 16384:
        raise RuntimeError("VMware window geometry is outside supported bounds")
    return x, y, width, height


def _is_vmware_window(window_id: str) -> tuple[bool, str, str, int]:
    try:
        title = _run(["xdotool", "getwindowname", window_id]).decode("utf-8", "replace").strip()
        window_class = _run(["xdotool", "getwindowclassname", window_id]).decode("utf-8", "replace").strip()
        pid = int(_run(["xdotool", "getwindowpid", window_id]).decode().strip())
    except (RuntimeError, ValueError):
        return False, "", "", 0

    try:
        executable = os.path.realpath(f"/proc/{pid}/exe").lower()
    except OSError:
        executable = ""
    name = os.path.basename(executable)
    vmware_process = name in {"vmware", "vmplayer", "vmware-vmx"} or "/vmware-workstation" in executable
    # VMware's Nix appLoader path does not have a vmware executable basename,
    # and XWayland can report its own PID. Its specific WM_CLASS/title pair is
    # therefore the reliable identity; avoid matching Fusion's steam_proton class.
    vmware_window_identity = (
        window_class.casefold() in {"vmware", "vmplayer"}
        and "vmware workstation" in title.casefold()
    )
    return vmware_window_identity or (vmware_process and "vmware" in title.casefold()), title, window_class, pid


def _all_windows() -> list[VMwareWindow]:
    output = _run(["xdotool", "search", "--onlyvisible", "--name", ".*"], timeout=5)
    found: list[VMwareWindow] = []
    for candidate in output.decode().splitlines():
        window_id = candidate.strip()
        if not window_id.isdecimal():
            continue
        is_vmware, title, window_class, pid = _is_vmware_window(window_id)
        if not is_vmware:
            continue
        try:
            x, y, width, height = _window_geometry(window_id)
        except RuntimeError:
            continue
        found.append(VMwareWindow(window_id, title, window_class, pid, x, y, width, height))
    return found


def _require_window(window_id: str) -> VMwareWindow:
    if not isinstance(window_id, str) or not window_id.isdecimal():
        raise ValueError("window_id must come from vmware_list_windows")
    for window in _all_windows():
        if window.window_id == window_id:
            return window
    raise ValueError("That window is not a visible VMware Workstation window")


def _activate(window: VMwareWindow) -> None:
    _run(["xdotool", "windowactivate", "--sync", window.window_id], timeout=5)
    focused = _run(["xdotool", "getwindowfocus"]).decode().strip()
    if focused != window.window_id:
        raise RuntimeError("VMware did not become the focused window; no input was sent")


def _point(window: VMwareWindow, x: int, y: int) -> None:
    if isinstance(x, bool) or isinstance(y, bool) or not isinstance(x, int) or not isinstance(y, int):
        raise ValueError("x and y must be integer coordinates relative to the VMware window")
    if not (0 <= x < window.width and 0 <= y < window.height):
        raise ValueError(f"Point is outside VMware window bounds ({window.width} x {window.height})")
    _run(["xdotool", "mousemove", "--sync", "--window", window.window_id, str(x), str(y)])


@server.tool()
def vmware_list_windows() -> dict:
    """List visible VMware Workstation windows that this controller can operate."""
    return {"windows": [asdict(window) for window in _all_windows()]}


@server.tool()
def vmware_capture_window(window_id: str) -> Image:
    """Capture VMware through the PipeWire portal; select VMware in its picker."""
    _require_window(window_id)
    png = capture_pipewire_window()
    return Image(data=png, format="png")


@server.tool()
def vmware_focus_window(window_id: str) -> dict:
    """Focus a visible VMware Workstation window."""
    window = _require_window(window_id)
    _activate(window)
    return {"focused": True, "window_id": window.window_id, "title": window.title}


@server.tool()
def vmware_click(
    window_id: str,
    x: int,
    y: int,
    button: Literal["left", "middle", "right"] = "left",
) -> dict:
    """Click inside VMware using window-relative coordinates; other windows are rejected."""
    window = _require_window(window_id)
    _activate(window)
    _point(window, x, y)
    button_id = {"left": "1", "middle": "2", "right": "3"}[button]
    _run(["xdotool", "click", "--clearmodifiers", button_id])
    return {"clicked": True, "window_id": window.window_id, "x": x, "y": y, "button": button}


@server.tool()
def vmware_scroll(window_id: str, x: int, y: int, direction: Literal["up", "down"], clicks: int = 3) -> dict:
    """Scroll inside VMware at a window-relative point."""
    if isinstance(clicks, bool) or not isinstance(clicks, int) or not 1 <= clicks <= 20:
        raise ValueError("clicks must be an integer from 1 to 20")
    window = _require_window(window_id)
    _activate(window)
    _point(window, x, y)
    button_id = "4" if direction == "up" else "5"
    _run(["xdotool", "click", "--repeat", str(clicks), "--delay", "70", button_id])
    return {"scrolled": True, "window_id": window.window_id, "direction": direction, "clicks": clicks}


@server.tool()
def vmware_drag(window_id: str, start_x: int, start_y: int, end_x: int, end_y: int) -> dict:
    """Drag within VMware, using coordinates relative to that window."""
    window = _require_window(window_id)
    _activate(window)
    _point(window, start_x, start_y)
    _run(["xdotool", "mousedown", "1"])
    try:
        _point(window, end_x, end_y)
    finally:
        _run(["xdotool", "mouseup", "1"])
    return {"dragged": True, "window_id": window.window_id, "from": [start_x, start_y], "to": [end_x, end_y]}


@server.tool()
def vmware_press_keys(window_id: str, key_combo: str) -> dict:
    """Send a key or chord such as Return, Escape, or Ctrl+Alt+Delete to VMware."""
    if not isinstance(key_combo, str) or len(key_combo) > MAX_KEY_LENGTH or not re.fullmatch(r"[A-Za-z0-9_+.-]+", key_combo):
        raise ValueError("key_combo contains unsupported characters")
    window = _require_window(window_id)
    _activate(window)
    _run(["xdotool", "key", "--clearmodifiers", "--", key_combo])
    return {"keys_sent": True, "window_id": window.window_id, "key_combo": key_combo}


@server.tool()
def vmware_type_text(window_id: str, text: str) -> dict:
    """Type plain text into VMware; never use this to enter a password or secret."""
    if not isinstance(text, str) or len(text) > MAX_TEXT_LENGTH:
        raise ValueError(f"text must be a string no longer than {MAX_TEXT_LENGTH} characters")
    window = _require_window(window_id)
    _activate(window)
    _run(["xdotool", "type", "--clearmodifiers", "--delay", "8", "--", text], timeout=30)
    return {"typed": True, "window_id": window.window_id, "characters": len(text)}


if __name__ == "__main__":
    server.run(transport="stdio")
