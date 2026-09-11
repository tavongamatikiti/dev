#!/usr/bin/env bash

set -euo pipefail

STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
BACKUP_ROOT="$STATE_HOME/dev-setup/backups/shell"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: scripts/backup-shell-configs.sh [--dry-run]

Copies existing Zsh configuration files to a private, timestamped backup
directory under ~/.local/state/dev-setup/backups/shell.
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

shell_files=(.zshenv .zprofile .zshrc .zlogin)
tmux_paths=(
  .tmux/resurrect
  .tmux/plugins/tmux-resurrect
  .tmux/plugins/tmux-continuum
  .config/tmux/resurrect
  .config/tmux/continuum
  .local/share/tmux
  .local/state/tmux
)
tmux_files=(.tmux.conf .config/tmux/tmux.conf .config/tmux/tmux.conf.local .local/bin/tmux-persist)

if [[ "$DRY_RUN" == "1" ]]; then
  printf '[dry-run] create a private timestamped directory below %s\n' "$BACKUP_ROOT"
  for file in "${shell_files[@]}"; do
    [[ -f "$HOME/$file" ]] && printf '[dry-run] copy %s\n' "$HOME/$file"
  done
  for path in "${tmux_paths[@]}"; do
    [[ -e "$HOME/$path" ]] && printf '[dry-run] copy %s\n' "$HOME/$path"
  done
  for file in "${tmux_files[@]}"; do
    [[ -f "$HOME/$file" ]] && printf '[dry-run] copy %s\n' "$HOME/$file"
  done
  exit 0
fi

umask 077
mkdir -p "$BACKUP_ROOT"
timestamp="$(date '+%Y%m%d-%H%M%S')"
backup_dir="$(mktemp -d "$BACKUP_ROOT/$timestamp-XXXXXX")"
manifest="$backup_dir/MANIFEST.txt"

printf 'Created: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" > "$manifest"
for file in "${shell_files[@]}"; do
  if [[ -f "$HOME/$file" ]]; then
    cp -p "$HOME/$file" "$backup_dir/$file"
    printf '%s\n' "$file" >> "$manifest"
  fi
done

for path in "${tmux_paths[@]}"; do
  if [[ -e "$HOME/$path" ]]; then
    mkdir -p "$backup_dir/$(dirname "$path")"
    cp -pR "$HOME/$path" "$backup_dir/$path"
    printf '%s\n' "$path" >> "$manifest"
  fi
done

for file in "${tmux_files[@]}"; do
  if [[ -f "$HOME/$file" ]]; then
    mkdir -p "$backup_dir/$(dirname "$file")"
    cp -p "$HOME/$file" "$backup_dir/$file"
    printf '%s\n' "$file" >> "$manifest"
  fi
done

printf 'Shell configuration backed up to %s\n' "$backup_dir"
