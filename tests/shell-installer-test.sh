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

mkdir -p "$TEST_BIN" "$TEST_HOME/.config"
printf 'export PERSONAL_SETTING=keep\n' > "$TEST_HOME/.zshrc"
cat > "$TEST_BIN/brew" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "--prefix" && "$2" == "openjdk@25" ]]; then
  printf '/opt/homebrew/opt/openjdk@25\n'
else
  printf '/opt/homebrew\n'
fi
EOF
chmod +x "$TEST_BIN/brew"

PATH="$TEST_BIN:$PATH" HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" \
  "$PROJECT_DIR/scripts/install-shell-config.sh"
PATH="$TEST_BIN:$PATH" HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" \
  "$PROJECT_DIR/scripts/install-shell-config.sh"

shell_value=$(PATH="$TEST_BIN:$PATH" HOME="$TEST_HOME" TEST_HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" \
  /bin/zsh -df -c 'export HOME="$TEST_HOME"; unset GOPATH; source "$HOME/.zshrc"; print -r -- "$JAVA_HOME|$GOPATH"')
[[ "$shell_value" == '/opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home|'"$TEST_HOME"'/.config/go' ]] || fail 'managed shell environment did not set Java 25 and GOPATH'
grep -Fqx 'export PERSONAL_SETTING=keep' "$TEST_HOME/.zshrc" >/dev/null || fail 'installer removed user shell configuration'
[[ "$(grep -Fc '# >>> dev-setup managed shell >>>' "$TEST_HOME/.zshrc")" == '1' ]] || fail 'installer added duplicate source blocks'
prompt_value=$(PATH="$TEST_BIN:$PATH" HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" \
  /bin/zsh -df -c 'source "$HOME/.config/dev-setup/shell.zsh"; print -r -- "$PROMPT"')
[[ "$prompt_value" == *'%F{84}'* ]] || fail 'managed shell should define a vivid-green prompt'
grep -Fq "ZSH_HIGHLIGHT_STYLES[default]='fg=#F8F8F2'" "$TEST_HOME/.config/dev-setup/shell.zsh" >/dev/null || fail 'managed shell should follow the Dracula reference for typed input'
grep -Fq "ZSH_HIGHLIGHT_STYLES[precommand]='fg=#F8F8F2,bold'" "$TEST_HOME/.config/dev-setup/shell.zsh" >/dev/null || fail 'managed shell should highlight precommands bright white bold'
grep -Fq "ZSH_HIGHLIGHT_STYLES[path]='fg=#F8F8F2,underline'" "$TEST_HOME/.config/dev-setup/shell.zsh" >/dev/null || fail 'managed shell should underline paths in foreground white'
grep -Fq "ZSH_HIGHLIGHT_STYLES[builtin]='fg=#50FA7B'" "$TEST_HOME/.config/dev-setup/shell.zsh" >/dev/null || fail 'managed shell should highlight builtins green like commands'

printf 'PASS: installs one managed shell source block without overwriting user settings\n'
