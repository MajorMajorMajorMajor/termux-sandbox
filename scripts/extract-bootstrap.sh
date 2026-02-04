#!/data/data/com.termux/files/usr/bin/sh
set -eu

ROOTFS=${1:-"$HOME/sandboxes/bootstrap-test"}
mkdir -p "$ROOTFS"

HOST_PREFIX="/data/data/com.termux/files/usr"

map_apk_arch() {
  case "$(uname -m)" in
    aarch64|arm64) echo "arm64-v8a" ;;
    armv7l|armv8l|arm) echo "armeabi-v7a" ;;
    i686|i386) echo "x86" ;;
    x86_64) echo "x86_64" ;;
    *)
      echo "" ;;
  esac
}

get_termux_apk_path() {
  if [ -n "${TERMUX_APP__APK_FILE_PATH:-}" ] && [ -f "$TERMUX_APP__APK_FILE_PATH" ]; then
    echo "$TERMUX_APP__APK_FILE_PATH"
    return 0
  fi

  for pm_cmd in pm /system/bin/pm; do
    if [ "$pm_cmd" = "pm" ]; then
      command -v pm >/dev/null 2>&1 || continue
    else
      [ -x /system/bin/pm ] || continue
    fi
    apk_path=$($pm_cmd path com.termux 2>/dev/null | head -n1 | sed 's/package://')
    if [ -n "$apk_path" ] && [ -f "$apk_path" ]; then
      echo "$apk_path"
      return 0
    fi
  done

  apk_path=$(find /data/app -maxdepth 4 -type f -name base.apk -path '*com.termux*' 2>/dev/null | head -n1)
  if [ -n "$apk_path" ] && [ -f "$apk_path" ]; then
    echo "$apk_path"
    return 0
  fi

  return 1
}

apk_path=$(get_termux_apk_path)
if [ -z "$apk_path" ]; then
  echo "Error: could not locate Termux APK path." >&2
  exit 1
fi

if ! command -v unzip >/dev/null 2>&1; then
  echo "Error: unzip is required. Install with: pkg install unzip" >&2
  exit 1
fi

tmp_dir=$(mktemp -d)
lib_path=""
apk_dir=$(dirname "$apk_path")
if [ -d "$apk_dir/lib" ]; then
  for libdir in "$apk_dir"/lib/*; do
    if [ -f "$libdir/libtermux-bootstrap.so" ]; then
      lib_path="$libdir/libtermux-bootstrap.so"
      break
    fi
  done
fi

if [ -n "$lib_path" ]; then
  cp "$lib_path" "$tmp_dir/libtermux-bootstrap.zip"
else
  apk_arch=$(map_apk_arch)
  if [ -z "$apk_arch" ]; then
    echo "Error: unsupported architecture for APK extraction: $(uname -m)" >&2
    rm -rf "$tmp_dir"
    exit 1
  fi
  unzip -p "$apk_path" "lib/$apk_arch/libtermux-bootstrap.so" > "$tmp_dir/libtermux-bootstrap.zip"
fi

if [ ! -s "$tmp_dir/libtermux-bootstrap.zip" ]; then
  echo "Error: could not locate Termux bootstrap library." >&2
  rm -rf "$tmp_dir"
  exit 1
fi

echo "Extracting bootstrap to $ROOTFS" >&2
if unzip -l "$tmp_dir/libtermux-bootstrap.zip" 2>/dev/null | awk '{print $4}' | grep -qx ".rodata"; then
  unzip -p "$tmp_dir/libtermux-bootstrap.zip" .rodata > "$tmp_dir/bootstrap.zip"
  if [ ! -s "$tmp_dir/bootstrap.zip" ]; then
    echo "Error: failed to extract bootstrap archive from Termux app." >&2
    rm -rf "$tmp_dir"
    exit 1
  fi
  unzip -q "$tmp_dir/bootstrap.zip" -d "$ROOTFS"
else
  unzip -q "$tmp_dir/libtermux-bootstrap.zip" -d "$ROOTFS"
fi
rm -rf "$tmp_dir"

echo "Extraction complete." >&2

if [ -f "$ROOTFS/SYMLINKS.txt" ]; then
  echo "Note: SYMLINKS.txt exists; apply symlinks before using." >&2
fi
