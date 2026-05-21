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

## Notes

- The AppImage stores writable runtime state under `~/.local/share/gowin-ide-appimage/`.
- `share/device` is copied to persistent runtime state so bitstream generation does not depend on an already-unmounted AppImage FUSE path.
- `Programmer` is copied to writable runtime state because it writes logs/cache beside its binaries.
- The build scripts only package files extracted from the user-provided Gowin archive plus wrapper files from this repository.
