#!/data/data/com.termux/files/usr/bin/sh
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

ROOTFS="$HOME/sandboxes/bootstrap-test"
rm -rf "$ROOTFS"

"$REPO_ROOT/scripts/extract-bootstrap.sh" "$ROOTFS"

"$REPO_ROOT/scripts/apply-symlinks.sh" "$ROOTFS"

ls -la "$ROOTFS/bin/chmod"
