#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
args=()
for argument in "$@"; do
  case "$argument" in
    --dry) args+=(--dry-run) ;;
    *) args+=("$argument") ;;
  esac
done

exec "$SCRIPT_DIR/scripts/install-configs.sh" "${args[@]}"
