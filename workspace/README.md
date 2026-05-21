# Gowin IDE AppImage Builder

This repository contains packaging scripts for building a local AppImage from a
user-provided Gowin Linux distribution archive.

The repository must not contain Gowin proprietary payload files. Keep the
following files outside git and provide them locally when building:

- Gowin Linux archive, for example `dist/Gowin_V1.9.12.02_SP2_linux.tar.gz`
- Gowin icon file, if the Linux archive does not contain one discoverable by the build script

## Dependencies

### openSUSE / zypper

```bash
sudo zypper install bash tar gzip xz zstd gcc make sed grep findutils coreutils curl ImageMagick librsvg-tools icoutils desktop-file-utils appstream-glib
```

### Debian / Ubuntu / apt

```bash
sudo apt update
sudo apt install bash tar gzip xz-utils zstd gcc make sed grep findutils coreutils curl imagemagick librsvg2-bin icoutils desktop-file-utils appstream
```

### Fedora / dnf

```bash
sudo dnf install bash tar gzip xz zstd gcc make sed grep findutils coreutils curl ImageMagick librsvg2-tools icoutils desktop-file-utils libappstream-glib
```

You also need `appimagetool`. Put it at:

```text
artifacts/tools/appimagetool-x86_64.AppImage
```

or pass it explicitly:

```bash
APPIMAGETOOL=/path/to/appimagetool-x86_64.AppImage ./workspace/build-from-tarball.sh dist/Gowin_V1.9.12.02_SP2_linux.tar.gz
```

## Build

Place the Gowin Linux archive under `dist/`, then run:

```bash
./workspace/build-from-tarball.sh dist/Gowin_V1.9.12.02_SP2_linux.tar.gz
```

The script extracts the archive to ignored local directories:

```text
vendor/IDE/
vendor/Programmer/
vendor/.gowin-version
```

Then it builds a versioned AppImage such as:

```text
artifacts/Gowin-IDE-1.9.12.02_SP2-x86_64.AppImage
```

## Icon Handling

The build does not track Gowin icons in git. It searches the extracted Gowin
archive for a suitable icon. Some Linux archives do not include a standalone
icon file; in that case, provide an icon from your local Gowin distribution
explicitly:

```bash
ICON_FILE=/path/to/gowin/icon.png ./workspace/build-from-tarball.sh dist/Gowin_V1.9.12.02_SP2_linux.tar.gz
```

Supported icon formats are `.png`, `.svg`, and `.ico`. If the extracted Gowin
archive contains a Windows PE resource such as `gw_ide.exe`, the script also
tries `wrestool` and `icotool` from `icoutils` to extract an ICO automatically.
Converted/generated icon files are written under `artifacts/generated-icons/`,
which is ignored by git.

As an explicit opt-in fallback, the build can fetch the favicon advertised by
the Gowin website. This downloads a Gowin-owned asset into ignored local build
artifacts and does not add it to git:

```bash
FETCH_GOWIN_ICON=1 ./workspace/build-from-tarball.sh dist/Gowin_V1.9.12.02_SP2_linux.tar.gz
```

The default URL is `https://www.gowinsemi.com.cn/`. Override it if needed:

```bash
FETCH_GOWIN_ICON=1 GOWIN_ICON_URL=https://www.gowinsemi.com.cn/ ./workspace/build-from-tarball.sh dist/Gowin_V1.9.12.02_SP2_linux.tar.gz
```

## Entrypoints

The generated AppImage supports:

```text
--help                            Show AppImage help
--gw_sh, gw_sh                    Start Gowin Tcl shell
--programmer, programmer          Start Gowin Programmer GUI
--programmer-cli, programmer_cli  Start Gowin Programmer CLI
--install-programmer-udev-rules   Install Programmer USB udev rules
```

## Verified Environment

This packaging flow has been tested with:

- Gowin Linux archive: `Gowin_V1.9.12.02_SP2_linux.tar.gz`
- Generated AppImage name: `Gowin-IDE-1.9.12.02_SP2-x86_64.AppImage`
- Gowin IDE bundled Qt: Qt 5.15.14
- Gowin Programmer bundled Qt: Qt 5.5.1
- AppImage architecture: x86_64
- Desktop integration target: Linux desktop systems using X11/XCB

Verified behavior:

- Build from a user-provided Gowin tarball with `build-from-tarball.sh`.
- Versioned AppImage output and compatibility symlink creation.
- IDE launch through the AppImage runtime.
- Gowin Tcl shell entrypoint with `--gw_sh` and `gw_sh`.
- Programmer GUI entrypoint with `--programmer` and `programmer`.
- Programmer CLI entrypoint with `--programmer-cli` and `programmer_cli`.
- Bitstream generation with persistent `share/device` runtime data.
- Optional icon handling from a user-provided icon file.
- Optional opt-in Gowin website favicon fetch with `FETCH_GOWIN_ICON=1`.

The build should also work with nearby Gowin Linux versions that keep the same
archive layout, but those versions have not been verified in this repository.

## Notes

- The AppImage stores writable runtime state under `~/.local/share/gowin-ide-appimage/`.
- `share/device` is copied to persistent runtime state so bitstream generation does not depend on an already-unmounted AppImage FUSE path.
- `Programmer` is copied to writable runtime state because it writes logs/cache beside its binaries.
- The build scripts only package files extracted from the user-provided Gowin archive plus wrapper files from this repository.
- Packaging status and implementation notes are in `workspace/docs/STATUS.md`.
- The two tracked Qt `xcbglintegrations` plugins are documented in `workspace/packaging/appimage/xcbglintegrations/README.md`.

## License

This repository's original scripts, wrappers, metadata, and documentation are
licensed under the MIT License. See `LICENSE`.

This repository does not include Gowin IDE, Gowin Programmer, Gowin device
databases, Gowin icons, Gowin logos, or other Gowin proprietary payload files.
Users must obtain Gowin software separately and comply with Gowin's license
terms.

The tracked Qt `xcbglintegrations` plugins are third-party Qt runtime
components and are not covered by this repository's MIT License. See `NOTICE`
and `workspace/packaging/appimage/xcbglintegrations/README.md`.
