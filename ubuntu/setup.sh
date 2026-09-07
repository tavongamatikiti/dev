#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OS_RELEASE_FILE="${DEV_SETUP_OS_RELEASE_FILE:-/etc/os-release}"
SUBUID_FILE="${DEV_SETUP_SUBUID_FILE:-/etc/subuid}"
SUBGID_FILE="${DEV_SETUP_SUBGID_FILE:-/etc/subgid}"
DRY_RUN=0
ONLY_COMPONENT=""
ARCH=""
TARGET_USER="dev"

usage() {
  cat <<'EOF'
Usage: ubuntu/setup.sh [--dry-run] [--only COMPONENT]

Set up a private Ubuntu development and production-style host.

Components: preflight, apt, java, languages, sdkman, podman, backup, shell, configs, verify
  --dry-run          Show commands without changing the host.
  --only COMPONENT   Run exactly one component.

Run this as the dev user with sudo access. Do not run it with sudo.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
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

require_ubuntu() {
  if [[ "$(uname -s)" != "Linux" ]]; then
    printf 'This installer supports Ubuntu Linux only.\n' >&2
    exit 1
  fi
  [[ -r "$OS_RELEASE_FILE" ]] || { printf 'Cannot read %s.\n' "$OS_RELEASE_FILE" >&2; exit 1; }

  # shellcheck disable=SC1090
  source "$OS_RELEASE_FILE"
  if [[ "${ID:-}" != "ubuntu" ]]; then
    printf 'This installer supports Ubuntu only. Detected: %s\n' "${ID:-unknown}" >&2
    exit 1
  fi
  case "${VERSION_ID:-}" in
    22.04|24.04|26.04) ;;
    *)
      printf 'Unsupported Ubuntu release: %s. Supported releases are 22.04, 24.04, and 26.04 LTS.\n' "${VERSION_ID:-unknown}" >&2
      exit 1
      ;;
  esac
}

require_development_user() {
  local current_user
  if [[ "${EUID}" == "0" ]]; then
    printf 'Run this installer as the dev account, not as root or through sudo.\n' >&2
    exit 1
  fi
  current_user="$(id -un)"
  if [[ "$current_user" != "$TARGET_USER" ]]; then
    printf 'Run this installer as %s. Current account: %s\n' "$TARGET_USER" "$current_user" >&2
    exit 1
  fi
  if ! command_exists sudo; then
    printf 'sudo is required for the system packages and rootless Podman prerequisites.\n' >&2
    exit 1
  fi
}

detect_architecture() {
  case "$(uname -m)" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) printf 'Unsupported architecture: %s. Supported architectures are amd64 and arm64.\n' "$(uname -m)" >&2; exit 1 ;;
  esac
}

require_sudo() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] sudo credentials will be requested before system changes\n'
  else
    sudo -v
  fi
}

install_apt_packages() {
  local packages=(
    build-essential ca-certificates curl gnupg git zsh tmux neovim ripgrep fzf tree jq wget
    ninja-build cmake pipx shellcheck fd-find ffmpeg poppler-utils python3 python3-pip python3-venv
    maven gradle podman uidmap slirp4netns fuse-overlayfs zsh-autosuggestions zsh-syntax-highlighting
  )
  run sudo apt-get update
  run sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"
}

install_optional_apt_packages() {
  local package
  local packages=(gh gitleaks tldr bear ddgr)
  for package in "${packages[@]}"; do
    if [[ "$DRY_RUN" == "1" ]]; then
      printf '[dry-run] install optional Ubuntu package when available: %s\n' "$package"
    elif apt-cache show "$package" >/dev/null 2>&1; then
      run sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "$package"
    else
      printf 'Optional package is unavailable on this Ubuntu release: %s\n' "$package"
    fi
  done
}

install_apt() {
  install_apt_packages
  install_optional_apt_packages
}

install_java() {
  local key_file="/etc/apt/keyrings/adoptium.gpg"
  local source_file="/etc/apt/sources.list.d/adoptium.list"
  local key_tmp source_tmp codename

  # shellcheck disable=SC1090
  source "$OS_RELEASE_FILE"
  codename="${VERSION_CODENAME:-}"
  [[ -n "$codename" ]] || { printf 'Ubuntu codename is unavailable.\n' >&2; exit 1; }

  if [[ "$DRY_RUN" == "1" ]]; then
    run sudo apt-get update
    run sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl gnupg
    printf '[dry-run] add Adoptium signed package source for %s\n' "$codename"
    run sudo apt-get update
    run sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y temurin-25-jdk
    return
  fi

  sudo apt-get update
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl gnupg
  key_tmp="$(mktemp)"
  source_tmp="$(mktemp)"
  trap 'rm -f "$key_tmp" "$source_tmp"' RETURN
  curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor > "$key_tmp"
  printf 'deb [signed-by=%s] https://packages.adoptium.net/artifactory/deb %s main\n' "$key_file" "$codename" > "$source_tmp"
  sudo install -d -m 0755 /etc/apt/keyrings /etc/apt/sources.list.d
  sudo install -m 0644 "$key_tmp" "$key_file"
  sudo install -m 0644 "$source_tmp" "$source_file"
  sudo apt-get update
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y temurin-25-jdk
  trap - RETURN
  rm -f "$key_tmp" "$source_tmp"
}

