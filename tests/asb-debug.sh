#!/data/data/com.termux/files/usr/bin/sh
set -eu

name=${1:-0}
if [ "$#" -gt 0 ]; then
  shift
fi

echo "== asb paths =="
./asb "$name" --rootfs-path
./asb "$name" --workdir-path

echo "== asb run (timeout 10s) =="
rm -rf "$(./asb "$name" --rootfs-path)"
if command -v timeout >/dev/null 2>&1; then
  timeout 10 ./asb "$name" "$@" || true
else
  ./asb "$name" "$@" || true
fi
