# My-NixOS

NixOS flake for the `linux` machine.

```bash
sudo nixos-rebuild switch --flake .#linux
```

## Layout

| Path | What |
| --- | --- |
| `flake.nix` | inputs (nixpkgs 26.05, home-manager, plasma-manager, hnc) and the host |
| `configuration.nix` | imports the modules below |
| `modules/system.nix` | boot, network, locale, user, ssh, automatic Nix cleanup |
| `modules/desktop.nix` | Plasma, keyboard, audio, printing |
| `modules/apps.nix` | Hancom Office, podman/distrobox, CLI tools |
| `home.nix`, `home/` | home-manager: Plasma settings (`plasma.nix`), GUI apps (`packages.nix`) |
| `hardware-configuration.nix` | generated for this machine |

## Notes

- `hnc` (Hancom Office) is a private repo fetched over HTTPS with the git
  credentials from `gh auth login`. Update with `nix flake update hnc`, and
  rebuild with `--sudo` so the fetch runs as your user, not root.
- Fusion 360 comes from `nix-packages.nixosModules.fusion360`. After a rebuild,
  close Fusion and run `fusion360-install` to install into the GE-Proton prefix,
  then launch it with `fusion360`. The former Wine prefix is kept untouched.
  Proton supplies DXVK; `fusion360-use-dxvk` is retained as a compatibility
  command and does not install a second DXVK copy.
- Old builds are cleaned up automatically: a weekly `nix.gc` deletes
  generations older than 7 days and `/boot` keeps the last 5.
- `screenWidth` in `home/plasma.nix` sets the top panel width.

WPILib VMX 2020 runs in an Ubuntu distrobox container (podman):
`scripts/nixos-distrobox.sh` in the WPILibInstaller-Avalonia repo.
