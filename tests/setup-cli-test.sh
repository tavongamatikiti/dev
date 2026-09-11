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

mkdir -p "$TEST_BIN" "$TEST_HOME/.nvm" "$TEST_HOME/.sdkman" "$TEST_HOME/.ssh"
printf 'private key\n' > "$TEST_HOME/.ssh/id_ed25519"
printf 'public key\n' > "$TEST_HOME/.ssh/id_ed25519.pub"

for command in brew xcode-select gem pod git ssh-add sudo; do
  cat > "$TEST_BIN/$command" <<'EOF'
#!/usr/bin/env bash
if [[ "$0" == */git && "$1" == "config" && "$2" == "--global" ]]; then
  if [[ $# -gt 3 ]]; then
    printf '%s\n' "$*" >> "$TEST_GIT_CONFIG_LOG"
  elif [[ "$3" == "user.email" ]]; then
    printf 'test@example.com\n'
  elif [[ "$3" == "user.name" ]]; then
    printf 'Test User\n'
  fi
  exit 0
fi
if [[ "$0" == */brew && "$1" == "--prefix" ]]; then
  printf '/opt/homebrew\n'
fi
if [[ "$0" == */brew && "$1" == "list" && "${TEST_BREW_MISSING:-0}" == "1" ]]; then
  exit 1
fi
exit 0
EOF
  chmod +x "$TEST_BIN/$command"
done

help_output=$(PATH="$TEST_BIN:$PATH" HOME="$TEST_HOME" "$PROJECT_DIR/setup.sh" --help || true)
[[ "$help_output" == *'Usage:'* ]] || fail 'setup --help should print usage without starting setup'

dry_output=$(PATH="$TEST_BIN:$PATH" HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" \
  "$PROJECT_DIR/setup.sh" --dry-run --only configs)
[[ "$dry_output" == *'[dry-run]'* ]] || fail 'config dry run should report planned work'
[[ ! -e "$TEST_HOME/.config/nvim" ]] || fail 'config dry run must not create files'

legacy_output=$(TEST_BREW_MISSING=1 PATH="$TEST_BIN:$PATH" HOME="$TEST_HOME" \
  "$PROJECT_DIR/runs/dev.sh" --dry-run || true)
[[ "$legacy_output" == *'[dry-run]'* ]] || fail 'legacy component wrappers should delegate to the safe setup CLI'

git_config_log="$TEST_HOME/git-config.log"
TEST_BREW_MISSING=1 PATH="$TEST_BIN:$PATH" HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" \
  TEST_GIT_CONFIG_LOG="$git_config_log" "$PROJECT_DIR/setup.sh" --dry-run --skip-apps >/dev/null
[[ ! -s "$git_config_log" ]] || fail 'full dry run must not write global Git configuration'

bootstrap_output=$(TEST_BREW_MISSING=1 PATH="$TEST_BIN:$PATH" HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" \
  "$PROJECT_DIR/setup.sh" --dry-run --skip-apps)
[[ "$bootstrap_output" == *'brew install openjdk@25'* ]] || fail 'fresh-Mac setup should install Java 25 LTS'
[[ "$bootstrap_output" == *'brew install cmake'* ]] || fail 'fresh-Mac setup should install explicitly requested CMake'
[[ "$bootstrap_output" == *'brew install gitleaks'* ]] || fail 'fresh-Mac setup should install explicitly requested Gitleaks'
[[ "$bootstrap_output" == *'brew install cocoapods'* ]] || fail 'fresh-Mac setup should install CocoaPods through Homebrew'
[[ "$bootstrap_output" == *'brew install bun'* ]] || fail 'fresh-Mac setup should install Bun'
[[ "$bootstrap_output" == *'brew install --cask ngrok'* ]] || fail 'fresh-Mac setup should install ngrok as a cask'
[[ "$bootstrap_output" == *'brew install felixkratz/formulae/borders'* ]] || fail 'fresh-Mac setup should install AeroSpace borders'
[[ "$bootstrap_output" == *'activate Node.js LTS and install pnpm'* ]] || fail 'fresh-Mac setup should activate pnpm'
[[ "$bootstrap_output" == *'brew install postgresql@18'* ]] || fail 'fresh-Mac setup should install PostgreSQL 18'
[[ "$bootstrap_output" == *'go install golang.org/x/tools/gopls@latest'* ]] || fail 'fresh-Mac setup should install gopls'
[[ "$bootstrap_output" == *'sdk install springboot'* ]] || fail 'fresh-Mac setup should install Spring Boot'
[[ "$bootstrap_output" == *'install managed Zsh environment'* ]] || fail 'fresh-Mac setup should install the managed shell environment'
[[ "$bootstrap_output" == *'brew install ddgr'* ]] || fail 'fresh-Mac setup should install ddgr'
[[ "$bootstrap_output" == *'brew install gitleaks'* ]] || fail 'fresh-Mac setup should install gitleaks'
[[ "$bootstrap_output" == *'brew install mole'* ]] || fail 'fresh-Mac setup should install mole'

printf 'PASS: setup CLI supports help and a non-mutating config dry run\n'
