#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_HOME="$(mktemp -d)"
trap 'rm -rf "$TEST_HOME"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

mkdir -p "$TEST_HOME/state"
printf 'export TEST_PROFILE=one\n' > "$TEST_HOME/.zprofile"
printf 'export TEST_RC=two\n' > "$TEST_HOME/.zshrc"
mkdir -p "$TEST_HOME/.tmux/resurrect"
printf 'restorable tmux state\n' > "$TEST_HOME/.tmux/resurrect/last"
mkdir -p "$TEST_HOME/.tmux-sessions" "$TEST_HOME/.local/bin"
printf 'tmux-persist session\n' > "$TEST_HOME/.tmux-sessions/dawa.session"
printf '#!/usr/bin/env bash\necho tmux-persist\n' > "$TEST_HOME/.local/bin/tmux-persist"
mkdir -p "$TEST_HOME/.config/tmux"
printf 'set -g status on\n' > "$TEST_HOME/.config/tmux/tmux.conf"

HOME="$TEST_HOME" XDG_STATE_HOME="$TEST_HOME/state" \
  "$PROJECT_DIR/scripts/backup-shell-configs.sh"

backup_dir=$(find "$TEST_HOME/state/dev-setup/backups/shell" -mindepth 1 -maxdepth 1 -type d)
[[ -n "$backup_dir" ]] || fail 'expected a timestamped shell backup directory'
cmp -s "$TEST_HOME/.zprofile" "$backup_dir/.zprofile" || fail '.zprofile backup differs from the source file'
cmp -s "$TEST_HOME/.zshrc" "$backup_dir/.zshrc" || fail '.zshrc backup differs from the source file'
cmp -s "$TEST_HOME/.tmux/resurrect/last" "$backup_dir/.tmux/resurrect/last" || fail 'tmux persistence state was not backed up'
[[ ! -e "$backup_dir/.tmux-sessions" ]] || fail 'tmux-persist session data must not be backed up'
cmp -s "$TEST_HOME/.local/bin/tmux-persist" "$backup_dir/.local/bin/tmux-persist" || fail 'tmux-persist program was not backed up'
cmp -s "$TEST_HOME/.config/tmux/tmux.conf" "$backup_dir/.config/tmux/tmux.conf" || fail 'tmux configuration was not backed up'
[[ -f "$backup_dir/MANIFEST.txt" ]] || fail 'expected a backup manifest'

printf 'PASS: backs up shell configuration files before they are changed\n'
