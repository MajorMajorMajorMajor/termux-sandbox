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

ROOTFS=${ROOTFS:-$(cached_rootfs)}
WORKDIR=${WORKDIR:-$(mktemp_dir)}

trap cleanup EXIT
trap 'fail "Unexpected error"' ERR

log "== test-relay-hup =="
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

RELAY_DIR="$ROOTFS/tmp/sandbox-relay"
rm -rf "$RELAY_DIR"

# Start relay server and verify it survives SIGHUP.
run_cmd "$REPO_ROOT/scripts/sandbox-relay.sh" "$RELAY_DIR" &
RELAY_PID=$!
sleep 0.3

kill -HUP "$RELAY_PID"
sleep 0.3
if ! kill -0 "$RELAY_PID" 2>/dev/null; then
  fail "relay exited after SIGHUP"
fi
log "relay survived SIGHUP"

# Install relay client in PATH overlay.
SANDBOX_BIN="$ROOTFS/tmp/sandbox-bin"
mkdir -p "$SANDBOX_BIN"
cp "$REPO_ROOT/scripts/sandbox-relay-client.sh" "$SANDBOX_BIN/am"
chmod 755 "$SANDBOX_BIN/am"

RELAY_PROOT_CMD=(
  env -i
  TERM="$ENV_TERM"
  HOME=/data/data/com.termux/files/usr/home/agent
  PREFIX=/data/data/com.termux/files/usr
  TERMUX_PREFIX=/data/data/com.termux/files/usr
  LD_PRELOAD="$ENV_LD_PRELOAD"
  PATH="$RELAY_ENV_PATH"
  proot
  --kill-on-exit
  --link2symlink
  -b "$ROOTFS":/data/data/com.termux/files/usr
  -b "$WORKDIR":/data/data/com.termux/files/usr/home/agent/work
  -b /dev -b /proc -b /sys -b /system -b /apex
  -w /data/data/com.termux/files/usr/home/agent
  /data/data/com.termux/files/usr/bin/bash
  -lc
)

# Verify relay still works after SIGHUP.
am_output=""
if command -v timeout >/dev/null 2>&1; then
  am_output=$(timeout 20 "${RELAY_PROOT_CMD[@]}" 'am start --help 2>&1' 2>&1) || true
else
  am_output=$("${RELAY_PROOT_CMD[@]}" 'am start --help 2>&1' 2>&1) || true
fi

if printf '%s' "$am_output" | grep -qi "activity manager"; then
  log "am via relay after SIGHUP: ok"
else
  log "am output: $am_output"
  kill "$RELAY_PID" 2>/dev/null || true
  fail "relay failed after SIGHUP"
fi

kill "$RELAY_PID" 2>/dev/null || true
rm -rf "$RELAY_DIR"
rm -rf "$SANDBOX_BIN"

elapsed_ms=$(timer_elapsed_ms)
log "elapsed: $(format_duration_ms "$elapsed_ms")"
pass "relay-hup"
