#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

# shellcheck source=helpers.sh
. "$SCRIPT_DIR/helpers.sh"

parse_common_args "$@"
if [ "${#EXTRA_ARGS[@]}" -gt 0 ]; then
  die "Unknown arguments: ${EXTRA_ARGS[*]}"
fi

ROOTFS=${ROOTFS:-$(mktemp_dir)}

trap cleanup EXIT
trap 'fail "Unexpected error"' ERR

log "== test-extract-bootstrap =="
print_paths

if [ -x "$ROOTFS/bin/bash" ]; then
  log "Rootfs already initialized; skipping extraction."
else
  run_cmd "$REPO_ROOT/scripts/extract-bootstrap.sh" "$ROOTFS"
fi

if [ ! -x "$ROOTFS/bin/bash" ]; then
  fail "missing $ROOTFS/bin/bash"
fi

if [ ! -f "$ROOTFS/SYMLINKS.txt" ]; then
  fail "missing $ROOTFS/SYMLINKS.txt"
fi

pass "extract-bootstrap"
