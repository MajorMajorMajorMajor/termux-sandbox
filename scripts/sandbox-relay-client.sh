#!/data/data/com.termux/files/usr/bin/sh
# sandbox-relay-client: runs inside proot sandbox as a replacement for `am`.
# Sends the command to the host-side relay server via a shared directory.
set -eu

RELAY_DIR="/data/data/com.termux/files/usr/tmp/sandbox-relay"

if [ ! -d "$RELAY_DIR" ]; then
  echo "Error: sandbox relay not running (missing $RELAY_DIR)" >&2
  exit 1
fi

# Create a unique request directory
req_id="req-$$-$(date +%s%N 2>/dev/null || echo $$)"
req_dir="$RELAY_DIR/$req_id"
mkdir -p "$req_dir"

cleanup() {
  rm -rf "$req_dir"
}
trap cleanup EXIT INT TERM

# Write raw null-delimited arguments (no shell escaping/eval needed)
: > "$req_dir/args"
for arg in "$@"; do
  printf '%s\0' "$arg" >> "$req_dir/args"
done

# Create response FIFO
mkfifo "$req_dir/response"

# Signal the server that the request is ready
touch "$RELAY_DIR/$req_id.ready"

# Read response (blocks until server writes)
response_timeout=30
response_status=0
if command -v timeout >/dev/null 2>&1; then
  if ! timeout "$response_timeout" cat "$req_dir/response" 2>/dev/null; then
    response_status=$?
  fi
else
  cat "$req_dir/response" 2>/dev/null &
  cat_pid=$!
  elapsed=0
  while kill -0 "$cat_pid" 2>/dev/null; do
    if [ "$elapsed" -ge "$response_timeout" ]; then
      kill "$cat_pid" 2>/dev/null || true
      wait "$cat_pid" 2>/dev/null || true
      response_status=124
      break
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
  if [ "$response_status" -eq 0 ]; then
    wait "$cat_pid" 2>/dev/null || response_status=$?
  fi
fi

# Read exit code
rc=0
if [ -f "$req_dir/exit" ]; then
  rc=$(cat "$req_dir/exit")
elif [ "$response_status" -eq 124 ]; then
  echo "Error: relay response timed out after ${response_timeout}s" >&2
  rc=124
fi

exit "${rc:-0}"
