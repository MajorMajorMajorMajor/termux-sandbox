#!/data/data/com.termux/files/usr/bin/sh
set -eu

echo "== pm path =="
if command -v pm >/dev/null 2>&1; then
  pm path com.termux || true
else
  echo "pm not found in PATH"
fi

echo "== /system/bin/pm path =="
if [ -x /system/bin/pm ]; then
  /system/bin/pm path com.termux || true
else
  echo "/system/bin/pm not found"
fi

echo "== TERMUX_APP__APK_FILE_PATH =="
if [ -n "${TERMUX_APP__APK_FILE_PATH:-}" ]; then
  echo "$TERMUX_APP__APK_FILE_PATH"
  ls -la "$TERMUX_APP__APK_FILE_PATH" || true
else
  echo "(unset)"
fi

echo "== find /data/app base.apk =="
find /data/app -maxdepth 4 -type f -name base.apk -path '*com.termux*' 2>/dev/null | head -n 5 || true

apk_path=$(pm path com.termux 2>/dev/null | head -n1 | sed 's/package://')
if [ -n "$apk_path" ] && [ -f "$apk_path" ]; then
  apk_dir=$(dirname "$apk_path")
  echo "== libtermux-bootstrap.so in lib dirs =="
  find "$apk_dir/lib" -name 'libtermux-bootstrap.so' 2>/dev/null | head -n 5 || true
  echo "== base.apk listing for libtermux-bootstrap.so =="
  if command -v unzip >/dev/null 2>&1; then
    unzip -l "$apk_path" 'lib/*/libtermux-bootstrap.so' | head -n 10 || true
  else
    echo "unzip not found"
  fi
fi
