#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0
SKIP_APPS=0
ONLY_COMPONENT=""

usage() {
  cat <<'EOF'
Usage: ./setup.sh [--dry-run] [--skip-apps] [--only COMPONENT]

Set up this Mac's development tools and configuration.

Components: backup, xcode, homebrew, core, languages, postgres, apps, git, sdkman, shell, configs, verify
  --dry-run          Show commands without changing the machine.
  --skip-apps        Do not install graphical applications.
  --only COMPONENT   Run exactly one component.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --skip-apps) SKIP_APPS=1 ;;
    --only)
      [[ $# -ge 2 ]] || { printf '%s\n' '--only requires a component' >&2; exit 1; }
      ONLY_COMPONENT="$2"
      shift
      ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

run_component() {
  [[ -z "$ONLY_COMPONENT" || "$ONLY_COMPONENT" == "$1" ]]
}

require_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    printf 'This installer supports macOS only.\n' >&2
    exit 1
  fi
}

ensure_brew() {
  if command_exists brew; then
    printf 'Homebrew already installed.\n'
    return
  fi

  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] install Homebrew from https://brew.sh\n'
    return
  fi

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

brew_install() {
  local package="$1"
  if brew list "$package" >/dev/null 2>&1; then
    printf '%s already installed.\n' "$package"
  else
    run brew install "$package"
  fi
}

brew_install_cask() {
  local package="$1"
  if brew list --cask "$package" >/dev/null 2>&1; then
    printf '%s already installed.\n' "$package"
  else
    run brew install --cask "$package"
  fi
}

install_xcode() {
  if xcode-select -p >/dev/null 2>&1; then
    printf 'Xcode Command Line Tools already installed.\n'
  elif [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] xcode-select --install\n'
  else
    xcode-select --install
    printf 'Finish the Xcode Command Line Tools prompt, then rerun setup.\n'
    exit 0
  fi
}

install_core() {
  local packages=(
    git tmux ripgrep fzf tree tldr neovim watchman jq wget gh zig zls go gradle maven
    ninja pipx yq shellcheck zsh-completions zsh-autosuggestions zsh-syntax-highlighting
    bear cmake cocoapods coreutils ddgr fd ffmpeg gitleaks mole poppler python-tk@3.14
    tree-sitter tree-sitter-cli bun
  )
  local package
  for package in "${packages[@]}"; do
    brew_install "$package"
  done
  brew_install_cask ngrok
  install_borders
}

install_borders() {
  if brew list borders >/dev/null 2>&1; then
    printf 'borders already installed.\n'
    return
  fi

  run brew tap felixkratz/formulae
  run brew trust --formula felixkratz/formulae/borders
  run brew install felixkratz/formulae/borders
}

install_go_tools() {
  local gopls_path
  export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
  export GOPATH="${GOPATH:-$XDG_CONFIG_HOME/go}"
  if [[ "$DRY_RUN" == "1" ]]; then
    run go install golang.org/x/tools/gopls@latest
    return
  fi
  gopls_path="$GOPATH/bin/gopls"
  if [[ -x "$gopls_path" ]]; then
    printf 'gopls already installed.\n'
  else
    run go install golang.org/x/tools/gopls@latest
  fi
}

install_languages() {
  if [[ ! -d "$HOME/.nvm" ]]; then
    if [[ "$DRY_RUN" == "1" ]]; then
      printf '[dry-run] install NVM and the Node.js LTS release\n'
    else
      curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.6/install.sh | PROFILE=/dev/null bash
      export NVM_DIR="$HOME/.nvm"
      # shellcheck disable=SC1091
      . "$NVM_DIR/nvm.sh"
      nvm install --lts
    fi
  else
    printf 'nvm already installed.\n'
  fi

  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] activate Node.js LTS and install pnpm\n'
  else
    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm use --lts
    if command_exists pnpm; then
      printf 'pnpm already installed.\n'
    else
      npm install --global pnpm
    fi
  fi

  brew_install openjdk@25
  brew_install ruby

  if [[ ! -e /Library/Java/JavaVirtualMachines/openjdk-25.jdk ]]; then
    run sudo ln -sfn "$(brew --prefix openjdk@25)/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk-25.jdk
  fi

  if ! command_exists pod; then
    run sudo gem install cocoapods
  else
    printf 'cocoapods already installed.\n'
  fi
}

install_postgres() {
  brew_install postgresql@18
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] brew services start postgresql@18 when PostgreSQL 17 is not already running\n'
  elif brew services list | awk '$1 == "postgresql@17" && $2 == "started" { found = 1 } END { exit !found }'; then
    printf 'PostgreSQL 17 is already running. PostgreSQL 18 was installed but was not started; migrate data explicitly before switching services.\n'
  elif ! brew services list | awk '$1 == "postgresql@18" && $2 == "started" { found = 1 } END { exit !found }'; then
    brew services start postgresql@18
  else
    printf 'postgresql@18 already running.\n'
  fi
}

install_apps() {
  local apps=(arc postman whatsapp spotify zoom jetbrains-toolbox blip aerospace dash ghostty karabiner-elements obsidian raycast font-jetbrains-mono-nerd-font)
  local app
  for app in "${apps[@]}"; do
    brew_install_cask "$app"
  done
}

