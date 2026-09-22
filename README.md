<div align="center">
  <h1>dev</h1>
  <p>Reproducible development setup for macOS and private Ubuntu servers.</p>
</div>

## Install

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/tavongamatikiti/dev/v1.0.9/install-mac.sh | bash -s -- --ref v1.0.9
```

### Ubuntu

Run this as the normal `dev` account with `sudo` access, never as root:

```bash
curl -fsSL https://raw.githubusercontent.com/tavongamatikiti/dev/v1.0.9/install-ubuntu.sh | bash -s -- --ref v1.0.9
```

The bootstrap refuses to overwrite an existing `~/Developer/dev` folder.

## Before You Start

- macOS with an administrator account, or Ubuntu 22.04, 24.04, or 26.04 with a normal sudo-enabled development account
- Internet access
- Enough disk space for Xcode tools, Homebrew packages, and apps

## Usage

## macOS

Review the intended changes first:

```bash
./setup.sh --dry-run
```

Run the full setup, excluding GUI applications:

```bash
./setup.sh --skip-apps
```

Run one component at a time:

```bash
./setup.sh --only configs
./setup.sh --only core
./setup.sh --only git
```

On a new Mac, run `./setup.sh` with no options. It installs every component, including GUI applications. macOS requires you to complete the Xcode Command Line Tools dialog once; then rerun the same command.

Available components are `backup`, `xcode`, `homebrew`, `core`, `languages`, `postgres`, `apps`, `git`, `shell`, `configs`, and `verify`.

`./dev-env.sh` remains as a compatibility command for installing configuration files. Use `./dev-env.sh --dry` to preview it.

## What It Configures

- CLI tools: Git, tmux, ripgrep, fzf, tree, tldr, Neovim, Watchman, cloudflared, jq, wget, GitHub CLI, Zig, Gradle, Maven, CMake, Gitleaks, fd, Tree-sitter, Bun, pnpm, psql, and borders for AeroSpace window outlines
- Runtimes: Node via NVM, Java 25 LTS, Ruby, CocoaPods, Go, gopls, Zig, and zls
- PostgreSQL 18 as a Homebrew service on new Macs. Existing PostgreSQL 17 services are left running until their data is explicitly migrated.
- Optional GUI applications: Arc, Postman, WhatsApp, Spotify, Zoom, JetBrains Toolbox, Blip, Ghostty, Karabiner-Elements, Obsidian, Raycast, and JetBrains Mono Nerd Font. Karabiner-Elements and Zoom use privileged installers, so one admin password is requested upfront.
- Git identity, rebase pulls, default branch preference, and separate macOS-keychain SSH keys for GitHub (`id_ed25519`) and GitLab (`id_ed25519_gitlab`). The GitLab key prompts for its own email address.
- Repository-managed AeroSpace, Ghostty, Karabiner, tmux, Neovim, tmux-sessionizer, tmux-persist, screenshot organizer, managed Zsh environment files, static completions for GitHub CLI, Gitleaks, and ripgrep, plus fzf key bindings and completions

The config installer copies only its own files and never removes unrelated files from `~/.config`. It installs the screenshot organizer as a user LaunchAgent. It preserves tmux-persist itself but never preserves its saved sessions. Before any shell changes, the installer creates a private backup under `~/.local/state/dev-setup/backups/shell`, including tmux-resurrect/continuum state when present.

## Ubuntu

Ubuntu setup installs developer tooling, Java 25, Node, Bun, pnpm, Go, Zig, Spring Boot CLI, Neovim, tmux, the PostgreSQL client, and rootless Podman. It supports only Ubuntu 22.04, 24.04, and 26.04 LTS. Run it as the existing `dev` account, never through `sudo`.

```bash
./ubuntu/setup.sh --dry-run
./ubuntu/setup.sh
./ubuntu/setup.sh --only podman
```

It does not configure UFW, SSH, port 22, Headscale, VPNs, Docker, application services, databases, reverse proxies, or containers. Rootless Podman has no containers or exposed ports after setup.

The same repository location is used on both platforms: `~/Developer/dev`.
