# My-NixOS

NixOS flake for the `kimseungsu` machine.

```bash
sudo nixos-rebuild switch --flake .#kimseungsu
```

Apps that need an FHS system run in Ubuntu distrobox containers (podman):

- Fusion 360: `bash fusion360/setup.sh`
- WPILib VMX 2020: `scripts/nixos-distrobox.sh` in the WPILibInstaller-Avalonia repo
