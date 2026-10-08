---
name: vmware-window
description: Inspect and operate the visible VMware Workstation window on this Niri desktop using the VMware window MCP tools.
---

# VMware Workstation window control

Use only the `vmware_*` MCP tools to inspect or operate VMware. They validate that the target is a visible VMware window and constrain pointer coordinates to that window. Do not use shell commands, global input tools, or other window targets for GUI control.

Workflow:

1. Call `vmware_list_windows` and choose the visible VMware window matching the user's request.
2. Call `vmware_capture_window` before acting; use the returned image to identify the requested control. The first PipeWire capture may show the ScreenCast chooser; select `Other - VMware Workstation`. The portal can remember this choice while the Codex MCP process is running.
3. Focus and perform one mouse or keyboard action at a time, then capture again to confirm the result.
4. Use `vmware_type_text` only for ordinary non-secret text. Never enter passwords, recovery codes, or license keys through the tool.
5. Pause for explicit confirmation before an action that deletes a VM or disk, changes a host-wide network/device setting, or submits a purchase or license transaction.
6. If no VMware window is listed or the server reports that it cannot operate the window, report the limitation instead of falling back to global desktop input.
