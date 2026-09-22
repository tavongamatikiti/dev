#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_CONFIG_DIR="$PROJECT_DIR/env/.config"
SOURCE_LAUNCH_AGENT="$PROJECT_DIR/env/LaunchAgents/com.user.screenshots.organize.plist"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: scripts/install-configs.sh [--dry-run]

Installs repository-managed Mac application and terminal configuration files.
Existing unrelated files are never removed.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

install_directory() {
  local source_dir="$1"
  local target_dir="$2"

  run mkdir -p "$target_dir"
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] copy %s to %s without deleting existing files\n' "$source_dir/" "$target_dir/"
  else
    cp -R "$source_dir/." "$target_dir/"
  fi
}

[[ -d "$SOURCE_CONFIG_DIR" ]] || {
  printf 'Missing config source directory: %s\n' "$SOURCE_CONFIG_DIR" >&2
  exit 1
}

install_directory "$SOURCE_CONFIG_DIR/nvim" "$XDG_CONFIG_HOME/nvim"
install_directory "$SOURCE_CONFIG_DIR/tmux" "$XDG_CONFIG_HOME/tmux"
install_directory "$SOURCE_CONFIG_DIR/tmux-sessionizer" "$XDG_CONFIG_HOME/tmux-sessionizer"
install_directory "$SOURCE_CONFIG_DIR/aerospace" "$XDG_CONFIG_HOME/aerospace"
install_directory "$SOURCE_CONFIG_DIR/ghostty" "$XDG_CONFIG_HOME/ghostty"
install_directory "$SOURCE_CONFIG_DIR/karabiner" "$XDG_CONFIG_HOME/karabiner"
run mkdir -p "$HOME/.local/bin"
run install -m 755 "$SOURCE_CONFIG_DIR/tmux-sessionizer/tmux-sessionizer.sh" "$HOME/.local/bin/tmux-sessionizer"
run install -m 755 "$SOURCE_CONFIG_DIR/dev-setup/tmux-persist" "$HOME/.local/bin/tmux-persist"
run install -m 755 "$SOURCE_CONFIG_DIR/dev-setup/organize-screenshots.sh" "$HOME/.local/bin/organize-screenshots"

configure_screenshot_location() {
  # macOS saves to ~/Desktop by default, which the agent can neither see nor read under TCC.
  local screenshot_dir="$HOME/Pictures/Screenshots"

  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] set macOS screenshot save location to %s\n' "$screenshot_dir"
    printf '[dry-run] reload the macOS UI server after changing the screenshot location\n'
    return
  fi

  run mkdir -p "$screenshot_dir"
  run defaults write com.apple.screencapture location "$screenshot_dir"
  run killall SystemUIServer 2>/dev/null || true # apply now; harmless when the server is absent
}

install_screenshot_launch_agent() {
  local target_dir="$HOME/Library/LaunchAgents"
  local target_file="$target_dir/com.user.screenshots.organize.plist"
  [[ -f "$SOURCE_LAUNCH_AGENT" ]] || {
    printf 'Missing screenshot LaunchAgent template: %s\n' "$SOURCE_LAUNCH_AGENT" >&2
    exit 1
  }

  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] install screenshot organizer LaunchAgent at %s\n' "$target_file"
    printf '[dry-run] load screenshot organizer LaunchAgent for the current user\n'
    return
  fi

  mkdir -p "$target_dir"
  sed "s|__HOME__|$HOME|g" "$SOURCE_LAUNCH_AGENT" > "$target_file"
  launchctl bootout "gui/$(id -u)" "$target_file" >/dev/null 2>&1 || true
  launchctl bootstrap "gui/$(id -u)" "$target_file"
}

install_screenshot_launch_agent
configure_screenshot_location

printf 'Configuration installation complete.\n'
