#!/usr/bin/env bash

set -euo pipefail

REPOSITORY="${DEV_SETUP_REPOSITORY:-https://github.com/tavongamatikiti/dev}"
REF=""
TARGET_DIR="${DEV_SETUP_DIR:-$HOME/Developer/dev}"
SETUP_ARGS=()

usage() {
  cat <<'EOF'
Usage: install-mac.sh [--ref TAG] [--target DIRECTORY] [--] [setup options]

For curl installation, --ref is required and must be a release tag.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref) REF="${2:-}"; [[ -n "$REF" ]] || { printf '%s\n' '--ref requires a tag' >&2; exit 1; }; shift ;;
    --target) TARGET_DIR="${2:-}"; [[ -n "$TARGET_DIR" ]] || { printf '%s\n' '--target requires a directory' >&2; exit 1; }; shift ;;
    --) shift; SETUP_ARGS=("$@"); break ;;
    -h|--help) usage; exit 0 ;;
    *) SETUP_ARGS+=("$1") ;;
  esac
  shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/setup.sh" ]]; then
  exec "$SCRIPT_DIR/setup.sh" "${SETUP_ARGS[@]}"
fi

[[ -n "$REF" ]] || { printf 'Use --ref with a release tag when running this through curl.\n' >&2; exit 1; }
[[ ! -e "$TARGET_DIR" ]] || { printf 'Refusing to overwrite existing setup directory: %s\n' "$TARGET_DIR" >&2; exit 1; }

temporary_dir="$(mktemp -d)"
trap 'rm -rf "$temporary_dir"' EXIT
archive="$temporary_dir/dev.tar.gz"
curl -fsSL "$REPOSITORY/archive/refs/tags/$REF.tar.gz" -o "$archive"
tar -xzf "$archive" -C "$temporary_dir"
source_dir="$(find "$temporary_dir" -mindepth 1 -maxdepth 1 -type d -name 'dev-*' -print -quit)"
[[ -n "$source_dir" ]] || { printf 'Downloaded archive did not contain the expected project directory.\n' >&2; exit 1; }
mkdir -p "$(dirname "$TARGET_DIR")"
mv "$source_dir" "$TARGET_DIR"
exec "$TARGET_DIR/setup.sh" "${SETUP_ARGS[@]}"

