# Managed by the Mac development setup. Keep personal shell settings in ~/.zshrc.

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
fi

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export GOPATH="${GOPATH:-$XDG_CONFIG_HOME/go}"
export PATH="$JAVA_HOME/bin:$HOME/.local/bin:$GOPATH/bin:${postgres_bin:-}:$PATH"

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

export BUN_INSTALL="$HOME/.bun"
[[ -d "$BUN_INSTALL/bin" ]] && export PATH="$BUN_INSTALL/bin:$PATH"
[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"

autoload -Uz compinit
compinit
