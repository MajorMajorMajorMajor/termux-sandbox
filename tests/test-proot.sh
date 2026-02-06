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

log "== test-proot =="
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

ENV_TERM=${TERM:-xterm-256color}
ENV_PATH="/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/bin/applets"
PROOT_SCRIPT='echo "inside proot"; id; pwd; ls -la "$HOME/work" || true'

PROOT_CMD=(
  env -i
  TERM="$ENV_TERM"
  HOME=/data/data/com.termux/files/usr/home/agent
  PREFIX=/data/data/com.termux/files/usr
  TERMUX_PREFIX=/data/data/com.termux/files/usr
  PATH="$ENV_PATH"
  proot
  --kill-on-exit
  --link2symlink
  -b "$ROOTFS":/data/data/com.termux/files/usr
  -b "$WORKDIR":/data/data/com.termux/files/usr/home/agent/work
  -b /dev -b /proc -b /sys -b /system -b /apex
  -w /data/data/com.termux/files/usr/home/agent
  /data/data/com.termux/files/usr/bin/bash
  -lc
  "$PROOT_SCRIPT"
)

if command -v timeout >/dev/null 2>&1; then
  run_cmd timeout 20 "${PROOT_CMD[@]}"
else
  run_cmd "${PROOT_CMD[@]}"
fi

# Test /usr/bin shebang compatibility via LD_PRELOAD (termux-exec)
log "Testing /usr/bin shebang compatibility via termux-exec..."

HOST_PREFIX="/data/data/com.termux/files/usr"
ENV_LD_PRELOAD="$HOST_PREFIX/lib/libtermux-exec-ld-preload.so"

cat > "$WORKDIR/test-env-shebang.sh" <<'SCRIPT'
#!/usr/bin/env bash
echo "env-shebang-ok"
SCRIPT
chmod +x "$WORKDIR/test-env-shebang.sh"

cat > "$WORKDIR/test-usr-bin-sh.sh" <<'SCRIPT'
#!/usr/bin/sh
echo "usr-bin-sh-ok"
SCRIPT
chmod +x "$WORKDIR/test-usr-bin-sh.sh"

SHEBANG_PROOT_BASE=(
  env -i
  TERM="$ENV_TERM"
  HOME=/data/data/com.termux/files/usr/home/agent
  PREFIX=/data/data/com.termux/files/usr
  TERMUX_PREFIX=/data/data/com.termux/files/usr
  LD_PRELOAD="$ENV_LD_PRELOAD"
  PATH="$ENV_PATH"
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

run_shebang_test() {
  local label="$1"
  local script="$2"
  local expect="$3"
  local output=""
  if command -v timeout >/dev/null 2>&1; then
    output=$(timeout 20 "${SHEBANG_PROOT_BASE[@]}" "$script" 2>&1) || true
  else
    output=$("${SHEBANG_PROOT_BASE[@]}" "$script" 2>&1) || true
  fi
  if printf '%s' "$output" | grep -q "$expect"; then
    log "$label: ok"
  else
    log "$label output: $output"
    fail "$label: expected '$expect' not found"
  fi
}

run_shebang_test "#!/usr/bin/env bash" '$HOME/work/test-env-shebang.sh' "env-shebang-ok"
run_shebang_test "#!/usr/bin/sh" '$HOME/work/test-usr-bin-sh.sh' "usr-bin-sh-ok"

elapsed_ms=$(timer_elapsed_ms)
log "elapsed: $(format_duration_ms "$elapsed_ms")"
pass "proot"