go_archive_for_arch() {
  case "$ARCH" in
    amd64) printf '%s\n' 'go1.26.1.linux-amd64.tar.gz' ;;
    arm64) printf '%s\n' 'go1.26.1.linux-arm64.tar.gz' ;;
  esac
}

zig_archive_for_arch() {
  case "$ARCH" in
    amd64) printf '%s\n' 'zig-x86_64-linux-0.15.2.tar.xz' ;;
    arm64) printf '%s\n' 'zig-aarch64-linux-0.15.2.tar.xz' ;;
  esac
}

install_go() {
  local archive destination download
  archive="$(go_archive_for_arch)"
  destination="$HOME/.local/opt/go1.26.1"
  if [[ -x "$destination/bin/go" ]]; then
    printf 'Go 1.26.1 already installed.\n'
    return
  fi
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] download and install Go 1.26.1 for %s at %s\n' "$ARCH" "$destination"
    return
  fi
  download="$(mktemp)"
  trap 'rm -f "$download"' RETURN
  curl -fsSL "https://go.dev/dl/$archive" -o "$download"
  mkdir -p "$HOME/.local/opt"
  if [[ -e "$destination" ]]; then
    printf 'Existing Go destination is incomplete: %s. Move it aside, then rerun this installer.\n' "$destination" >&2
    exit 1
  fi
  mkdir -p "$destination"
  tar -xzf "$download" -C "$destination" --strip-components=1
  trap - RETURN
  rm -f "$download"
}

install_zig() {
  local archive destination download
  archive="$(zig_archive_for_arch)"
  destination="$HOME/.local/opt/zig-0.15.2"
  if [[ -x "$destination/zig" ]]; then
    printf 'Zig 0.15.2 already installed.\n'
    return
  fi
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] download and install Zig 0.15.2 for %s at %s\n' "$ARCH" "$destination"
    return
  fi
  download="$(mktemp)"
  trap 'rm -f "$download"' RETURN
  curl -fsSL "https://ziglang.org/download/0.15.2/$archive" -o "$download"
  mkdir -p "$HOME/.local/opt"
  if [[ -e "$destination" ]]; then
    printf 'Existing Zig destination is incomplete: %s. Move it aside, then rerun this installer.\n' "$destination" >&2
    exit 1
  fi
  mkdir -p "$destination"
  tar -xJf "$download" -C "$destination" --strip-components=1
  trap - RETURN
  rm -f "$download"
}

load_nvm() {
  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  source "$NVM_DIR/nvm.sh"
}

install_languages() {
  if [[ ! -s "$HOME/.nvm/nvm.sh" ]]; then
    if [[ "$DRY_RUN" == "1" ]]; then
      printf '[dry-run] install NVM 0.40.6 without editing shell profiles\n'
      printf '[dry-run] install Node.js LTS and enable Corepack\n'
    else
      curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.6/install.sh | PROFILE=/dev/null bash
      load_nvm
      nvm install --lts
      nvm use --lts
      corepack enable
    fi
  else
    printf 'NVM already installed.\n'
  fi
  install_go
  install_zig
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] install gopls using Go\n'
  elif [[ ! -x "$HOME/go/bin/gopls" ]]; then
    "$HOME/.local/opt/go1.26.1/bin/go" install golang.org/x/tools/gopls@latest
  else
    printf 'gopls already installed.\n'
  fi
}

