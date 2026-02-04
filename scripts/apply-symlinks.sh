#!/data/data/com.termux/files/usr/bin/sh
set -eu

ROOTFS=${1:-}
if [ -z "$ROOTFS" ]; then
  echo "Usage: apply-symlinks.sh <rootfs>" >&2
  exit 1
fi

symlink_file="$ROOTFS/SYMLINKS.txt"
[ -f "$symlink_file" ] || exit 0

while IFS= read -r line; do
  [ -n "$line" ] || continue
  case "$line" in
    *"←"*)
      target="${line%%←*}"
      link="${line#*←}"
      ;;
    *)
      continue
      ;;
  esac
  target="${target#./}"
  link="${link#./}"
  [ -n "$link" ] || continue
  mkdir -p "$ROOTFS/$(dirname "$link")"
  ln -sfn "$target" "$ROOTFS/$link"
 done < "$symlink_file"
