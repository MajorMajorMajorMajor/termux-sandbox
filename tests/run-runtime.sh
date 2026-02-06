#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=helpers.sh
. "$SCRIPT_DIR/helpers.sh"

parse_common_args "$@"
if [ "${#EXTRA_ARGS[@]}" -gt 0 ]; then
  die "Unknown arguments: ${EXTRA_ARGS[*]}"
fi

ROOTFS_CACHE=${ROOTFS:-$(cached_rootfs)}
WORKDIR_CACHE=${WORKDIR:-$(mktemp_dir)}

trap cleanup EXIT
trap 'fail "Unexpected error"' ERR

log "== run-runtime =="
log "rootfs cache: $ROOTFS_CACHE"
log "workdir cache: $WORKDIR_CACHE"

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
  local status
  local start_ms end_ms elapsed_ms duration
  shift
  log "-- running $test_name --"
  start_ms=$(timestamp_ms)
  if "$SCRIPT_DIR/$test_name" "$@"; then
    status="PASS"
  else
    status="FAIL"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
  end_ms=$(timestamp_ms)
  elapsed_ms=$((end_ms - start_ms))
  duration=$(format_duration_ms "$elapsed_ms")
  RESULTS+=("$test_name: $status ($duration)")
}

run_test "test-proot.sh" "${TEST_FLAGS[@]}" --rootfs "$ROOTFS_CACHE" --workdir "$WORKDIR_CACHE"
run_test "test-relay.sh" "${TEST_FLAGS[@]}" --rootfs "$ROOTFS_CACHE" --workdir "$WORKDIR_CACHE"
run_test "test-asb.sh" "${TEST_FLAGS[@]}"

printf '\n== Summary (runtime) ==\n'
for result in "${RESULTS[@]}"; do
  printf '%s\n' "$result"
done

if [ "$FAIL_COUNT" -gt 0 ]; then
  printf 'FAIL (%s)\n' "$FAIL_COUNT"
  exit 1
fi

printf 'PASS\n'
