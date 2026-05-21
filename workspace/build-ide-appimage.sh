#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$ROOT_DIR/.." && pwd)
IDE_DIR="$REPO_ROOT/vendor/IDE"
PROGRAMMER_DIR="$REPO_ROOT/vendor/Programmer"
APPDIR="$REPO_ROOT/artifacts/build/GowinIDE.AppDir"
APPIMAGE_TOOL_DEFAULT="$REPO_ROOT/artifacts/tools/appimagetool-x86_64.AppImage"
APPIMAGE_TOOL="${APPIMAGETOOL:-$APPIMAGE_TOOL_DEFAULT}"
VERSION_FILE="$REPO_ROOT/vendor/.gowin-version"
VERSION="${GOWIN_VERSION:-}"
if [[ -z "$VERSION" && -f "$VERSION_FILE" ]]; then
  VERSION=$(<"$VERSION_FILE")
fi
VERSION="${VERSION:-unknown}"
OUTPUT_NAME="Gowin-IDE-${VERSION}-x86_64.AppImage"
ASSEMBLE_ONLY="${ASSEMBLE_ONLY:-0}"

if [[ ! -x "$IDE_DIR/bin/gw_ide" ]]; then
  printf 'Missing IDE executable: %s\n' "$IDE_DIR/bin/gw_ide" >&2
  exit 1
fi

