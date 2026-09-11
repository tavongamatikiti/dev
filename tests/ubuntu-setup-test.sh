#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_HOME="$(mktemp -d)"
TEST_BIN="$TEST_HOME/bin"
SUPPORTED_RELEASE="$TEST_HOME/os-release-supported"
UNSUPPORTED_RELEASE="$TEST_HOME/os-release-unsupported"
SUBUID_FILE="$TEST_HOME/subuid"
SUBGID_FILE="$TEST_HOME/subgid"
trap 'rm -rf "$TEST_HOME"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

mkdir -p "$TEST_BIN" "$TEST_HOME/.config/nvim" "$TEST_HOME/.config/unrelated"
printf '#!/usr/bin/env bash\nif [[ "$1" == "-s" ]]; then printf "Linux\\n"; else printf "x86_64\\n"; fi\n' > "$TEST_BIN/uname"
chmod +x "$TEST_BIN/uname"
printf '#!/usr/bin/env bash\nif [[ "$1" == "-un" ]]; then printf "dev\\n"; else /usr/bin/id "$@"; fi\n' > "$TEST_BIN/id"
chmod +x "$TEST_BIN/id"
printf 'ID=ubuntu\nVERSION_ID=24.04\nVERSION_CODENAME=noble\n' > "$SUPPORTED_RELEASE"
printf 'ID=ubuntu\nVERSION_ID=20.04\nVERSION_CODENAME=focal\n' > "$UNSUPPORTED_RELEASE"
: > "$SUBUID_FILE"
: > "$SUBGID_FILE"

podman_dry_run=$(PATH="$TEST_BIN:$PATH" HOME="$TEST_HOME" \
  DEV_SETUP_OS_RELEASE_FILE="$SUPPORTED_RELEASE" DEV_SETUP_SUBUID_FILE="$SUBUID_FILE" DEV_SETUP_SUBGID_FILE="$SUBGID_FILE" \
  "$PROJECT_DIR/ubuntu/setup.sh" --dry-run --only podman)
[[ "$podman_dry_run" == *'install Podman rootless dependencies from Ubuntu packages'* ]] || fail 'Podman component should plan rootless dependencies'
[[ "$podman_dry_run" == *'usermod --add-subuids'* ]] || fail 'Podman component should plan a missing subordinate UID range'
[[ "$podman_dry_run" == *'loginctl enable-linger'* ]] || fail 'Podman component should plan lingering'
[[ "$podman_dry_run" != *'ufw '* ]] || fail 'Podman component must not configure a firewall'

if PATH="$TEST_BIN:$PATH" HOME="$TEST_HOME" DEV_SETUP_OS_RELEASE_FILE="$UNSUPPORTED_RELEASE" \
  DEV_SETUP_SUBUID_FILE="$SUBUID_FILE" DEV_SETUP_SUBGID_FILE="$SUBGID_FILE" \
  "$PROJECT_DIR/ubuntu/setup.sh" --dry-run --only verify >/dev/null 2>&1; then
  fail 'unsupported Ubuntu release should be rejected'
fi

printf 'keep me\n' > "$TEST_HOME/.config/unrelated/settings.conf"
HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" "$PROJECT_DIR/ubuntu/scripts/install-configs.sh"
[[ -f "$TEST_HOME/.config/tmux/tmux.conf" ]] || fail 'Ubuntu tmux configuration was not installed'
[[ -f "$TEST_HOME/.local/bin/tmux-sessionizer" ]] || fail 'tmux-sessionizer was not installed'
grep -Fqx 'keep me' "$TEST_HOME/.config/unrelated/settings.conf" >/dev/null || fail 'unrelated configuration was changed'
if grep -Fq 'pbcopy' "$TEST_HOME/.config/tmux/tmux.conf"; then
  fail 'Ubuntu tmux configuration must not use macOS clipboard commands'
fi

entrypoint_dry_run=$(PATH="$TEST_BIN:$PATH" HOME="$TEST_HOME" \
  DEV_SETUP_OS_RELEASE_FILE="$SUPPORTED_RELEASE" DEV_SETUP_SUBUID_FILE="$SUBUID_FILE" DEV_SETUP_SUBGID_FILE="$SUBGID_FILE" \
  "$PROJECT_DIR/install-ubuntu.sh" --dry-run --only podman)
[[ "$entrypoint_dry_run" == *'loginctl enable-linger'* ]] || fail 'local Ubuntu entrypoint should delegate to setup'

languages_dry_run=$(PATH="$TEST_BIN:$PATH" HOME="$TEST_HOME" \
  DEV_SETUP_OS_RELEASE_FILE="$SUPPORTED_RELEASE" DEV_SETUP_SUBUID_FILE="$SUBUID_FILE" DEV_SETUP_SUBGID_FILE="$SUBGID_FILE" \
  "$PROJECT_DIR/ubuntu/setup.sh" --dry-run --only languages)
[[ "$languages_dry_run" == *'install pnpm and the tldr-pages client, refresh tldr pages, and install Bun'* ]] || fail 'Ubuntu setup should plan pnpm, tldr, and Bun installation'

mkdir -p "$TEST_HOME/.nvm" "$TEST_HOME/.bun/bin" "$TEST_HOME/.local/opt/go1.26.1/bin" "$TEST_HOME/.local/opt/zig-0.15.2"
cat > "$TEST_HOME/.nvm/nvm.sh" <<'EOF'
if [[ "$-" == *u* ]]; then
  printf 'nvm was sourced with nounset enabled\n' >&2
  return 91
fi
nvm() {
  [[ "$-" != *u* ]] || { printf 'nvm was called with nounset enabled\n' >&2; return 92; }
}
EOF
for command in npm tldr; do
  printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/$command"
  chmod +x "$TEST_BIN/$command"
done
for command in go zig bun; do
  printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_HOME/.local/opt/go1.26.1/bin/$command"
  chmod +x "$TEST_HOME/.local/opt/go1.26.1/bin/$command"
done
cp "$TEST_HOME/.local/opt/go1.26.1/bin/bun" "$TEST_HOME/.bun/bin/bun"
cp "$TEST_HOME/.local/opt/go1.26.1/bin/zig" "$TEST_HOME/.local/opt/zig-0.15.2/zig"

if ! PATH="$TEST_BIN:$PATH" HOME="$TEST_HOME" \
  DEV_SETUP_OS_RELEASE_FILE="$SUPPORTED_RELEASE" DEV_SETUP_SUBUID_FILE="$SUBUID_FILE" DEV_SETUP_SUBGID_FILE="$SUBGID_FILE" \
  "$PROJECT_DIR/ubuntu/setup.sh" --only languages >/dev/null 2>&1; then
  fail 'Ubuntu setup must source and run NVM with nounset disabled'
fi

if rg -q '—' "$PROJECT_DIR/README.md"; then
  fail 'README must not contain em dashes'
fi

printf 'PASS: Ubuntu setup supports safe dry runs and Linux-specific configuration\n'
