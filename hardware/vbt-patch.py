#!/usr/bin/env python3
"""Raise the HDMI max data rate in the board's Intel VBT.

The firmware vendor limits the HDMI port to 340 MHz (hdmi_max_data_rate = 4), which makes i915
reject 3440x1440@100 (554 MHz) although the sink (HDMI Forum VSDB: 600 MHz, SCDC) and the
Windows driver handle it. Setting the field to 0 means "platform maximum" (594 MHz).

usage: vbt-patch.py in.bin out.bin
"""
import struct
import sys

src, dst = sys.argv[1], sys.argv[2]
b = bytearray(open(src, "rb").read())

assert b[:4] == b"$VBT", "not a VBT"
vbt_size = struct.unpack_from("<H", b, 24)[0]
bdb = struct.unpack_from("<I", b, 28)[0]
bdb_header_size = struct.unpack_from("<H", b, bdb + 18)[0]

patched = 0
patched_delta = 0
off = bdb + bdb_header_size
while off + 3 <= vbt_size:
    block_id = b[off]
    size = struct.unpack_from("<H", b, off + 1)[0]
    if block_id == 2:  # general definitions
        data = off + 3
        child_size = b[data + 4]
        count = (size - 5) // child_size
        for i in range(count):
            child = data + 5 + i * child_size
            byte = b[child + 7]  # hdmi_level_shifter_value:5, hdmi_max_data_rate:3
            if (byte >> 5) == 4:  # 340 MHz
                b[child + 7] = byte & 0x1F
                patched_delta += (byte & 0x1F) - byte
                patched += 1
        break
    off += 3 + size

assert patched == 1, f"expected to patch exactly one HDMI port, patched {patched}"

# Keep the VBT checksum consistent: it moves by the same amount the patched byte changed.
b[26] = (b[26] - (patched_delta)) & 0xFF

open(dst, "wb").write(b)
print(f"patched {patched} HDMI port, checksum 0x{b[26]:02x}")
