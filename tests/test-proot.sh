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
PROOT_SCRIPT='echo "inside proot"; id; pwd; echo "HOME=$HOME"; ls -1 "$HOME"; echo "PARENT=$(basename "$HOME/..")"; ls -la "$HOME/work" || true'

PROOT_CMD=(
  env -i
  TERM="$ENV_TERM"
  HOME=/data/data/com.termux/files/home/agent
  PREFIX=/data/data/com.termux/files/usr
  TERMUX_PREFIX=/data/data/com.termux/files/usr
  PATH="$ENV_PATH"
  proot
  --kill-on-exit
  -b "$ROOTFS":/data/data/com.termux/files/usr
  -b "$ROOTFS/home":/data/data/com.termux/files/home
  -b "$WORKDIR":/data/data/com.termux/files/home/agent/work
  -b /dev -b /proc -b /sys -b /system -b /apex
  -w /data/data/com.termux/files/home/agent
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
  HOME=/data/data/com.termux/files/home/agent
  PREFIX=/data/data/com.termux/files/usr
  TERMUX_PREFIX=/data/data/com.termux/files/usr
  LD_PRELOAD="$ENV_LD_PRELOAD"
  PATH="$ENV_PATH"
  proot
  --kill-on-exit
  -b "$ROOTFS":/data/data/com.termux/files/usr
  -b "$ROOTFS/home":/data/data/com.termux/files/home
  -b "$WORKDIR":/data/data/com.termux/files/home/agent/work
  -b /dev -b /proc -b /sys -b /system -b /apex
  -w /data/data/com.termux/files/home/agent
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

# Test git object integrity for file:// shallow clone inside proot.
# Skip when git is not installed in the sandbox rootfs cache.
if command -v git >/dev/null 2>&1 && [ -x "$ROOTFS/bin/git" ]; then
  log "Testing git clone object integrity inside proot..."
  rm -rf "$WORKDIR/git-seed-src" "$WORKDIR/git-seed-remote.git" "$WORKDIR/git-seed-clone"
  mkdir -p "$WORKDIR/git-seed-src"
  run_cmd git -C "$WORKDIR/git-seed-src" init -q
  run_cmd git -C "$WORKDIR/git-seed-src" config user.name "Test"
  run_cmd git -C "$WORKDIR/git-seed-src" config user.email "test@example.com"
  printf 'one\n' > "$WORKDIR/git-seed-src/f.txt"
  run_cmd git -C "$WORKDIR/git-seed-src" add f.txt
  run_cmd git -C "$WORKDIR/git-seed-src" commit -q -m "one"
  printf 'two\n' >> "$WORKDIR/git-seed-src/f.txt"
  run_cmd git -C "$WORKDIR/git-seed-src" commit -q -am "two"
  run_cmd git clone --bare "$WORKDIR/git-seed-src" "$WORKDIR/git-seed-remote.git"

  GIT_PROOT_SCRIPT='set -euo pipefail; rm -rf "$HOME/work/git-seed-clone"; git -c protocol.file.allow=always clone --depth=1 "file://$HOME/work/git-seed-remote.git" "$HOME/work/git-seed-clone"; git -C "$HOME/work/git-seed-clone" fsck --full'
  if command -v timeout >/dev/null 2>&1; then
    run_cmd timeout 20 "${SHEBANG_PROOT_BASE[@]}" "$GIT_PROOT_SCRIPT"
  else
    run_cmd "${SHEBANG_PROOT_BASE[@]}" "$GIT_PROOT_SCRIPT"
  fi
else
  log "Skipping git clone integrity test (git missing on host or in $ROOTFS)"
fi

elapsed_ms=$(timer_elapsed_ms)
log "elapsed: $(format_duration_ms "$elapsed_ms")"
pass "proot"
