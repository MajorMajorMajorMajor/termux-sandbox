#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

VERBOSE=${VERBOSE:-1}
KEEP=${KEEP:-0}
ROOTFS=""
WORKDIR=""
TEMP_DIRS=()
EXTRA_ARGS=()
TEST_CACHE_DIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/termux-sandbox-test-cache"

log() {
  if [ "$VERBOSE" -eq 1 ]; then
    printf '%s\n' "$*"
  fi
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

mktemp_dir() {
  local dir
  dir=$(mktemp -d)
  TEMP_DIRS+=("$dir")
  printf '%s' "$dir"
}

cleanup() {
  if [ "$KEEP" -eq 1 ]; then
    return
  fi
  local dir
  for dir in "${TEMP_DIRS[@]}"; do
    [ -n "$dir" ] && rm -rf "$dir"
  done
}

# Return a cached rootfs path, bootstrapping only if needed.
# Does NOT add to TEMP_DIRS (cache is persistent across runs).
cached_rootfs() {
  local rootfs="$TEST_CACHE_DIR/rootfs"
  if [ ! -x "$rootfs/bin/bash" ]; then
    mkdir -p "$rootfs"
    log "Bootstrapping test cache: $rootfs" >&2
    "$REPO_ROOT/scripts/extract-bootstrap.sh" "$rootfs" >&2
    "$REPO_ROOT/scripts/apply-symlinks.sh" "$rootfs" >&2
  else
    log "Using cached rootfs: $rootfs" >&2
  fi
  printf '%s' "$rootfs"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

print_paths() {
  if [ -n "${ROOTFS:-}" ]; then
    log "rootfs: $ROOTFS"
  fi
  if [ -n "${WORKDIR:-}" ]; then
    log "workdir: $WORKDIR"
  fi
}

pass() {
  printf 'PASS: %s\n' "${1:-}"
}

fail() {
  printf 'FAIL: %s\n' "${1:-}" >&2
  exit 1
}

run_cmd() {
  log "+ $*"
  "$@"
}

timestamp_ms() {
  local ts
  ts=$(date +%s%3N 2>/dev/null || true)
  if [[ -z "$ts" || "$ts" =~ [^0-9] ]]; then
    ts=$(date +%s)
    ts=$((ts * 1000))
  fi
  printf '%s' "$ts"
}

timer_start() {
  TEST_TIMER_START=$(timestamp_ms)
}

timer_elapsed_ms() {
  local end
  end=$(timestamp_ms)
  printf '%s' $((end - TEST_TIMER_START))
}

format_duration_ms() {
  local ms=${1:-0}
  awk -v ms="$ms" 'BEGIN { printf "%.3fs", ms / 1000 }'
}

parse_common_args() {
  EXTRA_ARGS=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --rootfs)
        shift
        [ -n "${1:-}" ] || die "--rootfs requires a path"
        ROOTFS="$1"
        ;;
      --workdir)
        shift
        [ -n "${1:-}" ] || die "--workdir requires a path"
        WORKDIR="$1"
        ;;
      --keep)
        KEEP=1
        ;;
      --verbose)
        VERBOSE=1
        ;;
      --quiet)
        VERBOSE=0
        ;;
      --)
        shift
        if [ "$#" -gt 0 ]; then
          EXTRA_ARGS+=("$@")
        fi
        break
        ;;
      *)
        EXTRA_ARGS+=("$1")
        ;;
    esac
    shift
  done
}
