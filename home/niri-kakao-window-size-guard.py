#!/usr/bin/env python3
"""Correct oversized KakaoTalk windows once after they finish opening."""

import json
import math
import subprocess
import time


POLL_INTERVAL = 0.25
SETTLE_SECONDS = 1.0
SIZE_TOLERANCE = 100
TARGETS = {
    "main": (1200, 900),
    "chat": (900, 700),
}


def niri_json(*args: str):
    result = subprocess.run(
        ["niri", "msg", "-j", *args],
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout)


def snapshot():
    windows = niri_json("windows")
    workspaces = niri_json("workspaces")
    outputs = niri_json("outputs")
    workspace_output = {workspace["id"]: workspace["output"] for workspace in workspaces}
    return windows, workspace_output, outputs


def target_for(window: dict):
    if window.get("app_id") != "kakaotalk.exe":
        return None
    if not window.get("title"):
        return None
    return TARGETS["main"] if window.get("title") == "카카오톡" else TARGETS["chat"]


def geometry(window: dict):
    size = window.get("layout", {}).get("window_size")
    if not size or len(size) != 2:
        return None
    return tuple(round(value) for value in size)


def resize_delta(window_id: int, axis: str, current: int, target: int, output_extent: int):
    delta = target - current
    if abs(delta) <= SIZE_TOLERANCE or output_extent <= 0:
        return
    percent = max(1, math.ceil(abs(delta) * 100 / output_extent))
    signed_percent = f"-{percent}%" if delta < 0 else f"+{percent}%"
    subprocess.run(
        ["niri", "msg", "action", f"set-window-{axis}", "--id", str(window_id), signed_percent],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )


def correct_window(window: dict, workspace_output: dict, outputs: dict):
    target = target_for(window)
    current = geometry(window)
    if target is None or current is None:
        return False

    # Leave normally sized windows alone. In particular, never constrain a
    # window after this one-time opening check; users remain free to resize it.
    if current[0] <= target[0] + SIZE_TOLERANCE and current[1] <= target[1] + SIZE_TOLERANCE:
        return False

    output_name = workspace_output.get(window.get("workspace_id"))
    output = outputs.get(output_name, {})
    logical = output.get("logical", {})
    resize_delta(window["id"], "width", current[0], target[0], logical.get("width", 0))
    resize_delta(window["id"], "height", current[1], target[1], logical.get("height", 0))
    return True


def main():
    observed = {}
    handled = set()
    attempts = {}
    while True:
        try:
            windows, workspace_output, outputs = snapshot()
            live_ids = set()
            now = time.monotonic()
            for window in windows:
                if target_for(window) is None:
                    continue
                window_id = window["id"]
                live_ids.add(window_id)
                if window_id in handled:
                    continue
                current_geometry = geometry(window)
                if current_geometry is None:
                    continue
                previous = observed.get(window_id)
                if previous is None or previous[0] != current_geometry:
                    observed[window_id] = (current_geometry, now)
                    continue
                if now - previous[1] < SETTLE_SECONDS:
                    continue
                if attempts.get(window_id, 0) < 2 and correct_window(window, workspace_output, outputs):
                    attempts[window_id] = attempts.get(window_id, 0) + 1
                    observed.pop(window_id, None)
                else:
                    handled.add(window_id)
                    observed.pop(window_id, None)
            for window_id in set(observed) - live_ids:
                observed.pop(window_id, None)
        except (KeyError, TypeError, ValueError, json.JSONDecodeError, OSError, subprocess.SubprocessError):
            pass
        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    main()
