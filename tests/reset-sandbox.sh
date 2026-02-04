#!/data/data/com.termux/files/usr/bin/sh
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

name=${1:-0}

ROOTFS=$("$REPO_ROOT/asb" "$name" --rootfs-path)
WORKDIR=$("$REPO_ROOT/asb" "$name" --workdir-path)

echo "Removing rootfs: $ROOTFS" >&2
rm -rf "$ROOTFS"

echo "Removing workdir: $WORKDIR" >&2
rm -rf "$WORKDIR"

echo "Done." >&2
