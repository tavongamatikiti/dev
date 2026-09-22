#!/usr/bin/env bash

set -euo pipefail

DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: scripts/install-zsh-completions.sh [--dry-run]

Generates Zsh completion files for command-line tools installed by this setup.
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

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
COMPLETIONS_DIR="$XDG_CONFIG_HOME/zsh/completions"

generate_completion() {
  local command_name="$1"
  local completion_name="$2"
  shift 2

  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Skipping %s completion because %s is unavailable.\n' "$completion_name" "$command_name"
    return
  fi

  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] generate %s at %s\n' "$completion_name" "$COMPLETIONS_DIR/$completion_name"
    return
  fi

  local temporary_file
  temporary_file="$(mktemp "$COMPLETIONS_DIR/.${completion_name}.XXXXXX")"
  if "$@" > "$temporary_file"; then
    install -m 644 "$temporary_file" "$COMPLETIONS_DIR/$completion_name"
    rm -f "$temporary_file"
    printf 'Generated Zsh completion: %s\n' "$completion_name"
  else
    rm -f "$temporary_file"
    printf 'Unable to generate Zsh completion for %s.\n' "$command_name" >&2
    return 1
  fi
}

if [[ "$DRY_RUN" != "1" ]]; then
  mkdir -p "$COMPLETIONS_DIR"
fi

generate_completion gh _gh gh completion -s zsh
generate_completion gitleaks _gitleaks gitleaks completion zsh
generate_completion rg _rg rg --generate complete-zsh
