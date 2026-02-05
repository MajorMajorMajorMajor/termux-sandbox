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

log "== test-apply-symlinks =="
print_paths
timer_start

if [ ! -x "$ROOTFS/bin/bash" ] || [ ! -f "$ROOTFS/SYMLINKS.txt" ]; then
  log "Preparing rootfs via extract-bootstrap.sh"
  run_cmd "$REPO_ROOT/scripts/extract-bootstrap.sh" "$ROOTFS"
fi

run_cmd "$REPO_ROOT/scripts/apply-symlinks.sh" "$ROOTFS"

if [ ! -L "$ROOTFS/bin/chmod" ]; then
  fail "missing symlink: $ROOTFS/bin/chmod"
fi

elapsed_ms=$(timer_elapsed_ms)
log "elapsed: $(format_duration_ms "$elapsed_ms")"
pass "apply-symlinks"
