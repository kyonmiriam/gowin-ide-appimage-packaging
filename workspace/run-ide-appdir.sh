#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$ROOT_DIR/.." && pwd)
APPDIR="$REPO_ROOT/artifacts/build/GowinIDE.AppDir"

if [[ ! -x "$APPDIR/AppRun" ]]; then
  ASSEMBLE_ONLY=1 bash "$ROOT_DIR/build-ide-appimage.sh"
fi

if [[ ! -x "$APPDIR/AppRun" ]]; then
  printf 'Missing AppDir launcher after assembly: %s\n' "$APPDIR/AppRun" >&2
  exit 1
fi

exec "$APPDIR/AppRun" "$@"
