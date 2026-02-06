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

# Write arguments (printf %q encoded for safe eval on host side)
args=""
for arg in "$@"; do
  if [ -n "$args" ]; then
    args="$args "
  fi
  # Shell-escape each argument
  escaped=$(printf '%s' "$arg" | sed "s/'/'\\\\''/g")
  args="$args'$escaped'"
done
printf '%s' "$args" > "$req_dir/args"

# Create response FIFO
mkfifo "$req_dir/response"

# Signal the server that the request is ready
touch "$RELAY_DIR/$req_id.ready"

# Read response (blocks until server writes)
timeout 30 cat "$req_dir/response" 2>/dev/null || true

# Read exit code
rc=0
if [ -f "$req_dir/exit" ]; then
  rc=$(cat "$req_dir/exit")
fi

# Clean up our request dir
rm -rf "$req_dir"

exit "${rc:-0}"