configure_git() {
  local email name
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] configure Git identity, pull rebase, and default branch when needed\n'
    printf '[dry-run] generate and add an SSH key only when %s is absent\n' "$HOME/.ssh/id_ed25519"
    return
  fi

  email="$(git config --global user.email || true)"
  name="$(git config --global user.name || true)"

  if [[ -z "$email" ]]; then
    read -r -p 'GitHub email: ' email
    git config --global user.email "$email"
  fi
  if [[ -z "$name" ]]; then
    read -r -p 'GitHub name: ' name
    git config --global user.name "$name"
  fi

  git config --global pull.rebase true
  git config --global init.defaultBranch master

  if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
    printf 'SSH key already exists: %s\n' "$HOME/.ssh/id_ed25519"
    return
  fi

  run mkdir -p "$HOME/.ssh"
  run chmod 700 "$HOME/.ssh"
  run ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ''
  if [[ "$DRY_RUN" == "0" ]] && ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519" 2>/dev/null; then
    printf 'SSH key added to the macOS keychain.\n'
  fi
  if [[ "$DRY_RUN" == "0" ]]; then
    printf 'Add this SSH key to GitHub:\n'
    cat "$HOME/.ssh/id_ed25519.pub"
  fi
}

install_sdkman() {
  if [[ ! -d "$HOME/.sdkman" ]]; then
    if [[ "$DRY_RUN" == "1" ]]; then
      printf '[dry-run] install SDKMAN\n'
    else
      curl -s https://get.sdkman.io | rcupdate=false bash
    fi
  else
    printf 'SDKMAN already installed.\n'
  fi

  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] sdk install springboot\n'
  elif [[ ! -d "$HOME/.sdkman/candidates/springboot/current" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk install springboot
  else
    printf 'Spring Boot CLI already installed.\n'
  fi
}

backup_shell_configs() {
  local args=()
  [[ "$DRY_RUN" == "1" ]] && args+=(--dry-run)
  "$SCRIPT_DIR/scripts/backup-shell-configs.sh" "${args[@]}"
}

install_shell_environment() {
  local args=()
  [[ "$DRY_RUN" == "1" ]] && args+=(--dry-run)
  "$SCRIPT_DIR/scripts/install-shell-config.sh" "${args[@]}"
}

install_configs() {
  local args=()
  [[ "$DRY_RUN" == "1" ]] && args+=(--dry-run)
  "$SCRIPT_DIR/scripts/install-configs.sh" "${args[@]}"
}

verify_setup() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] verify installed commands and configuration paths\n'
    return
  fi

  export NVM_DIR="$HOME/.nvm"
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  export SDKMAN_DIR="$HOME/.sdkman"
  [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
  XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
  export GOPATH="${GOPATH:-$XDG_CONFIG_HOME/go}"
  export PATH="$(brew --prefix postgresql@18)/bin:$GOPATH/bin:$PATH"
  local required_commands=(git tmux rg fzf nvim node bun pnpm java javac mvn gradle spring go gopls zig zls ninja pipx yq shellcheck psql)
  local required_paths=(
    "$XDG_CONFIG_HOME/nvim/init.lua"
    "$XDG_CONFIG_HOME/tmux/tmux.conf"
    "$XDG_CONFIG_HOME/tmux-sessionizer/tmux-sessionizer.sh"
    "$HOME/.local/bin/tmux-sessionizer"
    "$HOME/.local/bin/tmux-persist"
    "$HOME/.local/bin/organize-screenshots"
    "$XDG_CONFIG_HOME/aerospace/aerospace.toml"
    "$XDG_CONFIG_HOME/ghostty/config"
    "$XDG_CONFIG_HOME/karabiner/karabiner.json"
    "$XDG_CONFIG_HOME/dev-setup/shell.zsh"
  )
  local command path missing=0

  for command in "${required_commands[@]}"; do
    if command -v "$command" >/dev/null 2>&1; then
      printf 'verified command: %s\n' "$command"
    else
      printf 'missing command: %s\n' "$command" >&2
      missing=1
    fi
  done
  for path in "${required_paths[@]}"; do
    if [[ -e "$path" ]]; then
      printf 'verified path: %s\n' "$path"
    else
      printf 'missing path: %s\n' "$path" >&2
      missing=1
    fi
  done
  [[ "$missing" == "0" ]]
}

require_macos

case "$ONLY_COMPONENT" in
  ''|backup|xcode|homebrew|core|languages|postgres|apps|git|sdkman|shell|configs|verify) ;;
  *) printf 'Unknown component: %s\n' "$ONLY_COMPONENT" >&2; usage >&2; exit 1 ;;
esac

if [[ -z "$ONLY_COMPONENT" || "$ONLY_COMPONENT" == backup || "$ONLY_COMPONENT" == languages || "$ONLY_COMPONENT" == sdkman || "$ONLY_COMPONENT" == shell ]]; then
  backup_shell_configs
fi
run_component xcode && install_xcode
if run_component homebrew || run_component core || run_component languages || run_component postgres || run_component apps; then
  ensure_brew
fi
run_component homebrew && [[ -z "$ONLY_COMPONENT" ]] && run brew update
run_component core && install_core
run_component core && install_go_tools
run_component languages && install_languages
run_component postgres && install_postgres
if [[ "$SKIP_APPS" == "0" ]] && run_component apps; then
  install_apps
fi
run_component git && configure_git
run_component sdkman && install_sdkman
run_component shell && install_shell_environment
run_component configs && install_configs
run_component verify && verify_setup

printf 'Mac development setup complete.\n'
