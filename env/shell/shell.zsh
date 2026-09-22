# Managed by the Mac development setup. Keep personal shell settings in ~/.zshrc.

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
zsh_completion_dir="$XDG_CONFIG_HOME/zsh/completions"
[[ -d "$zsh_completion_dir" ]] && fpath=("$zsh_completion_dir" $fpath)

if (( $+commands[brew] )); then
  brew_prefix="$(brew --prefix)"
  export JAVA_HOME="$(brew --prefix openjdk@25)/libexec/openjdk.jdk/Contents/Home"
  if brew list --versions postgresql@18 >/dev/null 2>&1; then
    postgres_bin="$(brew --prefix postgresql@18)/bin"
  fi
  brew_zsh_completions="$brew_prefix/share/zsh/site-functions"
  [[ -d "$brew_zsh_completions" ]] && fpath=("$brew_zsh_completions" $fpath)
  [[ -r "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -r "$brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "$brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  [[ -r "$brew_prefix/opt/fzf/shell/key-bindings.zsh" ]] && source "$brew_prefix/opt/fzf/shell/key-bindings.zsh"
  [[ -r "$brew_prefix/opt/fzf/shell/completion.zsh" ]] && source "$brew_prefix/opt/fzf/shell/completion.zsh"
fi

export GOPATH="${GOPATH:-$XDG_CONFIG_HOME/go}"
export PATH="$JAVA_HOME/bin:$HOME/.local/bin:$GOPATH/bin:${postgres_bin:-}:$PATH"

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

export BUN_INSTALL="$HOME/.bun"
[[ -d "$BUN_INSTALL/bin" ]] && export PATH="$BUN_INSTALL/bin:$PATH"
[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"

autoload -Uz compinit
compinit

# Green prompt: vivid on any theme; branch segment stays empty outside repos and is %-safe.
setopt PROMPT_SUBST

_dev_git_branch() { # always succeeds; prints " (branch)", " (@sha)", or nothing
  (( $+commands[git] )) || return 0
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  local branch
  branch="$(git branch --show-current 2>/dev/null)" || branch=""
  if [[ -z "$branch" ]]; then # detached HEAD: fall back to short SHA
    branch="$(git rev-parse --short HEAD 2>/dev/null)" || return 0
    [[ -n "$branch" ]] && branch="@${branch}"
  fi
  [[ -n "$branch" ]] || return 0
  print -r -- " %F{84}(${branch//\%/%%})%f"
}

PROMPT='%B%F{84}%1~%f%b$(_dev_git_branch) %B%F{48}❯%f%b '

# Typed-input colors from the Dracula theme for zsh-syntax-highlighting (truecolor; italic omitted: unsupported by zsh).
ZSH_HIGHLIGHT_STYLES[default]='fg=#F8F8F2'
ZSH_HIGHLIGHT_STYLES[command]='fg=#50FA7B'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#F8F8F2,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#50FA7B'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#50FA7B'
ZSH_HIGHLIGHT_STYLES[path]='fg=#F8F8F2,underline'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#FFB86C'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#FFB86C'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#F1FA8C'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#F1FA8C'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#FF5555'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#6272A4'
