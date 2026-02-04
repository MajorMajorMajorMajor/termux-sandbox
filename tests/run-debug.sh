#!/data/data/com.termux/files/usr/bin/sh
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

echo "== termux-apk-debug =="
"$SCRIPT_DIR/termux-apk-debug.sh"

echo "== asb-debug =="
(cd "$REPO_ROOT" && "$SCRIPT_DIR/asb-debug.sh" "$@")
