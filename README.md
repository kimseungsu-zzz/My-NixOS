# My-NixOS

NixOS flake for the `kimseungsu` machine.

```bash
sudo nixos-rebuild switch --flake .#kimseungsu
```

WPILib VMX 2020 runs in an Ubuntu distrobox container (podman):
`scripts/nixos-distrobox.sh` in the WPILibInstaller-Avalonia repo.

Autodesk Fusion 360 (unofficial, Wine) runs in a separate distrobox with its own
HOME, so it does not see your real home directory. Firefox for the sign-in is
installed inside it.

```bash
./fusion360/setup.sh          # install
./fusion360/setup.sh launch   # or use the KDE menu entry
./fusion360/setup.sh purge    # remove container and its home
```

The isolation keeps Fusion away from your files; it is not a security sandbox
(distrobox still exposes the host at `/run/host` and shares display/GPU).
