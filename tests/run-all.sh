#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=helpers.sh
. "$SCRIPT_DIR/helpers.sh"

parse_common_args "$@"
if [ "${#EXTRA_ARGS[@]}" -gt 0 ]; then
  die "Unknown arguments: ${EXTRA_ARGS[*]}"
fi

ROOTFS_CACHE=${ROOTFS:-$(mktemp_dir)}
WORKDIR_CACHE=${WORKDIR:-$(mktemp_dir)}

trap cleanup EXIT
trap 'fail "Unexpected error"' ERR

log "== run-all =="
log "rootfs cache: $ROOTFS_CACHE"
log "workdir cache: $WORKDIR_CACHE"

mkdir -p "$ROOTFS_CACHE" "$WORKDIR_CACHE"

TEST_FLAGS=()
if [ "$KEEP" -eq 1 ]; then
  TEST_FLAGS+=(--keep)
fi
if [ "$VERBOSE" -eq 0 ]; then
  TEST_FLAGS+=(--quiet)
fi

RESULTS=()
FAIL_COUNT=0

run_test() {
  local test_name="$1"
  shift
  log "-- running $test_name --"
  if "$SCRIPT_DIR/$test_name" "$@"; then
    RESULTS+=("$test_name: PASS")
  else
    RESULTS+=("$test_name: FAIL")
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

run_test "test-extract-bootstrap.sh" "${TEST_FLAGS[@]}" --rootfs "$ROOTFS_CACHE"
run_test "test-apply-symlinks.sh" "${TEST_FLAGS[@]}" --rootfs "$ROOTFS_CACHE"
run_test "test-proot.sh" "${TEST_FLAGS[@]}" --rootfs "$ROOTFS_CACHE" --workdir "$WORKDIR_CACHE"
run_test "test-asb.sh" "${TEST_FLAGS[@]}"

printf '\n== Summary ==\n'
for result in "${RESULTS[@]}"; do
  printf '%s\n' "$result"
done

if [ "$FAIL_COUNT" -gt 0 ]; then
  printf 'FAIL (%s)\n' "$FAIL_COUNT"
  exit 1
fi

printf 'PASS\n'
