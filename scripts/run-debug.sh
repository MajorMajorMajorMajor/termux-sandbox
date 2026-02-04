#!/data/data/com.termux/files/usr/bin/sh
set -eu

echo "== termux-apk-debug =="
./scripts/termux-apk-debug.sh

echo "== asb-debug =="
./scripts/asb-debug.sh "$@"
