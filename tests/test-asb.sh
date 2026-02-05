#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

# shellcheck source=helpers.sh
. "$SCRIPT_DIR/helpers.sh"

parse_common_args "$@"

ASB_NAME=${ASB_NAME:-0}
args=("${EXTRA_ARGS[@]}")
while [ "${#args[@]}" -gt 0 ]; do
  case "${args[0]}" in
    --name)
      args=("${args[@]:1}")
      [ "${#args[@]}" -gt 0 ] || die "--name requires a value"
      ASB_NAME="${args[0]}"
      args=("${args[@]:1}")
      ;;
    *)
      die "Unknown argument: ${args[0]}"
      ;;
  esac
done

TEST_HOME=$(mktemp_dir)

trap cleanup EXIT
trap 'fail "Unexpected error"' ERR

log "== test-asb =="
log "sandbox name: $ASB_NAME"
log "home: $TEST_HOME"

if [ ! -x "$REPO_ROOT/asb" ]; then
  die "asb script not found or not executable: $REPO_ROOT/asb"
fi

if [[ "$ASB_NAME" == agent-sandbox-* ]]; then
  SANDBOX_NAME="$ASB_NAME"
else
  SANDBOX_NAME="agent-sandbox-$ASB_NAME"
fi

EXPECTED_ROOTFS="$TEST_HOME/sandboxes/$SANDBOX_NAME"
EXPECTED_WORKDIR="$TEST_HOME/agent-work-${SANDBOX_NAME#agent-sandbox-}"

log "+ HOME=$TEST_HOME $REPO_ROOT/asb $ASB_NAME --rootfs-path"
ROOTFS_OUT=$(HOME="$TEST_HOME" "$REPO_ROOT/asb" "$ASB_NAME" --rootfs-path)

log "+ HOME=$TEST_HOME $REPO_ROOT/asb $ASB_NAME --workdir-path"
WORKDIR_OUT=$(HOME="$TEST_HOME" "$REPO_ROOT/asb" "$ASB_NAME" --workdir-path)

if [ "$ROOTFS_OUT" != "$EXPECTED_ROOTFS" ]; then
  fail "unexpected rootfs path: $ROOTFS_OUT"
fi

if [ "$WORKDIR_OUT" != "$EXPECTED_WORKDIR" ]; then
  fail "unexpected workdir path: $WORKDIR_OUT"
fi

log "Non-interactive launch should fail when sandbox is missing"
if output=$(HOME="$TEST_HOME" "$REPO_ROOT/asb" "$ASB_NAME" </dev/null 2>&1); then
  fail "expected non-interactive asb to fail"
else
  if ! printf '%s' "$output" | grep -qi "does not exist"; then
    fail "unexpected error message: $output"
  fi
fi

pass "asb"
