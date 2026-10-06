#!/usr/bin/env python3
"""Retry Niri size requests for newly-created KakaoTalk conversation windows."""

import json
import subprocess
import threading
import time


MIN_WIDTH = 900
MIN_HEIGHT = 700
VERIFY_SECONDS = 1.0
RETRY_SECONDS = 0.5

active: set[int] = set()
active_lock = threading.Lock()


def windows() -> list[dict]:
    result = subprocess.run(
        ["niri", "msg", "-j", "windows"],
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout)


def request_size(window_id: int) -> None:
    for dimension, value in (("width", MIN_WIDTH), ("height", MIN_HEIGHT)):
        subprocess.run(
            ["niri", "msg", "action", f"set-window-{dimension}", "--id", str(window_id), str(value)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )


def repair(window_id: int) -> None:
    stable_since: float | None = None
    try:
        while True:
            current = next((window for window in windows() if window["id"] == window_id), None)
            if current is None:
                return

            size = current.get("layout", {}).get("window_size") or [0, 0]
            if size[0] >= MIN_WIDTH and size[1] >= MIN_HEIGHT:
                if stable_since is None:
                    stable_since = time.monotonic()
                elif time.monotonic() - stable_since >= VERIFY_SECONDS:
                    print(f"KakaoTalk window {window_id}: {size[0]}x{size[1]} stable for 1s; done", flush=True)
                    return
            else:
                stable_since = None
                request_size(window_id)
            time.sleep(RETRY_SECONDS)
    finally:
        with active_lock:
            active.discard(window_id)


def consider(window: dict) -> None:
    if window.get("app_id") == "explorer.exe" and window.get("title", "") == "":
        subprocess.run(
            ["niri", "msg", "action", "close-window", "--id", str(window["id"])],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        print(f"Closed KakaoTalk's empty Wine shell window {window['id']}", flush=True)
        return

    if window.get("app_id") != "kakaotalk.exe":
        return
    title = window.get("title", "")
    if not title or title == "카카오톡":
        return

    window_id = window["id"]
    size = window.get("layout", {}).get("window_size") or [0, 0]
    if size[0] >= MIN_WIDTH and size[1] >= MIN_HEIGHT:
        return

    with active_lock:
        if window_id in active:
            return
        active.add(window_id)
    print(f"KakaoTalk conversation window {window_id} appeared at {size[0]}x{size[1]}; retrying 900x700", flush=True)
    threading.Thread(target=repair, args=(window_id,), daemon=True).start()


def main() -> None:
    while True:
        try:
            stream = subprocess.Popen(
                ["niri", "msg", "-j", "event-stream"],
                stdout=subprocess.PIPE,
                text=True,
            )
            assert stream.stdout is not None
            for line in stream.stdout:
                event = json.loads(line)
                changed = event.get("WindowsChanged")
                if changed:
                    for window in changed.get("windows", []):
                        consider(window)
            stream.wait()
        except (json.JSONDecodeError, OSError, subprocess.SubprocessError) as error:
            print(f"Niri event stream disconnected: {error}; reconnecting", flush=True)
        time.sleep(1)


if __name__ == "__main__":
    main()