install_sdkman() {
  if [[ ! -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
    if [[ "$DRY_RUN" == "1" ]]; then
      printf '[dry-run] install SDKMAN without editing shell profiles\n'
    else
      curl -fsSL https://get.sdkman.io | rcupdate=false bash
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

subid_range_start() {
  local files=()
  [[ -r "$SUBUID_FILE" ]] && files+=("$SUBUID_FILE")
  [[ -r "$SUBGID_FILE" ]] && files+=("$SUBGID_FILE")
  if [[ "${#files[@]}" == "0" ]]; then
    printf '%s\n' 131072
    return
  fi
  awk -F: '
    BEGIN { maximum = 99999 }
    {
      if ($2 ~ /^[0-9]+$/ && $3 ~ /^[0-9]+$/) {
        end = $2 + $3 - 1
        if (end > maximum) maximum = end
      }
    }
    END { print int((maximum + 65536) / 65536) * 65536 }
  ' "${files[@]}"
}

has_subid_mapping() {
  local mapping_file="$1" user="$2"
  [[ -r "$mapping_file" ]] && grep -q "^${user}:" "$mapping_file"
}

ensure_subid_mappings() {
  local user="$TARGET_USER" range_start range_end range
  if has_subid_mapping "$SUBUID_FILE" "$user" && has_subid_mapping "$SUBGID_FILE" "$user"; then
    printf 'Subordinate UID and GID mappings already exist for %s.\n' "$user"
    return
  fi
  range_start="$(subid_range_start)"
  range_end=$((range_start + 65535))
  range="${range_start}-${range_end}"
  if [[ "$DRY_RUN" == "1" ]]; then
    if ! has_subid_mapping "$SUBUID_FILE" "$user"; then
      run sudo usermod --add-subuids "$range" "$user"
    fi
    if ! has_subid_mapping "$SUBGID_FILE" "$user"; then
      run sudo usermod --add-subgids "$range" "$user"
    fi
    return
  fi
  if ! has_subid_mapping "$SUBUID_FILE" "$user"; then
    sudo usermod --add-subuids "$range" "$user"
  fi
  if ! has_subid_mapping "$SUBGID_FILE" "$user"; then
    sudo usermod --add-subgids "$range" "$user"
  fi
}

install_podman() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] install Podman rootless dependencies from Ubuntu packages\n'
  else
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y podman uidmap slirp4netns fuse-overlayfs
  fi
  ensure_subid_mappings
  run sudo loginctl enable-linger "$TARGET_USER"
}

backup_configs() {
  local args=()
  [[ "$DRY_RUN" == "1" ]] && args+=(--dry-run)
  "$PROJECT_DIR/scripts/backup-shell-configs.sh" "${args[@]}"
}

install_shell() {
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
  local command missing=0
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] verify Ubuntu developer commands, Java 25, and rootless Podman\n'
    return
  fi
  export PATH="$HOME/.local/opt/go1.26.1/bin:$HOME/.local/opt/zig-0.15.2:$HOME/.local/bin:$HOME/go/bin:$PATH"
  export NVM_DIR="$HOME/.nvm"
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  export SDKMAN_DIR="$HOME/.sdkman"
  [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
  for command in git tmux rg fzf nvim node java javac mvn gradle spring go gopls zig podman; do
    if command_exists "$command"; then
      printf 'verified command: %s\n' "$command"
    else
      printf 'missing command: %s\n' "$command" >&2
      missing=1
    fi
  done
  java -version 2>&1 | grep -q '25\.' || { printf 'Java 25 is not active.\n' >&2; missing=1; }
  podman info --format '{{.Host.Security.Rootless}}' | grep -qx true || { printf 'Podman is not running rootless.\n' >&2; missing=1; }
  [[ "$missing" == "0" ]]
}

require_ubuntu
require_development_user
detect_architecture

case "$ONLY_COMPONENT" in
  ''|preflight|apt|java|languages|sdkman|podman|backup|shell|configs|verify) ;;
  *) printf 'Unknown component: %s\n' "$ONLY_COMPONENT" >&2; usage >&2; exit 1 ;;
esac

if [[ -z "$ONLY_COMPONENT" || "$ONLY_COMPONENT" == preflight ]]; then
  printf 'Preflight passed for Ubuntu on %s.\n' "$ARCH"
fi

if [[ -z "$ONLY_COMPONENT" || "$ONLY_COMPONENT" == apt || "$ONLY_COMPONENT" == java || "$ONLY_COMPONENT" == podman ]]; then
  require_sudo
fi

if run_component apt; then install_apt; fi
if run_component java; then install_java; fi
if run_component languages; then install_languages; fi
if run_component sdkman; then install_sdkman; fi
if run_component podman; then install_podman; fi
if [[ -z "$ONLY_COMPONENT" || "$ONLY_COMPONENT" == backup || "$ONLY_COMPONENT" == shell || "$ONLY_COMPONENT" == configs ]]; then
  backup_configs
fi
if run_component shell; then install_shell; fi
if run_component configs; then install_configs; fi
if run_component verify; then verify_setup; fi
