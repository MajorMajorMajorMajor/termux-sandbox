#!/data/data/com.termux/files/usr/bin/sh
set -eu

ROOTFS="$HOME/sandboxes/bootstrap-test"
rm -rf "$ROOTFS"

./scripts/extract-bootstrap.sh "$ROOTFS"

time ./scripts/apply-symlinks.sh "$ROOTFS"

ls -la "$ROOTFS/bin/chmod"
