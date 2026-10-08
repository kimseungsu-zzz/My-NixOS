"""Capture a user-selected window through the XDG ScreenCast portal/PipeWire."""

from __future__ import annotations

import asyncio
import os
import secrets
import subprocess
from pathlib import Path

from dbus_next import BusType, Message, MessageType, Variant
from dbus_next.aio import MessageBus
from dbus_next.introspection import Node


PORTAL = "org.freedesktop.portal.Desktop"
PORTAL_PATH = "/org/freedesktop/portal/desktop"
SCREENCAST = "org.freedesktop.portal.ScreenCast"
REQUEST = "org.freedesktop.portal.Request"
SESSION = "org.freedesktop.portal.Session"
PORTAL_NODE = Node.parse(
    """<node><interface name='org.freedesktop.portal.ScreenCast'>
    <method name='CreateSession'><arg type='a{sv}' direction='in'/><arg type='o' direction='out'/></method>
    <method name='SelectSources'><arg type='o' direction='in'/><arg type='a{sv}' direction='in'/><arg type='o' direction='out'/></method>
    <method name='Start'><arg type='o' direction='in'/><arg type='s' direction='in'/><arg type='a{sv}' direction='in'/><arg type='o' direction='out'/></method>
    <method name='OpenPipeWireRemote'><arg type='o' direction='in'/><arg type='a{sv}' direction='in'/><arg type='h' direction='out'/></method>
    </interface></node>"""
)
SESSION_NODE = Node.parse(
    """<node><interface name='org.freedesktop.portal.Session'>
    <method name='Close'/></interface></node>"""
)


def _variant(value: object, signature: str) -> Variant:
    return Variant(signature, value)


async def _portal_request(bus: MessageBus, method, args: tuple, options: dict) -> dict:
    token = f"vmware_{secrets.token_hex(8)}"
    options = dict(options)
    options["handle_token"] = _variant(token, "s")
    sender = (bus.unique_name or "").lstrip(":").replace(":", "_").replace(".", "_")
    request_path = f"{PORTAL_PATH}/request/{sender}/{token}"
    loop = asyncio.get_running_loop()
    response_future = loop.create_future()

    match_rule = (
        f"type='signal',interface='{REQUEST}',member='Response',path='{request_path}'"
    )
    await bus.call(
        Message(
            destination="org.freedesktop.DBus",
            path="/org/freedesktop/DBus",
            interface="org.freedesktop.DBus",
            member="AddMatch",
            signature="s",
            body=[match_rule],
        )
    )

    def on_message(message: Message) -> bool:
        if message.message_type == MessageType.SIGNAL and message.path == request_path and message.member == "Response":
            if not response_future.done():
                response_future.set_result((message.body[0], message.body[1]))
            return True
        return False

    bus.add_message_handler(on_message)
    try:
        returned_path = await method(*args, options)
        if returned_path != request_path:
            raise RuntimeError(f"Portal request path mismatch: {returned_path}")
        response, results = await asyncio.wait_for(response_future, timeout=180)
        if response != 0:
            raise RuntimeError("ScreenCast portal request was cancelled or denied")
        return results
    finally:
        bus.remove_message_handler(on_message)
        try:
            await bus.call(
                Message(
                    destination="org.freedesktop.DBus",
                    path="/org/freedesktop/DBus",
                    interface="org.freedesktop.DBus",
                    member="RemoveMatch",
                    signature="s",
                    body=[match_rule],
                )
            )
        except Exception:
            pass


def _cache_path() -> Path:
    cache_root = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
    return cache_root / "codex-vmware-window" / "screencast-restore-token"


async def _capture_pipewire_window() -> bytes:
    if not os.environ.get("DBUS_SESSION_BUS_ADDRESS"):
        runtime_dir = os.environ.get("XDG_RUNTIME_DIR")
        if not runtime_dir:
            raise RuntimeError("XDG_RUNTIME_DIR is missing; cannot reach the user's session bus")
        os.environ["DBUS_SESSION_BUS_ADDRESS"] = f"unix:path={runtime_dir}/bus"
    bus = await MessageBus(bus_type=BusType.SESSION).connect()
    session_path = None
    pipewire_fd = None
    try:
        portal = bus.get_proxy_object(PORTAL, PORTAL_PATH, PORTAL_NODE)
        screencast = portal.get_interface(SCREENCAST)

        create_results = await _portal_request(
            bus,
            screencast.call_create_session,
            (),
            {"session_handle_token": _variant(f"vmware_{secrets.token_hex(8)}", "s")},
        )
        session_path = create_results["session_handle"].value

        restore_path = _cache_path()
        try:
            restore_token = restore_path.read_text(encoding="utf-8").strip()
        except OSError:
            restore_token = ""

        select_options = {
            "types": _variant(2, "u"),  # WINDOW only
            "multiple": _variant(False, "b"),
            "cursor_mode": _variant(2, "u"),  # Include the pointer in the captured image.
            "persist_mode": _variant(1, "u"),  # Remember only while the MCP app is running.
        }
        if restore_token:
            select_options["restore_token"] = _variant(restore_token, "s")
        await _portal_request(
            bus, screencast.call_select_sources, (session_path,), select_options
        )
        start_results = await _portal_request(
            bus, screencast.call_start, (session_path, ""), {}
        )

        next_token = start_results.get("restore_token")
        if next_token is not None and next_token.value:
            restore_path.parent.mkdir(parents=True, exist_ok=True)
            restore_path.write_text(next_token.value, encoding="utf-8")
            restore_path.chmod(0o600)

        streams = start_results.get("streams", _variant([], "a(ua{sv})")).value
        if len(streams) != 1:
            raise RuntimeError("ScreenCast portal did not return exactly one window stream")
        node_id, properties = streams[0]
        source_type = properties.get("source_type")
        if source_type is not None and source_type.value != 2:
            raise RuntimeError("Portal returned a non-window screen stream")

        pipewire_fd = await screencast.call_open_pipe_wire_remote(session_path, {})
        if hasattr(pipewire_fd, "take"):
            pipewire_fd = pipewire_fd.take()
        pipewire_fd = int(pipewire_fd)

        gst_command = [
            "gst-launch-1.0",
            "-q",
            "pipewiresrc",
            f"fd={pipewire_fd}",
            f"path={node_id}",
            "do-timestamp=true",
            "num-buffers=1",
            "!",
            "videoconvert",
            "!",
            "pngenc",
            "!",
            "filesink",
            "location=/dev/stdout",
        ]
        completed = await asyncio.to_thread(
            subprocess.run,
            gst_command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            pass_fds=(pipewire_fd,),
            timeout=25,
            check=False,
        )
        if completed.returncode != 0:
            detail = completed.stderr.decode("utf-8", "replace").strip()
            raise RuntimeError(f"PipeWire frame capture failed: {detail}")
        if not completed.stdout.startswith(b"\x89PNG\r\n\x1a\n"):
            raise RuntimeError("PipeWire returned data that is not a PNG image")
        return completed.stdout
    finally:
        if pipewire_fd is not None:
            try:
                os.close(pipewire_fd)
            except OSError:
                pass
        if session_path:
            try:
                session_object = bus.get_proxy_object(PORTAL, session_path, SESSION_NODE)
                await session_object.get_interface(SESSION).call_close()
            except Exception:
                pass
        bus.disconnect()


async def capture_pipewire_window() -> bytes:
    """Capture a window selected by the ScreenCast portal using PipeWire."""
    try:
        return await _capture_pipewire_window()
    except (OSError, asyncio.TimeoutError) as exc:
        raise RuntimeError(f"Could not capture VMware through PipeWire: {exc}") from exc
