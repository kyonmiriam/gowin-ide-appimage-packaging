#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$ROOT_DIR/.." && pwd)
IDE_DIR="$REPO_ROOT/vendor/IDE"
PROGRAMMER_DIR="$REPO_ROOT/vendor/Programmer"
APPDIR="$REPO_ROOT/artifacts/build/GowinIDE.AppDir"
APPIMAGE_TOOL_DEFAULT="$REPO_ROOT/artifacts/tools/appimagetool-x86_64.AppImage"
APPIMAGE_TOOL="${APPIMAGETOOL:-$APPIMAGE_TOOL_DEFAULT}"
OUTPUT_NAME="Gowin-IDE-x86_64.AppImage"
ASSEMBLE_ONLY="${ASSEMBLE_ONLY:-0}"

if [[ ! -x "$IDE_DIR/bin/gw_ide" ]]; then
  printf 'Missing IDE executable: %s\n' "$IDE_DIR/bin/gw_ide" >&2
  exit 1
fi

mkdir -p "$REPO_ROOT/artifacts/build" "$REPO_ROOT/artifacts/tools"
rm -rf "$APPDIR"

mkdir -p \
  "$APPDIR/usr/bin" \
  "$APPDIR/usr/lib" \
  "$APPDIR/usr/plugins" \
  "$APPDIR/usr/share/applications" \
  "$APPDIR/usr/share/icons/hicolor/256x256/apps" \
  "$APPDIR/usr/share/icons/hicolor/scalable/apps" \
  "$APPDIR/usr/share/metainfo"

cp -a "$IDE_DIR/bin/." "$APPDIR/usr/bin/"
cp -a "$IDE_DIR/data" "$APPDIR/usr/"
cp -a "$IDE_DIR/doc" "$APPDIR/usr/"
cp -a "$IDE_DIR/ipcore" "$APPDIR/usr/"
cp -a "$IDE_DIR/share" "$APPDIR/usr/"
cp -a "$IDE_DIR/simlib" "$APPDIR/usr/"
cp -a "$IDE_DIR/plugins/." "$APPDIR/usr/plugins/"
ln -sfn ../bin/resources "$APPDIR/usr/data/resources"
mkdir -p "$APPDIR/usr/translations"
ln -sfn ../bin/translations/qtwebengine_locales "$APPDIR/usr/translations/qtwebengine_locales"
cp -a "$PROGRAMMER_DIR" "$APPDIR/"
cp "$ROOT_DIR/packaging/appimage/50-programmer_usb.rules" "$APPDIR/Programmer/Driver/50-programmer_usb.rules"
cp "$APPDIR/Programmer/Driver/50-programmer_usb.rules" "$APPDIR/Programmer/bin/50-programmer_usb.rules"
mv "$APPDIR/Programmer/bin/programmer" "$APPDIR/Programmer/bin/programmer.real"
mv "$APPDIR/Programmer/bin/programmer_cli" "$APPDIR/Programmer/bin/programmer_cli.real"
cp "$ROOT_DIR/packaging/appimage/programmer-wrapper" "$APPDIR/Programmer/bin/programmer"
cp "$ROOT_DIR/packaging/appimage/programmer-wrapper" "$APPDIR/Programmer/bin/programmer_cli"
chmod +x "$APPDIR/Programmer/bin/programmer" "$APPDIR/Programmer/bin/programmer_cli"
cp "$ROOT_DIR/packaging/appimage/programmer-fonts.conf" "$APPDIR/Programmer/bin/fontconfig/fonts.conf"
mkdir -p "$APPDIR/usr/plugins/qt/xcbglintegrations"
cp -a "$ROOT_DIR/packaging/appimage/xcbglintegrations/." "$APPDIR/usr/plugins/qt/xcbglintegrations/"

# Avoid bundling a few compatibility-sensitive libraries that should come
# from the host system to prevent symbol/version mismatches.
EXCLUDE_LIBS=(
  libfreetype.so.6
  libfontconfig.so.1
  libX11.so
  libXext.so.6
  libXrender.so.1
  libxcb.so.1
  libXau.so.6
  libGL.so.1
  libGLX.so.0
  libGLdispatch.so.0
  libstdc++.so.6
  libpthread.so
)

cp -a "$IDE_DIR/lib/." "$APPDIR/usr/lib/"
gcc -shared -fPIC \
  "$ROOT_DIR/packaging/appimage/qputenv-keep-xcbgl.c" \
  -ldl \
  -o "$APPDIR/usr/lib/libgowin-qputenv-keep-xcbgl.so"

for lib in "${EXCLUDE_LIBS[@]}"; do
  rm -f "$APPDIR/usr/lib/$lib"
done

cp "$ROOT_DIR/packaging/appimage/AppRun" "$APPDIR/AppRun"
cp "$ROOT_DIR/packaging/appimage/install-programmer-udev-rules.sh" "$APPDIR/usr/bin/"
chmod +x "$APPDIR/usr/bin/install-programmer-udev-rules.sh"
cp "$ROOT_DIR/packaging/appimage/host-command-wrapper" "$APPDIR/usr/bin/host-command-wrapper"
chmod +x "$APPDIR/usr/bin/host-command-wrapper"
for cmd in xdg-open gio dolphin nautilus thunar kioclient kioclient5 codium vscodium code open-file-location konsole gnome-terminal kgx xterm xfce4-terminal mate-terminal lxterminal terminator; do
  ln -sf host-command-wrapper "$APPDIR/usr/bin/$cmd"
done
cp "$ROOT_DIR/packaging/appimage/gowin-ide.desktop" "$APPDIR/usr/share/applications/"
cp "$ROOT_DIR/packaging/appimage/gowin-ide.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/"
cp "$ROOT_DIR/packaging/appimage/gowin-ide.ico" "$APPDIR/usr/share/icons/hicolor/256x256/apps/"
cp "$ROOT_DIR/packaging/appimage/gowin-ide.svg" "$APPDIR/usr/share/icons/hicolor/scalable/apps/"
cp "$ROOT_DIR/packaging/appimage/io.github.gowinsemi.gowin_ide.appdata.xml" "$APPDIR/usr/share/metainfo/"
cp "$ROOT_DIR/packaging/appimage/qt.conf" "$APPDIR/usr/bin/qt.conf"

ln -sf usr/share/applications/gowin-ide.desktop "$APPDIR/gowin-ide.desktop"
ln -sf usr/share/icons/hicolor/256x256/apps/gowin-ide.png "$APPDIR/gowin-ide.png"
ln -sf usr/share/icons/hicolor/256x256/apps/gowin-ide.ico "$APPDIR/gowin-ide.ico"
ln -sf gowin-ide.png "$APPDIR/.DirIcon"

chmod +x "$APPDIR/AppRun"

if [[ "$ASSEMBLE_ONLY" == "1" ]]; then
  printf 'Assembled AppDir at %s\n' "$APPDIR"
  exit 0
fi

if [[ ! -x "$APPIMAGE_TOOL" ]]; then
  printf 'appimagetool not found: %s\n' "$APPIMAGE_TOOL" >&2
  printf 'Download it and rerun, or set APPIMAGETOOL=/path/to/appimagetool\n' >&2
  exit 2
fi

ARCH=x86_64 "$APPIMAGE_TOOL" "$APPDIR" "$REPO_ROOT/artifacts/$OUTPUT_NAME"

printf 'Built %s\n' "$REPO_ROOT/artifacts/$OUTPUT_NAME"
