#!/bin/bash
# organize-screenshots.sh - moves screenshots from base dir into YYYY-MM subfolders
# Base: ~/Pictures/Screenshots -> ~/Pictures/Screenshots/2026-08/
# Uses file creation/modification date for correct month, not just "today"

set -euo pipefail
BASE="$HOME/Pictures/Screenshots"

# safety: ensure base exists
mkdir -p "$BASE"

# find files directly in BASE (not in subfolders) - handle spaces
find "$BASE" -maxdepth 1 -type f \( -iname "Screen Shot *.png" -o -iname "Screenshot *.png" -o -iname "Screen Recording *.mov" \) -print0 | while IFS= read -r -d '' f; do
  # skip if file is still being written (modified within last 2 seconds)
  if [[ $(find "$f" -mmin -0.05 2>/dev/null) ]]; then
    # check age more precisely with stat
    mod_epoch=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0)
    now_epoch=$(date +%s)
    age=$((now_epoch - mod_epoch))
    if (( age < 2 )); then
      continue
    fi
  fi

  # get file's creation date (fallback to modification date)
  # macOS stat: %B = creation time (Darwin), fallback to %m
  file_epoch=$(stat -f %B "$f" 2>/dev/null || stat -f %m "$f" 2>/dev/null || date +%s)
  # if creation time is 0 (not available), use modification time
  if [[ "$file_epoch" == "0" ]]; then
    file_epoch=$(stat -f %m "$f" 2>/dev/null || date +%s)
  fi
  month=$(date -r "$file_epoch" +%Y-%m 2>/dev/null || date -d "@$file_epoch" +%Y-%m 2>/dev/null || date +%Y-%m)
  dest_dir="$BASE/$month"
  mkdir -p "$dest_dir"

  # avoid overwriting: if dest exists, add suffix
  base_name=$(basename "$f")
  dest="$dest_dir/$base_name"
  if [[ -e "$dest" ]]; then
    # append timestamp
    name_no_ext="${base_name%.*}"
    ext="${base_name##*.}"
    dest="$dest_dir/${name_no_ext}_$(date +%H%M%S).$ext"
  fi

  mv -n "$f" "$dest" 2>/dev/null || mv "$f" "$dest"
  echo "$(date '+%Y-%m-%d %H:%M:%S') moved: $base_name -> $month/" >> "$BASE/.organize.log"
done
