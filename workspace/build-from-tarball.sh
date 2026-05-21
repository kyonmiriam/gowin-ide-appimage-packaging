#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

usage() {
  cat <<'EOF'
Usage:
  build-from-tarball.sh /path/to/Gowin_V<version>_linux.tar.gz

Optional environment:
  ICON_FILE=/path/to/icon.png|icon.ico|icon.svg
      Use an icon supplied by the user. If unset, the build script searches the
      extracted Gowin archive for an icon file.
  APPIMAGETOOL=/path/to/appimagetool-x86_64.AppImage
      Use a specific appimagetool binary.
  ASSEMBLE_ONLY=1
      Stop after creating artifacts/build/GowinIDE.AppDir.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

TARBALL="${1:-}"
if [[ -z "$TARBALL" ]]; then
  usage >&2
  exit 2
fi

bash "$ROOT_DIR/prepare-vendor-from-tarball.sh" "$TARBALL"
bash "$ROOT_DIR/build-ide-appimage.sh"
