#!/data/data/com.termux/files/usr/bin/sh
# sandbox-relay: host-side relay server for executing commands from inside proot.
# Watches a shared directory for request files and executes them on the host.
set -eu

RELAY_DIR="${1:-}"
if [ -z "$RELAY_DIR" ]; then
  echo "Usage: sandbox-relay.sh <relay-dir>" >&2
  exit 1
fi

mkdir -p "$RELAY_DIR"

# Relay directory is rooted inside the sandbox rootfs at <rootfs>/tmp/sandbox-relay.
# Map sandbox-visible absolute paths back to host-visible rootfs paths before invoking am.
SANDBOX_PREFIX="/data/data/com.termux/files/usr"
ROOTFS_DIR=$(dirname "$(dirname "$RELAY_DIR")")

cleanup() {
  rm -rf "$RELAY_DIR"
}
trap cleanup EXIT
trap '' HUP

while true; do
  for ready_file in "$RELAY_DIR"/req-*.ready; do
    [ -f "$ready_file" ] || continue

    req_id="${ready_file%.ready}"
    req_id="${req_id##*/}"
    req_dir="$RELAY_DIR/$req_id"
    args_file="$req_dir/args"
    response_fifo="$req_dir/response"
    exit_file="$req_dir/exit"

    # Remove ready marker immediately to avoid reprocessing
    rm -f "$ready_file"

    if [ ! -d "$req_dir" ] || [ ! -f "$args_file" ]; then
      continue
    fi

    # Execute am on the host using raw null-delimited args (no eval).
    # Translate sandbox paths (e.g. /data/.../usr/tmp/...) to host rootfs paths
    # so Termux:API can write/read files visible to processes in the sandbox.
    set +e
    if [ -s "$args_file" ]; then
      output=$(
        SANDBOX_PREFIX="$SANDBOX_PREFIX" ROOTFS_DIR="$ROOTFS_DIR" \
        perl -e 'local $/ = "\0"; while (defined(my $arg = <>)) { $arg =~ s/\0\z//; if (index($arg, $ENV{"SANDBOX_PREFIX"}) == 0) { $arg = $ENV{"ROOTFS_DIR"} . substr($arg, length($ENV{"SANDBOX_PREFIX"})); } print $arg, "\0"; }' "$args_file" \
          | xargs -0 am 2>&1
      )
    else
      output=$(am 2>&1)
    fi
    rc=$?
    set -e

    # Write exit code (client may already have timed out and cleaned up)
    if [ -d "$req_dir" ]; then
      printf '%d' "$rc" > "$exit_file" 2>/dev/null || true
    fi

    # Write response to FIFO (client is blocking on read)
    if [ -p "$response_fifo" ]; then
      printf '%s' "$output" > "$response_fifo" 2>/dev/null || true
    fi
  done

  # Polling interval (sleep can be interrupted by signals; avoid exiting under set -e)
  sleep 0.1 || true
done
