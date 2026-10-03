{ pkgs, ... }:

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

  # WPILib VMX 2020 (WPILibInstaller-Avalonia, scripts/nixos-distrobox.sh) runs in
  # an Ubuntu distrobox container. hardware.graphics exposes Mesa at
  # /run/opengl-driver, which distrobox bind-mounts into the container.
  virtualisation.podman.enable = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

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
  ];
}
