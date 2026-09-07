#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UBUNTU_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$(cd "$UBUNTU_DIR/.." && pwd)"
SHARED_CONFIG_DIR="$PROJECT_DIR/env/.config"
UBUNTU_CONFIG_DIR="$UBUNTU_DIR/env/.config"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) printf '%s\n' 'Usage: ubuntu/scripts/install-configs.sh [--dry-run]'; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
  shift
done

install_directory() {
  local source_dir="$1" target_dir="$2"
  [[ -d "$source_dir" ]] || { printf 'Missing config source directory: %s\n' "$source_dir" >&2; exit 1; }
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] copy %s to %s without deleting existing files\n' "$source_dir/" "$target_dir/"
  else
    mkdir -p "$target_dir"
    cp -R "$source_dir/." "$target_dir/"
  fi
}

install_directory "$SHARED_CONFIG_DIR/nvim" "$XDG_CONFIG_HOME/nvim"
install_directory "$SHARED_CONFIG_DIR/tmux-sessionizer" "$XDG_CONFIG_HOME/tmux-sessionizer"
install_directory "$UBUNTU_CONFIG_DIR/tmux" "$XDG_CONFIG_HOME/tmux"
if [[ "$DRY_RUN" == "1" ]]; then
  printf '[dry-run] install tmux-sessionizer at %s\n' "$HOME/.local/bin/tmux-sessionizer"
else
  mkdir -p "$HOME/.local/bin"
  install -m 755 "$SHARED_CONFIG_DIR/tmux-sessionizer/tmux-sessionizer.sh" "$HOME/.local/bin/tmux-sessionizer"
fi
printf 'Ubuntu configuration installation complete.\n'

