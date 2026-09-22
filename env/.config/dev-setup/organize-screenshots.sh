#!/bin/bash
# Sort screenshots into ~/Pictures/Screenshots/YYYY-MM; Desktop is best-effort (macOS TCC blocks launchd).

set -euo pipefail
SRC="$HOME/Desktop"
BASE="$HOME/Pictures/Screenshots"

mkdir -p "$BASE"

# YYYY-MM of a file by creation date, falling back to modification date.
file_month() { # $1 = file
  local epoch
  epoch=$(stat -f %B "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || date +%s)
  [[ "$epoch" == "0" ]] && epoch=$(stat -f %m "$1" 2>/dev/null || date +%s)
  date -r "$epoch" +%Y-%m 2>/dev/null || date +%Y-%m
}

organize_file() { # $1 = file
  local month dest_dir base dest
  month=$(file_month "$1")
  dest_dir="$BASE/$month"
  mkdir -p "$dest_dir"
  base=$(basename "$1")
  dest="$dest_dir/$base"
  [[ -e "$dest" ]] && dest="$dest_dir/${base%.*}_$(date +%H%M%S).${base##*.}"
  mv -n "$1" "$dest"
  echo "$(date '+%Y-%m-%d %H:%M:%S') moved: $base -> $month/" >> "$BASE/.organize.log"
}

scan_dir() { # $1 = dir; unreadable dirs are skipped so launchd never fails on ~/Desktop
  [[ -d "$1" && -r "$1" && -x "$1" ]] || return 0
  find "$1" -maxdepth 1 -type f \( -iname "Screen Shot *.png" -o -iname "Screenshot *.png" -o -iname "Screen Recording *.mov" \) -print0 2>/dev/null | while IFS= read -r -d '' f; do
    organize_file "$f"
  done || true
}

scan_dir "$BASE"
scan_dir "$SRC"
