# Gowin IDE AppImage Packaging

Unofficial AppImage packaging scripts for Gowin IDE, Gowin Tcl shell, and
Gowin Programmer on Linux.

This repository does not include Gowin IDE, Gowin Programmer, Gowin device
databases, Gowin icons, Gowin logos, generated AppImages, or Gowin Linux
archives. You must obtain the Gowin Linux archive separately and comply with
Gowin's license terms.

## What It Builds

From a user-provided Gowin Linux archive, the scripts build a local AppImage
with entrypoints for:

- Gowin IDE
- Gowin Tcl shell: `--gw_sh` or `gw_sh`
- Gowin Programmer GUI: `--programmer` or `programmer`
- Gowin Programmer CLI: `--programmer-cli` or `programmer_cli`
- Programmer USB udev rule installer: `--install-programmer-udev-rules`

## Quick Start

Place the Gowin Linux archive under `dist/`, then run:

```bash
./workspace/build-from-tarball.sh dist/Gowin_V1.9.12.02_SP2_linux.tar.gz
```

The generated AppImage is written under `artifacts/`, for example:

```text
artifacts/Gowin-IDE-1.9.12.02_SP2-x86_64.AppImage
```

The `dist/`, `vendor/`, and `artifacts/` directories are ignored by git.

## Verified Environment

This packaging flow has been tested with:

- Gowin Linux archive: `Gowin_V1.9.12.02_SP2_linux.tar.gz`
- Gowin IDE bundled Qt: Qt 5.15.14
- Gowin Programmer bundled Qt: Qt 5.5.1
- AppImage architecture: x86_64
- Linux desktop systems using X11/XCB

Verified behavior includes IDE launch, Gowin Tcl shell, Programmer GUI,
Programmer CLI, versioned AppImage output, and bitstream generation with
persistent `share/device` runtime data.

## Documentation

- Full build instructions: `workspace/README.md`
- Packaging status and implementation notes: `workspace/docs/STATUS.md`
- Qt plugin source/license notes: `workspace/packaging/appimage/xcbglintegrations/README.md`

## Repository Contents

```text
workspace/                    Packaging scripts and AppImage runtime files
LICENSE                       MIT license for original repository content
NOTICE                        Third-party and proprietary payload notices
```

Ignored local build inputs/outputs:

```text
dist/                         User-provided Gowin archives
vendor/                       Extracted Gowin payload
artifacts/                    Generated AppDir/AppImage/icons/tools
```

## License

This repository's original scripts, wrappers, metadata, and documentation are
licensed under the MIT License. See `LICENSE`.

The tracked Qt `xcbglintegrations` plugins are third-party Qt runtime
components and are not covered by this repository's MIT License. See `NOTICE`
and `workspace/packaging/appimage/xcbglintegrations/README.md`.

Gowin software and assets are not included in this repository and remain subject
to Gowin's license terms.
