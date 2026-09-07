#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UBUNTU_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="$UBUNTU_DIR/env/shell/shell.zsh"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TARGET_DIR="$XDG_CONFIG_HOME/dev-setup"
TARGET_FILE="$TARGET_DIR/shell.zsh"
ZSHRC="$HOME/.zshrc"
START_MARKER='# >>> dev-setup managed shell >>>'
END_MARKER='# <<< dev-setup managed shell <<<'
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) printf '%s\n' 'Usage: ubuntu/scripts/install-shell-config.sh [--dry-run]'; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
  shift
done

[[ -f "$TEMPLATE" ]] || { printf 'Missing shell template: %s\n' "$TEMPLATE" >&2; exit 1; }
if [[ "$DRY_RUN" == "1" ]]; then
  printf '[dry-run] install managed Ubuntu Zsh environment at %s\n' "$TARGET_FILE"
  printf '[dry-run] add one managed source block to %s\n' "$ZSHRC"
  exit 0
fi

mkdir -p "$TARGET_DIR"
install -m 644 "$TEMPLATE" "$TARGET_FILE"
touch "$ZSHRC"
if ! grep -Fqx "$START_MARKER" "$ZSHRC" >/dev/null; then
  {
    printf '\n%s\n' "$START_MARKER"
    printf '[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/dev-setup/shell.zsh" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/dev-setup/shell.zsh"\n'
    printf '%s\n' "$END_MARKER"
  } >> "$ZSHRC"
fi
printf 'Managed Ubuntu Zsh environment installed at %s\n' "$TARGET_FILE"

