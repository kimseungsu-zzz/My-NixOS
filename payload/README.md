# Installer payload

Everything the installer ships besides VS Code lives here. Drop files into
these folders and they are packaged as-is; there is no download step and no
dependency resolution, so whatever is here is exactly what gets installed.

| Folder            | Installed to        | What goes in it                              |
|-------------------|---------------------|----------------------------------------------|
| `maven/wpilib`    | `<install>/maven`   | The WPILib maven repository tree             |
| `maven/vendor`    | `<install>/maven`   | Vendor libraries (navX, Studica, VMX-Pi, …)  |
| `toolchains`      | `<install>/toolchains` | Cross compilers, laid out as `~/.gradle/toolchains` |
| `tools`           | `<install>/tools`   | Desktop tools (Glass, OutlineViewer, …)      |
| `vendordeps`      | `<install>/vendordeps` | Vendor library JSON files (navX, VMX-Pi, …) |
| `documentation`   | `<install>/documentation` | Unpacked API docs, in `java/` and `cpp/` |

The vendor library files are what "Install new libraries (offline)" lists, so
a vendor whose artifacts are in `maven/vendor` also needs its JSON here to be
installable without a network. The WPILib command framework files are added
automatically, out of the extension vsix.

Both maven folders are merged into a single repository at `<install>/maven`,
so WPILib and vendor artifacts can be maintained separately but still resolve
as one repo. The toolchains folder is copied to `<gradle user home>/toolchains`
by the post-install script, so each entry sits at the path GradleRIO looks for:
`raspbian10` for the VMX-Pi and `frc/2020/roborio` for the roboRIO.

The documentation folders are what "Open API Documentation" opens; without them
the command downloads the archives from first.wpi.edu.

Extensions are handled separately, in `extensions/`. Commands that need to run
at the end of installation go in `postInstall/`.
