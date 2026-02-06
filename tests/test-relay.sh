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
WORKDIR=${WORKDIR:-$(mktemp_dir)}

trap cleanup EXIT
trap 'fail "Unexpected error"' ERR

log "== test-relay =="
print_paths
timer_start

require_cmd proot

if [ ! -x "$ROOTFS/bin/bash" ]; then
  log "Preparing rootfs via extract-bootstrap.sh"
  run_cmd "$REPO_ROOT/scripts/extract-bootstrap.sh" "$ROOTFS"
  run_cmd "$REPO_ROOT/scripts/apply-symlinks.sh" "$ROOTFS"
fi

mkdir -p "$ROOTFS/home/agent" "$ROOTFS/home/agent/work" "$ROOTFS/etc/dpkg/dpkg.cfg.d"
mkdir -p "$WORKDIR"

HOST_PREFIX="/data/data/com.termux/files/usr"
ENV_TERM=${TERM:-xterm-256color}
ENV_PATH="$HOST_PREFIX/bin:$HOST_PREFIX/bin/applets"
RELAY_ENV_PATH="$HOST_PREFIX/tmp/sandbox-bin:$ENV_PATH"
ENV_LD_PRELOAD="$HOST_PREFIX/lib/libtermux-exec-ld-preload.so"

# Start relay server
RELAY_DIR="$ROOTFS/tmp/sandbox-relay"
rm -rf "$RELAY_DIR"
run_cmd "$REPO_ROOT/scripts/sandbox-relay.sh" "$RELAY_DIR" &
RELAY_PID=$!
sleep 0.3

# Install relay client in a PATH overlay (preserves original bin/am)
SANDBOX_BIN="$ROOTFS/tmp/sandbox-bin"
mkdir -p "$SANDBOX_BIN"
cp "$REPO_ROOT/scripts/sandbox-relay-client.sh" "$SANDBOX_BIN/am"
chmod 755 "$SANDBOX_BIN/am"

# Test: run am inside proot and check output
RELAY_PROOT_CMD=(
  env -i
  TERM="$ENV_TERM"
  HOME=/data/data/com.termux/files/usr/home/agent
  PREFIX=/data/data/com.termux/files/usr
  TERMUX_PREFIX=/data/data/com.termux/files/usr
  LD_PRELOAD="$ENV_LD_PRELOAD"
  PATH="$RELAY_ENV_PATH"
  proot
  --link2symlink
  -b "$ROOTFS":/data/data/com.termux/files/usr
  -b "$WORKDIR":/data/data/com.termux/files/usr/home/agent/work
  -b /dev -b /proc -b /sys -b /system -b /apex
  -w /data/data/com.termux/files/usr/home/agent
  /data/data/com.termux/files/usr/bin/bash
  -lc
)

# Test 1: am produces output via relay
log "Testing am via relay inside proot..."
am_output=""
if command -v timeout >/dev/null 2>&1; then
  am_output=$(timeout 20 "${RELAY_PROOT_CMD[@]}" 'am start --help 2>&1' 2>&1) || true
else
  am_output=$("${RELAY_PROOT_CMD[@]}" 'am start --help 2>&1' 2>&1) || true
fi

if printf '%s' "$am_output" | grep -qi "activity manager"; then
  log "am via relay: ok"
else
  log "am output: $am_output"
  kill "$RELAY_PID" 2>/dev/null || true
  fail "am via relay did not produce expected output"
fi

# Clean up relay
kill "$RELAY_PID" 2>/dev/null || true
rm -rf "$RELAY_DIR"
rm -rf "$SANDBOX_BIN"

elapsed_ms=$(timer_elapsed_ms)
log "elapsed: $(format_duration_ms "$elapsed_ms")"
pass "relay"
