# My-NixOS

NixOS flake for the `kimseungsu` machine.

```bash
sudo nixos-rebuild switch --flake .#kimseungsu
```

WPILib VMX 2020 runs in an Ubuntu distrobox container (podman):
`scripts/nixos-distrobox.sh` in the WPILibInstaller-Avalonia repo.
