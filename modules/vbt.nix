{ pkgs, ... }:

let
  # hardware/vbt.bin is this laptop's VBT, dumped with
  #   sudo cat /sys/kernel/debug/dri/1/i915_vbt > hardware/vbt.bin
  # Its HDMI port is capped at 340 MHz, so i915 rejects 3440x1440@100 (554 MHz). Windows drives
  # the same port at 100 Hz RGB 8-bit. The patched copy lifts the cap to the platform maximum.
  vbtFirmware = pkgs.runCommand "vbt-hdmi-patched" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    mkdir -p $out/lib/firmware/i915
    python3 ${../hardware/vbt-patch.py} ${../hardware/vbt.bin} $out/lib/firmware/i915/vbt-patched.bin
  '';
in
{
  hardware.firmware = [ vbtFirmware ];
  boot.kernelParams = [ "i915.vbt_firmware=i915/vbt-patched.bin" ];
}
