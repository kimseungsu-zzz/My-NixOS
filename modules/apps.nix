{ pkgs, lib, ... }:

{
  programs.firefox.enable = true;

  # Hancom Office (hwp, hword, hcl, hsl). Module: github.com/kimseungsu-zzz/nixos-hnc
  # koreanSupport (default on): ko_KR locale + ibus-hangul + CJK fonts.
  # Runs through XWayland on the Plasma Wayland session (bundled Qt 5.11 has no Wayland plugin).
  programs.hoffice11.enable = true;

  # Studica Hardware Manager. users get added to the dialout group (re-login needed).
  programs.studica-hardware-manager = {
    enable = true;
    users = [ "linux" ];
  };

  # Studica Titan Config & Update App (udev rules for 0483:5740 / df11, dfu-util).
  programs.titan-config.enable = true;

  # WPILib VMX 2020 (WPILibInstaller-Avalonia, scripts/nixos-distrobox.sh) runs in
  # an Ubuntu distrobox container. hardware.graphics exposes Mesa at
  # /run/opengl-driver, which distrobox bind-mounts into the container.
  virtualisation.podman.enable = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Terminal: Terminator instead of Konsole (colours in home.nix, default terminal and the
  # Ctrl+Alt+T shortcut in home/plasma.nix).
  environment.plasma6.excludePackages = [ pkgs.kdePackages.konsole ];

  # Ventoy is flagged insecure in nixpkgs: its prebuilt boot images and tools are binary blobs
  # that cannot be audited (https://github.com/NixOS/nixpkgs/issues/404663). Only Ventoy is
  # allowed through; any other insecure package is still refused.
  nixpkgs.config.allowInsecurePredicate = pkg: lib.hasPrefix "ventoy" (lib.getName pkg);

  # CLI tools and anything the system itself needs. GUI apps live in
  # home/packages.nix.
  environment.systemPackages = with pkgs; [
    wget
    git
    gh
    btop
    distrobox
    nodejs
    python3
    terminator
    # 26.05 ships rpi-imager 2.0.9, which crashes at startup (QML "QQmlApplicationEngine failed
    # to load component": missing Material import, nixpkgs#529793). Fixed upstream after 2.0.9;
    # drop this override when nixpkgs has >= 2.0.10.
    (rpi-imager.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        (fetchpatch {
          name = "add-material-import.patch";
          url = "https://github.com/raspberrypi/rpi-imager/commit/a4a2d3f402c20daf76a15d18acb22f6be6810b35.patch";
          hash = "sha256-n0AwancP8oY/sUUQtmuznfgeYkf+eXrHC1uzx41OclE=";
        })
      ];
    }))
    ventoy-full-gtk  # bootable USB creator (run with sudo or via polkit)
  ];
}
