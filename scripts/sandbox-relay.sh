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

cleanup() {
  rm -rf "$RELAY_DIR"
}
trap cleanup EXIT

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

    # Execute am on the host using raw null-delimited args (no eval)
    set +e
    if [ -s "$args_file" ]; then
      output=$(xargs -0 am < "$args_file" 2>&1)
    else
      output=$(am 2>&1)
    fi
    rc=$?
    set -e

    # Write exit code
    printf '%d' "$rc" > "$exit_file"

    # Write response to FIFO (client is blocking on read)
    if [ -p "$response_fifo" ]; then
      printf '%s' "$output" > "$response_fifo"
    fi
  done

  # Polling interval
  sleep 0.1
done
