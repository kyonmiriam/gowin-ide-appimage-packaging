#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$ROOT_DIR/.." && pwd)

usage() {
  cat <<'EOF'
Usage:
  prepare-vendor-from-tarball.sh /path/to/Gowin_V<version>_linux.tar.gz

Extracts the user-provided Gowin Linux archive into vendor/IDE and
vendor/Programmer. The archive is not copied into the repository.
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

if [[ ! -f "$TARBALL" ]]; then
  printf 'Missing Gowin archive: %s\n' "$TARBALL" >&2
  exit 1
fi

case "$(basename "$TARBALL")" in
  *.tar|*.tar.gz|*.tgz|*.tar.xz|*.txz|*.tar.zst|*.tzst) ;;
  *)
    printf 'Unsupported archive extension: %s\n' "$TARBALL" >&2
    exit 1
    ;;
esac

VERSION=$(basename "$TARBALL" | sed -E 's/^Gowin_?V?([^_]+(_SP[0-9]+)?).*$/\1/')
if [[ -z "$VERSION" || "$VERSION" == "$(basename "$TARBALL")" ]]; then
  VERSION="unknown"
fi

TMP_DIR=$(mktemp -d)
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

tar -xf "$TARBALL" -C "$TMP_DIR"

IDE_BIN=$(find "$TMP_DIR" -type f -path '*/IDE/bin/gw_ide' -print -quit)
PROGRAMMER_BIN=$(find "$TMP_DIR" -type f -path '*/Programmer/bin/programmer' -print -quit)
IDE_SRC="${IDE_BIN%/bin/gw_ide}"
PROGRAMMER_SRC="${PROGRAMMER_BIN%/bin/programmer}"

if [[ -z "$IDE_SRC" || ! -x "$IDE_SRC/bin/gw_ide" ]]; then
  printf 'Could not locate IDE/bin/gw_ide inside %s\n' "$TARBALL" >&2
  exit 1
fi

if [[ -z "$PROGRAMMER_SRC" || ! -x "$PROGRAMMER_SRC/bin/programmer" ]]; then
  printf 'Could not locate Programmer/bin/programmer inside %s\n' "$TARBALL" >&2
  exit 1
fi

mkdir -p "$REPO_ROOT/vendor"
rm -rf "$REPO_ROOT/vendor/IDE" "$REPO_ROOT/vendor/Programmer"
cp -a "$IDE_SRC" "$REPO_ROOT/vendor/IDE"
cp -a "$PROGRAMMER_SRC" "$REPO_ROOT/vendor/Programmer"
printf '%s\n' "$VERSION" > "$REPO_ROOT/vendor/.gowin-version"

printf 'Prepared vendor/IDE and vendor/Programmer from %s\n' "$TARBALL"
printf 'Detected Gowin version: %s\n' "$VERSION"
