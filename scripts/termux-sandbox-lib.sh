#!/data/data/com.termux/files/usr/bin/sh
set -eu

termux_sandbox_map_arch() {
  case "$(uname -m)" in
    aarch64|arm64) echo "aarch64" ;;
    armv7l|armv8l|arm) echo "arm" ;;
    i686|i386) echo "i686" ;;
    x86_64) echo "x86_64" ;;
    *)
      echo "" ;;
  esac
}

termux_sandbox_ensure_unzip() {
  if ! command -v unzip >/dev/null 2>&1; then
    echo "Error: unzip is required. Install with: pkg install unzip" >&2
    exit 1
  fi
}

termux_sandbox_download_file() {
  url="$1"
  dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -L -o "$dest" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$dest" "$url"
  else
    echo "Error: curl or wget is required to download bootstraps." >&2
    exit 1
  fi
}

termux_sandbox_find_helper() {
  helper="$1"
  if [ -n "${TERMUX_SANDBOX_SCRIPT_DIR:-}" ] && [ -x "$TERMUX_SANDBOX_SCRIPT_DIR/scripts/$helper" ]; then
    echo "$TERMUX_SANDBOX_SCRIPT_DIR/scripts/$helper"
    return 0
  fi
  if [ -x "$HOME/.termux-sandbox/scripts/$helper" ]; then
    echo "$HOME/.termux-sandbox/scripts/$helper"
    return 0
  fi
  return 1
}

termux_sandbox_run_helper() {
  helper_path=$(termux_sandbox_find_helper "$1" || true)
  if [ -z "$helper_path" ]; then
    echo "Error: helper script '$1' not found. Ensure scripts are installed." >&2
    exit 1
  fi
  shift
  "$helper_path" "$@"
}

termux_sandbox_extract_bootstrap_from_termux() {
  rootfs="$1"
  termux_sandbox_run_helper "extract-bootstrap.sh" "$rootfs"
}

termux_sandbox_bootstrap_from_prefix() {
  sandbox_name="$1"
  rootfs="$2"
  host_prefix="$3"

  echo "Bootstrapping sandbox '$sandbox_name' from current Termux prefix..." >&2
  echo "Rootfs: $rootfs" >&2
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$host_prefix/" "$rootfs/"
  else
    cp -a "$host_prefix/." "$rootfs/"
  fi
}

