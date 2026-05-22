# Gowin IDE AppImage Packaging

Unofficial AppImage packaging scripts for building a local Gowin IDE AppImage on
Linux.

This repository does not include Gowin IDE, Gowin Programmer, Gowin device
databases, Gowin icons, Gowin logos, generated AppImages, or Gowin Linux
archives. You must obtain the Gowin Linux archive separately and comply with
Gowin's license terms.

## At A Glance

- Builds from a user-provided Gowin Linux archive.
- Keeps Gowin proprietary payload files out of git.
- Produces a local AppImage with entrypoints for IDE, `gw_sh`, Programmer GUI,
  Programmer CLI, and a udev rule installer.
- Includes runtime fixes for Qt/XCB, QtWebEngine, writable state, and
  Programmer USB access on Linux systems.

## Why This Exists

The official Gowin Linux IDE binary is built around a specific Ubuntu runtime
environment. On other Linux distributions, and even on Ubuntu releases that do
not match the expected runtime closely enough, users can run into many small but
time-consuming issues: Qt plugin mismatches, QtWebEngine resource lookup
failures, host library conflicts, writable runtime assumptions, and Programmer
USB cable access problems.

This repository exists to make that setup reproducible. It packages the
user-provided Gowin IDE and Programmer files into a local AppImage with wrapper
scripts, runtime layout fixes, entrypoints, and troubleshooting notes, while
keeping Gowin proprietary payload files outside git.

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

Primary AppImage entrypoints:

- IDE: `./artifacts/Gowin-IDE-x86_64.AppImage`
- Tcl shell: `--gw_sh` or `gw_sh`
- Programmer GUI: `--programmer` or `programmer`
- Programmer CLI: `--programmer-cli` or `programmer_cli`
- USB rule installer: `--install-programmer-udev-rules`

## Verified Environment

This packaging flow has been tested with:

- Gowin Linux archive: `Gowin_V1.9.12.02_SP2_linux.tar.gz`
- Gowin IDE bundled Qt: Qt 5.15.14
- Gowin Programmer bundled Qt: Qt 5.5.1
- AppImage architecture: x86_64
- Linux desktop systems using X11/XCB

Verified behavior includes:

- versioned AppImage output from a user-provided Gowin tarball
- IDE launch
- Gowin Tcl shell launch with `--gw_sh`
- Programmer GUI and Programmer CLI launch
- persistent `share/device` runtime data for bitstream generation
- stabilized writable runtime state under `~/.local/share/gowin-ide-appimage/`

## Programmer Cable Troubleshooting

If Programmer reports `Cable failed to open via the channel`, the usual cause is
USB access rather than AppImage startup. On RHEL/Rocky Linux style systems,
check whether the cable is owned by the kernel `ftdi_sio` driver or whether the
udev rule did not grant user access:

```bash
lsusb
lsusb -t
ls -l /dev/bus/usb/BBB/DDD
udevadm info -q property -n /dev/bus/usb/BBB/DDD
```

Replace `BBB/DDD` with the Bus/Device numbers from `lsusb`. If `lsusb -t` shows
`Driver=ftdi_sio` for the cable interface, Gowin Programmer may fail to claim
the interface until the driver is detached and the cable is reconnected.

Install the packaged udev rule, reconnect the cable, then test the CLI before
debugging the GUI:

```bash
./artifacts/Gowin-IDE-x86_64.AppImage --install-programmer-udev-rules
./artifacts/Gowin-IDE-x86_64.AppImage --programmer-cli --scan-cables
```

As a permission check only, compare with `sudo`:

```bash
sudo ./artifacts/Gowin-IDE-x86_64.AppImage --programmer-cli --scan-cables
```

If `sudo` works but a normal user does not, the problem is udev permissions. If
both fail while `ftdi_sio` is bound, the problem is likely kernel driver binding.

For simple FPGA programming workflows, `openFPGALoader` may be a better option
than Gowin Programmer. It integrates well with Linux distributions and often
handles supported cables without the Gowin Programmer runtime.

## Documentation

- Build and usage details: `workspace/README.md`
- Packaging status: `workspace/docs/STATUS.md`
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
