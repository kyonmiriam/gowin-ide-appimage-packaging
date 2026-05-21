#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
APPDIR=$(cd "$SCRIPT_DIR/../.." && pwd)
if [[ ! -d "$APPDIR/Programmer" ]]; then
  APPDIR=$(cd "$SCRIPT_DIR/../../.." && pwd)
fi
RULE_SRC="$APPDIR/Programmer/Driver/50-programmer_usb.rules"
RULE_DST="/etc/udev/rules.d/50-programmer_usb.rules"

if [[ ! -f "$RULE_SRC" ]]; then
  printf 'Missing Programmer udev rule: %s\n' "$RULE_SRC" >&2
  exit 1
fi

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  TMP_RULE=$(mktemp /tmp/gowin-programmer-usb-rules.XXXXXX)
  cp "$RULE_SRC" "$TMP_RULE"
  chmod 0644 "$TMP_RULE"
  exec sudo /bin/sh -c '
    set -e
    install -m 0644 "$1" /etc/udev/rules.d/50-programmer_usb.rules
    udevadm control --reload-rules
    udevadm trigger --attr-match=idVendor=33aa --attr-match=idProduct=0120 || true
    udevadm trigger --attr-match=idVendor=0403 --attr-match=idProduct=6014 || true
    udevadm trigger --attr-match=idVendor=0403 --attr-match=idProduct=6010 || true
    rm -f "$1"
    printf "Installed /etc/udev/rules.d/50-programmer_usb.rules\n"
    printf "Reconnect the Gowin USB cable before scanning in Programmer.\n"
  ' sh "$TMP_RULE"
fi

install -m 0644 "$RULE_SRC" "$RULE_DST"
udevadm control --reload-rules
udevadm trigger --attr-match=idVendor=33aa --attr-match=idProduct=0120 || true
udevadm trigger --attr-match=idVendor=0403 --attr-match=idProduct=6014 || true
udevadm trigger --attr-match=idVendor=0403 --attr-match=idProduct=6010 || true

printf 'Installed %s\n' "$RULE_DST"
printf 'Reconnect the Gowin USB cable before scanning in Programmer.\n'
