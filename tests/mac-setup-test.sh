#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_HOME="$(mktemp -d)"
trap 'rm -rf "$TEST_HOME"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_file() {
  [[ -f "$1" ]] || fail "expected file $1"
}

assert_contains() {
  grep -Fqx "$2" "$1" >/dev/null || fail "expected $1 to contain $2"
}

# A config deployment must leave unrelated user configuration untouched,
# while installing the repository-managed config files in the XDG location.
mkdir -p "$TEST_HOME/.config/nvim" "$TEST_HOME/.config/unrelated"
printf 'keep me\n' > "$TEST_HOME/.config/unrelated/settings.conf"
printf 'old config\n' > "$TEST_HOME/.config/nvim/init.lua"

HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" \
  "$PROJECT_DIR/scripts/install-configs.sh"

assert_file "$TEST_HOME/.config/nvim/init.lua"
assert_file "$TEST_HOME/.config/tmux/tmux.conf"
assert_file "$TEST_HOME/.local/bin/tmux-sessionizer"
assert_file "$TEST_HOME/.local/bin/tmux-persist"
assert_file "$TEST_HOME/.local/bin/organize-screenshots"
assert_file "$TEST_HOME/.config/aerospace/aerospace.toml"
assert_file "$TEST_HOME/.config/ghostty/config"
assert_file "$TEST_HOME/.config/karabiner/karabiner.json"
assert_file "$TEST_HOME/.config/unrelated/settings.conf"
assert_contains "$TEST_HOME/.config/unrelated/settings.conf" 'keep me'

printf 'PASS: installs managed configs without removing unrelated config\n'
