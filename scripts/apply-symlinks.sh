#!/data/data/com.termux/files/usr/bin/sh
set -eu

ROOTFS=${1:-}
if [ -z "$ROOTFS" ]; then
  echo "Usage: apply-symlinks.sh <rootfs>" >&2
  exit 1
fi

symlink_file="$ROOTFS/SYMLINKS.txt"
[ -f "$symlink_file" ] || exit 0

pairs_file=$(mktemp)
dirs_file=$(mktemp)

cleanup() {
  rm -f "$pairs_file" "$dirs_file"
}
trap cleanup EXIT

awk -F'←' -v pairs="$pairs_file" -v dirs="$dirs_file" '
NF==2 {
  target=$1
  link=$2
  sub(/^\.\//, "", target)
  sub(/^\.\//, "", link)
  if (link == "") next
  print target "\t" link >> pairs
  if (index(link, "/") > 0) {
    dir=link
    sub(/\/[^\/]*$/, "", dir)
    if (dir != "" && dir != ".") print dir >> dirs
  }
}
' "$symlink_file"

if [ -s "$dirs_file" ]; then
  sort -u "$dirs_file" | while IFS= read -r dir; do
    [ -n "$dir" ] || continue
    mkdir -p "$ROOTFS/$dir"
  done
fi

if [ -s "$pairs_file" ]; then
  tab=$(printf '\t')
  while IFS="$tab" read -r target link; do
    [ -n "$link" ] || continue
    ln -sfn "$target" "$ROOTFS/$link"
  done < "$pairs_file"
fi
