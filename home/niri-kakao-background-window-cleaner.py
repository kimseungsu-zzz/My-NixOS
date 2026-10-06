#!/usr/bin/env python3
"""Close KakaoTalk's empty Wine Explorer desktop window under Niri."""

import json
import subprocess
import time


def close_empty_shell(window: dict) -> None:
    if window.get("app_id") != "explorer.exe" or window.get("title", "") != "":
        return

    subprocess.run(
        ["niri", "msg", "action", "close-window", "--id", str(window["id"])],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )


def main() -> None:
    while True:
        try:
            current = subprocess.run(
                ["niri", "msg", "-j", "windows"],
                check=True,
                capture_output=True,
                text=True,
            )
            for window in json.loads(current.stdout):
                close_empty_shell(window)

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
                        close_empty_shell(window)
            stream.wait()
            time.sleep(1)
        except (json.JSONDecodeError, OSError, subprocess.SubprocessError):
            time.sleep(1)


if __name__ == "__main__":
    main()
