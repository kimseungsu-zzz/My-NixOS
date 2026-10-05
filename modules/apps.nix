{ pkgs, lib, ... }:

let
  # 26.05 ships rpi-imager 2.0.9, which crashes at startup (QML "QQmlApplicationEngine failed
  # to load component": missing Material import, nixpkgs#529793). Fixed upstream after 2.0.9;
  # drop the patch when nixpkgs has >= 2.0.10.
  rpiImagerPatched = pkgs.rpi-imager.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (pkgs.fetchpatch {
        name = "add-material-import.patch";
        url = "https://github.com/raspberrypi/rpi-imager/commit/a4a2d3f402c20daf76a15d18acb22f6be6810b35.patch";
        hash = "sha256-n0AwancP8oY/sUUQtmuznfgeYkf+eXrHC1uzx41OclE=";
      })
    ];
  });

  # Imager has to write raw block devices, so it always starts as root: `rpi-imager` (and the
  # menu entry, whose Exec is plain `rpi-imager`) goes through pkexec, passing the Wayland
  # session variables on so the root process can show its window.
  rpiImager = pkgs.symlinkJoin {
    name = "rpi-imager-root";
    paths = [ rpiImagerPatched ];
    postBuild = ''
      rm $out/bin/rpi-imager
      cat > $out/bin/rpi-imager <<'EOF'
      #!${pkgs.runtimeShell}
      if [ "$(id -u)" = 0 ]; then
        exec ${rpiImagerPatched}/bin/rpi-imager "$@"
      fi
      exec /run/wrappers/bin/pkexec env \
        WAYLAND_DISPLAY="$WAYLAND_DISPLAY" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
        DISPLAY="$DISPLAY" XAUTHORITY="$XAUTHORITY" \
        ${rpiImagerPatched}/bin/rpi-imager "$@"
      EOF
      chmod +x $out/bin/rpi-imager
    '';
  };
in
{
  programs.firefox.enable = true;

  # ChatGPT Community (menu entry "ChatGPT Community", command codex-desktop). Unfree wrapper.
  programs.codexDesktopLinux.enable = true;

  # Claude Desktop (official Linux beta, unfree).
  programs.claude-desktop.enable = true;

  # OBS Studio (screen recording / streaming), with the virtual camera module.
  programs.obs-studio.enable = true;

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
    rpiImager   # Raspberry Pi Imager, always as root
    ventoy-full-gtk  # bootable USB creator (run with sudo or via polkit)
    bambu-studio
  ];
}
