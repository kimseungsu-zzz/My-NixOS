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
    # Run through XWayland: the Wayland Qt backend fails to open the window on this setup.
    (symlinkJoin {
      name = "rpi-imager-xcb";
      paths = [ rpi-imager ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = "wrapProgram $out/bin/rpi-imager --set QT_QPA_PLATFORM xcb";
    })
    ventoy-full-gtk  # bootable USB creator (run with sudo or via polkit)
  ];
}
