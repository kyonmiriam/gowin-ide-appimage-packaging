# Gowin IDE AppImage Packaging Status

This document is safe to publish. It intentionally avoids host-specific paths,
license server values, USB serial numbers, and other local test details.

## Current State

- The AppImage build flow is scriptable from a user-provided Gowin Linux archive.
- The repository does not track Gowin proprietary payload files, AppImage outputs,
  user archives, or Gowin icon assets.
- The generated AppImage supports the IDE, Gowin Tcl shell, Programmer GUI,
  Programmer CLI, and a helper for installing Programmer USB udev rules.
- Runtime state is kept under `~/.local/share/gowin-ide-appimage/`.
- `share/device` is copied to persistent runtime state so bitstream generation
  does not depend on an AppImage FUSE mount that may already be gone.
- Programmer is copied to a writable runtime directory because it writes logs and
  cache files beside its binaries.

## Build Flow

Use:

```bash
./workspace/build-from-tarball.sh dist/Gowin_V1.9.12.02_SP2_linux.tar.gz
```

The flow performs these steps:

- Extracts the user-provided archive into ignored local directories:
  `vendor/IDE/` and `vendor/Programmer/`.
- Parses the Gowin version from the archive name and writes it to ignored
  `vendor/.gowin-version`.
- Builds a versioned AppImage such as
  `artifacts/Gowin-IDE-1.9.12.02_SP2-x86_64.AppImage`.
- Creates the compatibility symlink `artifacts/Gowin-IDE-x86_64.AppImage`.

## AppImage Entrypoints

```text
--help                            Show AppImage help
--gw_sh, gw_sh                    Start Gowin Tcl shell
--programmer, programmer          Start Gowin Programmer GUI
--programmer-cli, programmer_cli  Start Gowin Programmer CLI
--install-programmer-udev-rules   Install Programmer USB udev rules
```

## Runtime Fixes

- A preload shim preserves Qt/XCB/OpenGL and QtWebEngine-related environment
  variables that the Gowin launcher may overwrite.
- QtWebEngine resource paths and ICU data paths are set explicitly.
- `gw_sh` runs through the same AppImage runtime instead of being executed
  directly from the vendor tree.
- Programmer runs through its own wrapper so IDE Qt/runtime variables do not
  contaminate Programmer's separate Qt 5.5 runtime.
- Host command wrappers clean the Gowin/AppImage environment before launching
  host file managers, editors, and terminal emulators.

## USB Rules

The packaged udev rule covers the commonly used Programmer USB IDs:

```text
33aa:0120
0403:6014
0403:6010
```

The rule avoids recursive `udevadm trigger` or global `modprobe -r ftdi_sio`
behavior. For FTDI-based cables, it detaches `ftdi_sio` at bind time for the
interfaces used by the Programmer.

## Icons

The repository does not track Gowin icon files. Build-time icon sources are:

- `ICON_FILE=/path/to/icon` supplied by the user.
- An icon discovered inside the extracted user-provided Gowin archive.
- A Windows PE icon resource from the extracted archive, if available, using
  `wrestool` and `icotool`.
- Optional opt-in website favicon fetch with `FETCH_GOWIN_ICON=1`.

Generated icons are written only under ignored `artifacts/generated-icons/`.

## Third-Party Binary Plugins

The repository intentionally keeps two Qt `xcbglintegrations` binary plugins
under `workspace/packaging/appimage/xcbglintegrations/`. They are not Gowin
files. They are kept because the Gowin Linux archive includes Qt 5.15.14 but
does not include the XCB GL integration plugins required on modern desktops.

See `workspace/packaging/appimage/xcbglintegrations/README.md` for source and
license notes.

## Repository Layout

```text
GOWIN/
  workspace/
    README.md
    build-from-tarball.sh
    prepare-vendor-from-tarball.sh
    build-ide-appimage.sh
    run-ide-appdir.sh
    docs/
      STATUS.md
    packaging/appimage/
      AppRun
      host-command-wrapper
      programmer-wrapper
      qputenv-keep-xcbgl.c
      xcbglintegrations/
  dist/                         # ignored user-provided archives
  vendor/                       # ignored extracted Gowin payload
  artifacts/                    # ignored generated AppDir/AppImage/icons/tools
```
