#!/data/data/com.termux/files/usr/bin/sh
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

name=${1:-0}

ROOTFS=$("$REPO_ROOT/asb" "$name" --rootfs-path)
WORKDIR=$("$REPO_ROOT/asb" "$name" --workdir-path)

if [ ! -x "$ROOTFS/bin/bash" ]; then
  echo "Error: missing bash in rootfs: $ROOTFS" >&2
  exit 1
fi

ENV_TERM=${TERM:-xterm-256color}
ENV_PATH="/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/bin/applets"

run_cmd() {
  if command -v timeout >/dev/null 2>&1; then
    timeout 15 "$@"
  else
    "$@"
  fi
}

echo "== proot test =="
echo "rootfs: $ROOTFS"
echo "workdir: $WORKDIR"

run_cmd env -i \
  TERM="$ENV_TERM" \
  HOME=/data/data/com.termux/files/usr/home/agent \
  PREFIX=/data/data/com.termux/files/usr \
  TERMUX_PREFIX=/data/data/com.termux/files/usr \
  PATH="$ENV_PATH" \
  proot \
  --link2symlink \
  -0 \
  -b "$ROOTFS":/data/data/com.termux/files/usr \
  -b "$WORKDIR":/data/data/com.termux/files/usr/home/agent/work \
  -b /dev -b /proc -b /sys -b /system -b /apex \
  -w /data/data/com.termux/files/usr/home/agent \
  /data/data/com.termux/files/usr/bin/bash -lc '
    echo "inside proot"
    id
    ls -la "$HOME/work" || true
    exit 0'
