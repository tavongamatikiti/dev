#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_HOME="$(mktemp -d)"
TEST_BIN="$TEST_HOME/bin"
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
mkdir -p "$TEST_BIN" "$TEST_HOME/.config/nvim" "$TEST_HOME/.config/unrelated"
printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/launchctl"
chmod +x "$TEST_BIN/launchctl"
cat > "$TEST_BIN/defaults" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$TEST_DEFAULTS_LOG"
exit 0
EOF
chmod +x "$TEST_BIN/defaults"
cat > "$TEST_BIN/killall" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$TEST_KILLALL_LOG"
exit 0
EOF
chmod +x "$TEST_BIN/killall"
printf 'keep me\n' > "$TEST_HOME/.config/unrelated/settings.conf"
printf 'old config\n' > "$TEST_HOME/.config/nvim/init.lua"

PATH="$TEST_BIN:$PATH" HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" \
  TEST_DEFAULTS_LOG="$TEST_HOME/defaults.log" TEST_KILLALL_LOG="$TEST_HOME/killall.log" \
  "$PROJECT_DIR/scripts/install-configs.sh"

assert_file "$TEST_HOME/.config/nvim/init.lua"
assert_file "$TEST_HOME/.config/tmux/tmux.conf"
assert_file "$TEST_HOME/.local/bin/tmux-sessionizer"
assert_file "$TEST_HOME/.local/bin/tmux-persist"
assert_file "$TEST_HOME/.local/bin/organize-screenshots"
assert_file "$TEST_HOME/.config/aerospace/aerospace.toml"
assert_file "$TEST_HOME/.config/ghostty/config"
assert_file "$TEST_HOME/.config/karabiner/karabiner.json"
assert_contains "$TEST_HOME/.config/ghostty/config" 'font-family = JetBrainsMono Nerd Font'
assert_file "$TEST_HOME/Library/LaunchAgents/com.user.screenshots.organize.plist"
assert_contains "$TEST_HOME/Library/LaunchAgents/com.user.screenshots.organize.plist" "    <string>$TEST_HOME/.local/bin/organize-screenshots</string>"
grep -Fq '|| true' "$TEST_HOME/.local/bin/organize-screenshots" >/dev/null || fail 'organizer must tolerate unreadable directories (macOS TCC)'
grep -Fq 'SRC="$HOME/Desktop"' "$TEST_HOME/.local/bin/organize-screenshots" >/dev/null || fail 'organizer should still sweep stray Desktop screenshots best-effort'
grep -Fqx "write com.apple.screencapture location $TEST_HOME/Pictures/Screenshots" "$TEST_HOME/defaults.log" >/dev/null || fail 'installer must point macOS screenshots at the organizer inbox'
grep -Fqx 'SystemUIServer' "$TEST_HOME/killall.log" >/dev/null || fail 'installer must reload the UI server after moving the screenshot location'
assert_file "$TEST_HOME/.config/unrelated/settings.conf"
assert_contains "$TEST_HOME/.config/unrelated/settings.conf" 'keep me'

printf 'PASS: installs managed configs without removing unrelated config\n'