termux_sandbox_bootstrap_from_mirror() {
  rootfs="$1"
  host_prefix="$2"

  arch=$(termux_sandbox_map_arch)
  if [ -z "$arch" ]; then
    echo "Error: unsupported architecture: $(uname -m)" >&2
    exit 1
  fi

  mirror_url=""
  for list in "$host_prefix/etc/apt/sources.list" "$host_prefix/etc/apt/sources.list.d"/*.list; do
    [ -f "$list" ] || continue
    mirror_url=$(awk '$1=="deb" {print $2; exit}' "$list")
    [ -n "$mirror_url" ] && break
  done
  if [ -z "$mirror_url" ]; then
    echo "Error: could not determine Termux mirror from apt sources." >&2
    exit 1
  fi

  mirror_base=$(printf "%s" "$mirror_url" | sed 's#/apt/.*##')
  if [ -z "$mirror_base" ]; then
    echo "Error: failed to parse mirror base from $mirror_url" >&2
    exit 1
  fi

  termux_sandbox_ensure_unzip
  tmp_dir=$(mktemp -d)
  bootstrap_zip="$tmp_dir/bootstrap-$arch.zip"
  url="$mirror_base/bootstrap/bootstrap-$arch.zip"
  echo "Downloading bootstrap from $url" >&2
  termux_sandbox_download_file "$url" "$bootstrap_zip"
  unzip -q "$bootstrap_zip" -d "$rootfs"
  rm -rf "$tmp_dir"
}

termux_sandbox_bootstrap_from_url() {
  rootfs="$1"
  bootstrap_url="$2"

  arch=$(termux_sandbox_map_arch)
  if [ -z "$arch" ]; then
    echo "Error: unsupported architecture: $(uname -m)" >&2
    exit 1
  fi

  termux_sandbox_ensure_unzip
  tmp_dir=$(mktemp -d)
  bootstrap_zip="$tmp_dir/bootstrap-$arch.zip"
  echo "Downloading bootstrap from $bootstrap_url" >&2
  termux_sandbox_download_file "$bootstrap_url" "$bootstrap_zip"
  unzip -q "$bootstrap_zip" -d "$rootfs"
  rm -rf "$tmp_dir"
}

termux_sandbox_bootstrap_from_file() {
  rootfs="$1"
  bootstrap_file="$2"

  termux_sandbox_ensure_unzip
  if [ ! -f "$bootstrap_file" ]; then
    echo "Error: bootstrap file not found: $bootstrap_file" >&2
    exit 1
  fi
  unzip -q "$bootstrap_file" -d "$rootfs"
}

termux_sandbox_apply_symlinks() {
  rootfs="$1"
  echo "Applying Termux symlinks (this can take a while)..." >&2
  termux_sandbox_run_helper "apply-symlinks.sh" "$rootfs"
}

termux_sandbox_bootstrap_if_needed() {
  mode="$1"
  sandbox_name="$2"
  rootfs="$3"
  host_prefix="$4"
  bootstrap_url="$5"
  bootstrap_file="$6"

  if [ -x "$rootfs/bin/bash" ]; then
    return
  fi

  case "$mode" in
    none)
      echo "Error: rootfs is missing $host_prefix/bin/bash." >&2
      echo "Hint: run with --bootstrap or provide a bootstrap source." >&2
      exit 1
      ;;
    termux)
      echo "Bootstrapping sandbox '$sandbox_name' from Termux app bootstrap..." >&2
      echo "Rootfs: $rootfs" >&2
      termux_sandbox_extract_bootstrap_from_termux "$rootfs"
      ;;
    prefix)
      termux_sandbox_bootstrap_from_prefix "$sandbox_name" "$rootfs" "$host_prefix"
      ;;
    mirror)
      echo "Bootstrapping sandbox '$sandbox_name' from Termux mirror..." >&2
      echo "Rootfs: $rootfs" >&2
      termux_sandbox_bootstrap_from_mirror "$rootfs" "$host_prefix"
      ;;
    url)
      if [ -z "$bootstrap_url" ]; then
        echo "Error: --bootstrap-url must be provided when using bootstrap url." >&2
        exit 1
      fi
      echo "Bootstrapping sandbox '$sandbox_name' from URL..." >&2
      echo "Rootfs: $rootfs" >&2
      termux_sandbox_bootstrap_from_url "$rootfs" "$bootstrap_url"
      ;;
    file)
      if [ -z "$bootstrap_file" ]; then
        echo "Error: --bootstrap-file must be provided when using bootstrap file." >&2
        exit 1
      fi
      echo "Bootstrapping sandbox '$sandbox_name' from file..." >&2
      echo "Rootfs: $rootfs" >&2
      termux_sandbox_bootstrap_from_file "$rootfs" "$bootstrap_file"
      ;;
    *)
      echo "Error: unknown bootstrap mode: $mode" >&2
      return 2
      ;;
  esac

  termux_sandbox_apply_symlinks "$rootfs"
}

termux_sandbox_ensure_sticky_tmp() {
  dir="$1"
  mkdir -p "$dir"
  if ! chmod 1777 "$dir" 2>/dev/null; then
    rm -rf "$dir"
    mkdir -p "$dir"
    chmod 1777 "$dir"
  fi
}

termux_sandbox_prepare_rootfs() {
  rootfs="$1"
  mkdir -p "$rootfs/home/agent" "$rootfs/home/agent/work" "$rootfs/etc/dpkg/dpkg.cfg.d"
  termux_sandbox_ensure_sticky_tmp "$rootfs/tmp"
  termux_sandbox_ensure_sticky_tmp "$rootfs/var/tmp"

  if [ -f "$rootfs/SYMLINKS.txt" ] && [ ! -e "$rootfs/bin/chmod" ]; then
    termux_sandbox_apply_symlinks "$rootfs"
  fi
}

termux_sandbox_write_prompt_rc() {
  rootfs="$1"
  rc_path="$rootfs/etc/termux-sandbox-rc"
  mkdir -p "$(dirname "$rc_path")"
  cat > "$rc_path" <<'EOF'
# Generated by termux-sandbox. Sources standard bash config then adds a prompt marker.
if [ -f /data/data/com.termux/files/usr/etc/bash.bashrc ]; then
  . /data/data/com.termux/files/usr/etc/bash.bashrc
fi
if [ -f "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi
if [ -n "${TERMUX_SANDBOX_PATH_PREPEND:-}" ]; then
  case ":$PATH:" in
    *":$TERMUX_SANDBOX_PATH_PREPEND:"*) ;;
    *) PATH="$TERMUX_SANDBOX_PATH_PREPEND:$PATH" ;;
  esac
fi
if [ -n "${PS1:-}" ]; then
  TERMUX_SANDBOX_NAME="${TERMUX_SANDBOX_NAME:-sandbox}"
  TERMUX_SANDBOX_PROMPT_TEXT="[${TERMUX_SANDBOX_NAME}] "
  TERMUX_SANDBOX_COLORS=(96 92 93 95 94 91 97)
  TERMUX_SANDBOX_COLOR_INDEX=0
  if command -v od >/dev/null 2>&1; then
    for value in $(printf '%s' "$TERMUX_SANDBOX_NAME" | od -An -tu1); do
      TERMUX_SANDBOX_COLOR_INDEX=$((TERMUX_SANDBOX_COLOR_INDEX + value))
    done
  fi
  TERMUX_SANDBOX_COLOR=${TERMUX_SANDBOX_COLORS[$((TERMUX_SANDBOX_COLOR_INDEX % ${#TERMUX_SANDBOX_COLORS[@]}))]}
  TERMUX_SANDBOX_PROMPT_PREFIX="\[\e[1;${TERMUX_SANDBOX_COLOR}m\]${TERMUX_SANDBOX_PROMPT_TEXT}\[\e[0m\]"
  case "$PS1" in
    *"$TERMUX_SANDBOX_PROMPT_TEXT"*) ;;
    *) PS1="${TERMUX_SANDBOX_PROMPT_PREFIX}${PS1}" ;;
  esac
fi
EOF
}

termux_sandbox_setup_relay() {
  rootfs="$1"
  host_prefix="$2"

  RELAY_DIR="$rootfs/tmp/sandbox-relay"
  RELAY_PID=""
  SANDBOX_BIN=""
  SANDBOX_PATH_PREPEND=""

  relay_helper=$(termux_sandbox_find_helper "sandbox-relay.sh" || true)
  relay_client=$(termux_sandbox_find_helper "sandbox-relay-client.sh" || true)

  if [ -n "$relay_helper" ] && [ -n "$relay_client" ]; then
    rm -rf "$RELAY_DIR"
    "$relay_helper" "$RELAY_DIR" &
    RELAY_PID=$!

    SANDBOX_BIN="$rootfs/tmp/sandbox-bin"
    mkdir -p "$SANDBOX_BIN"
    cp "$relay_client" "$SANDBOX_BIN/am"
    chmod 755 "$SANDBOX_BIN/am"

    SANDBOX_PATH_PREPEND="$host_prefix/tmp/sandbox-bin"
  fi
}

termux_sandbox_cleanup_relay() {
  [ -n "${RELAY_PID:-}" ] && kill "$RELAY_PID" 2>/dev/null || true
  [ -n "${RELAY_DIR:-}" ] && rm -rf "$RELAY_DIR"
  [ -n "${SANDBOX_BIN:-}" ] && rm -rf "$SANDBOX_BIN"
}
