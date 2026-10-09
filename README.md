# My-NixOS

NixOS flake for the `linux` machine: niri (scrollable-tiling Wayland compositor) with the
Noctalia shell.

```bash
sudo nixos-rebuild switch --flake .#linux
```

## Layout

| Path | What |
| --- | --- |
| `flake.nix` | inputs (nixpkgs 26.05, home-manager, noctalia, hnc2020, nix-packages, ...) and the host |
| `configuration.nix` | imports the modules below |
| `modules/system.nix` | boot, network, locale, user, ssh, automatic Nix cleanup |
| `modules/desktop.nix` | niri session, keyboard, Korean input (kime), audio, Bluetooth, printing |
| `modules/apps.nix` | Hancom Office, Thunar, podman/distrobox, CLI tools |
| `modules/theme.nix` | Catppuccin Mocha: login screen, cursor, fonts |
| `home.nix`, `home/` | home-manager: niri config (`niri.nix`), GTK theme and foot (`home.nix`), GUI apps (`packages.nix`), tray bridge (`xembedsniproxy/`), clipboard helper (`copy-image/`) |
| `hardware-configuration.nix` | generated for this machine |

## Notes

- `hnc2020` (Hancom Office) is a private repo fetched over HTTPS with the git
  credentials from `gh auth login`. Update with `nix flake update hnc2020`, and
  rebuild with `--sudo` so the fetch runs as your user, not root.
- Old builds are cleaned up automatically: a weekly `nix.gc` deletes
  generations older than 7 days and `/boot` keeps the last 5.
- Screenshots (`Print`, `Mod+Shift+S`) go to `~/Pictures/Screenshots` and onto the clipboard as
  PNG and BMP plus the file itself (`home/copy-image`), so they paste into Wine programs and
  file managers too.
- X11 tray icons (KakaoTalk under Wine) reach Noctalia through KDE's `xembedsniproxy`, built on
  its own and run as a user service (`home/xembedsniproxy`).

- Fusion 360 (`fusion360`) renders on the integrated GPU: ghost images stayed in the viewport on
  the Arc A350M. `FUSION_GPU=arc fusion360` switches back, and
  `FUSION_DXVK_HUD=fps,devinfo fusion360` shows a frame-rate overlay. Starting it while another
  instance runs stops that one and exits; run it again.

WPILib VMX 2020 runs in an Ubuntu distrobox container (podman):
`scripts/nixos-distrobox.sh` in the WPILibInstaller-Avalonia repo.