find_icon_file() {
  local generated_dir="$REPO_ROOT/artifacts/generated-icons"
  local website_url="${GOWIN_ICON_URL:-https://www.gowinsemi.com.cn/}"
  local html_file="$generated_dir/gowin-site.html"
  local href
  local favicon_url
  local favicon_file
  local direct_icon
  local pe_file
  local extracted_ico

  if [[ -n "${ICON_FILE:-}" ]]; then
    if [[ -f "$ICON_FILE" ]]; then
      printf '%s\n' "$ICON_FILE"
      return 0
    fi
    printf 'ICON_FILE does not exist: %s\n' "$ICON_FILE" >&2
    return 1
  fi

  direct_icon=$(find "$IDE_DIR" "$PROGRAMMER_DIR" -type f \
    \( -iname '*gowin*.png' -o -iname '*gowin*.ico' -o -iname '*gowin*.svg' -o -iname '*gw_ide*.png' -o -iname '*gw_ide*.ico' -o -iname '*gw_ide*.svg' \) \
    -print -quit)
  if [[ -n "$direct_icon" ]]; then
    printf '%s\n' "$direct_icon"
    return 0
  fi

  pe_file=$(find "$IDE_DIR" "$PROGRAMMER_DIR" -type f \
    \( -iname 'gw_ide.exe' -o -iname '*gowin*.exe' -o -iname '*gw_ide*.dll' -o -iname '*gowin*.dll' \) \
    -print -quit)
  if [[ -n "$pe_file" ]]; then
    if ! command -v wrestool >/dev/null 2>&1 || ! command -v icotool >/dev/null 2>&1; then
      printf 'Found possible PE icon source but need icoutils (wrestool and icotool): %s\n' "$pe_file" >&2
      return 1
    fi
    mkdir -p "$generated_dir"
    extracted_ico="$generated_dir/gowin-ide-extracted.ico"
    if wrestool -x -t 14 "$pe_file" > "$extracted_ico" 2>/dev/null && [[ -s "$extracted_ico" ]]; then
      printf '%s\n' "$extracted_ico"
      return 0
    fi
  fi

  if [[ "${FETCH_GOWIN_ICON:-0}" == "1" ]]; then
    if ! command -v curl >/dev/null 2>&1; then
      printf 'FETCH_GOWIN_ICON=1 requires curl\n' >&2
      return 1
    fi
    mkdir -p "$generated_dir"
    if ! curl -fsSL "$website_url" -o "$html_file"; then
      printf 'Failed to fetch Gowin website for icon: %s\n' "$website_url" >&2
      return 1
    fi
    href=$(grep -Eio '<link[^>]+rel="[^"]*(icon|shortcut icon)[^"]*"[^>]*>' "$html_file" | grep -Eio 'href="[^"]+' | head -n1 | cut -d= -f2- | tr -d '"' || true)
    if [[ -z "$href" ]]; then
      href="/favicon.ico"
    fi
    case "$href" in
      http://*|https://*) favicon_url="$href" ;;
      //*) favicon_url="https:$href" ;;
      /*) favicon_url="${website_url%/}$href" ;;
      *) favicon_url="${website_url%/}/$href" ;;
    esac
    case "${favicon_url,,}" in
      *.png) favicon_file="$generated_dir/gowin-site-icon.png" ;;
      *.svg) favicon_file="$generated_dir/gowin-site-icon.svg" ;;
      *.ico) favicon_file="$generated_dir/gowin-site-icon.ico" ;;
      *) favicon_file="$generated_dir/gowin-site-icon.ico" ;;
    esac
    if curl -fsSL "$favicon_url" -o "$favicon_file" && [[ -s "$favicon_file" ]]; then
      printf '%s\n' "$favicon_file"
      return 0
    fi
    printf 'Failed to fetch Gowin website icon: %s\n' "$favicon_url" >&2
    return 1
  fi
}

prepare_icon_files() {
  local icon_src="$1"
  local generated_dir="$REPO_ROOT/artifacts/generated-icons"
  local png_out="$generated_dir/gowin-ide.png"
  local svg_out="$generated_dir/gowin-ide.svg"

  mkdir -p "$generated_dir"
  rm -f "$png_out" "$svg_out"

  case "${icon_src,,}" in
    *.png)
      cp "$icon_src" "$png_out"
      ;;
    *.svg)
      cp "$icon_src" "$svg_out"
      if command -v rsvg-convert >/dev/null 2>&1; then
        rsvg-convert -w 256 -h 256 "$icon_src" -o "$png_out"
      elif command -v magick >/dev/null 2>&1; then
        magick "$icon_src" -resize 256x256 "$png_out"
      elif command -v convert >/dev/null 2>&1; then
        convert "$icon_src" -resize 256x256 "$png_out"
      else
        printf 'Need rsvg-convert or ImageMagick to convert SVG icon: %s\n' "$icon_src" >&2
        return 1
      fi
      ;;
    *.ico)
      if command -v icotool >/dev/null 2>&1; then
        icotool -x -w 256 -h 256 -o "$generated_dir" "$icon_src" >/dev/null 2>&1 || true
        local extracted_png
        extracted_png=$(find "$generated_dir" -maxdepth 1 -type f -name '*.png' -print -quit)
        if [[ -n "$extracted_png" ]]; then
          mv "$extracted_png" "$png_out"
        fi
      fi
      if [[ ! -f "$png_out" ]] && command -v magick >/dev/null 2>&1; then
        magick "$icon_src[0]" -resize 256x256 "$png_out"
      elif [[ ! -f "$png_out" ]] && command -v convert >/dev/null 2>&1; then
        convert "$icon_src[0]" -resize 256x256 "$png_out"
      elif [[ ! -f "$png_out" ]]; then
        printf 'Need ImageMagick to convert ICO icon: %s\n' "$icon_src" >&2
        return 1
      fi
      cp "$icon_src" "$generated_dir/gowin-ide.ico"
      ;;
    *)
      printf 'Unsupported icon format: %s\n' "$icon_src" >&2
      return 1
      ;;
  esac

  if [[ ! -f "$png_out" ]]; then
    printf 'Failed to generate PNG icon from: %s\n' "$icon_src" >&2
    return 1
  fi

  printf '%s\n' "$generated_dir"
}

mkdir -p "$REPO_ROOT/artifacts/build" "$REPO_ROOT/artifacts/tools"
rm -rf "$APPDIR"
ICON_SRC=$(find_icon_file || true)
if [[ -z "$ICON_SRC" ]]; then
  printf 'No Gowin icon found in vendor archive. Provide ICON_FILE=/path/to/icon extracted from the Gowin archive.\n' >&2
  exit 1
fi
ICON_DIR=$(prepare_icon_files "$ICON_SRC")

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
cp "$ICON_DIR/gowin-ide.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/"
if [[ -f "$ICON_DIR/gowin-ide.ico" ]]; then
  cp "$ICON_DIR/gowin-ide.ico" "$APPDIR/usr/share/icons/hicolor/256x256/apps/"
fi
if [[ -f "$ICON_DIR/gowin-ide.svg" ]]; then
  cp "$ICON_DIR/gowin-ide.svg" "$APPDIR/usr/share/icons/hicolor/scalable/apps/"
fi
cp "$ROOT_DIR/packaging/appimage/io.github.gowinsemi.gowin_ide.appdata.xml" "$APPDIR/usr/share/metainfo/"
cp "$ROOT_DIR/packaging/appimage/qt.conf" "$APPDIR/usr/bin/qt.conf"

ln -sf usr/share/applications/gowin-ide.desktop "$APPDIR/gowin-ide.desktop"
ln -sf usr/share/icons/hicolor/256x256/apps/gowin-ide.png "$APPDIR/gowin-ide.png"
ln -sf gowin-ide.png "$APPDIR/.DirIcon"
if [[ -f "$APPDIR/usr/share/icons/hicolor/256x256/apps/gowin-ide.ico" ]]; then
  ln -sf usr/share/icons/hicolor/256x256/apps/gowin-ide.ico "$APPDIR/gowin-ide.ico"
fi

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
ln -sf "$OUTPUT_NAME" "$REPO_ROOT/artifacts/Gowin-IDE-x86_64.AppImage"

printf 'Built %s\n' "$REPO_ROOT/artifacts/$OUTPUT_NAME"
printf 'Updated compatibility symlink %s\n' "$REPO_ROOT/artifacts/Gowin-IDE-x86_64.AppImage"
