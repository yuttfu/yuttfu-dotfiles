# Interactive Zsh configuration for yuttfu.

typeset -U path PATH
if [[ -z "${HOMEBREW_PREFIX:-}" ]]; then
  if [[ -d /opt/homebrew ]]; then
    HOMEBREW_PREFIX=/opt/homebrew
  elif [[ -d /usr/local/Homebrew ]]; then
    HOMEBREW_PREFIX=/usr/local
  else
    HOMEBREW_PREFIX=""
  fi
fi

if [[ -n "$HOMEBREW_PREFIX" ]]; then
  path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" $path)
fi
path=("$HOME/.local/bin" $path)

if [[ -d "$HOME/Library/pnpm" ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
  path=("$PNPM_HOME" $path)
fi
export PATH

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# Completion
if [[ -n "$HOMEBREW_PREFIX" ]] && [[ -d "$HOMEBREW_PREFIX/share/zsh-completions" ]]; then
  fpath=("$HOMEBREW_PREFIX/share/zsh-completions" $fpath)
fi
autoload -Uz compinit
zsh_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$zsh_cache_dir"
compinit -d "$zsh_cache_dir/zcompdump"
unset zsh_cache_dir
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select

# Interactive tools
if (( $+commands[fzf] )); then
  source <(fzf --zsh 2>/dev/null)
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border=rounded --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc,marker:#f5e0dc,prompt:#cba6f7,hl+:#f38ba8'
fi

if (( $+commands[fd] )); then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi

if (( $+commands[fnm] )); then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

# Conda changes environments; Starship owns the prompt.
if (( $+commands[conda] )); then
  conda_hook="$(conda shell.zsh hook 2>/dev/null)"
  if [[ -n "$conda_hook" ]]; then
    eval "$conda_hook"
  fi
  unset conda_hook
fi

# Aliases are only installed when their commands are available.
if (( $+commands[eza] )); then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -la --icons --group-directories-first'
  alias lt='eza --tree --icons --level=2'
fi
(( $+commands[bat] )) && alias cat='bat'
(( $+commands[fd] )) && alias find='fd'
(( $+commands[rg] )) && alias grep='rg'
(( $+commands[btop] )) && alias top='btop'
(( $+commands[lazygit] )) && alias lg='lazygit'

set-ssh-key() {
  local key="$HOME/.ssh/$1"
  if [[ -z "$1" || ! -f "$key" ]]; then
    printf 'Key not found: %s\n' "$key" >&2
    printf 'Available keys:\n' >&2
    command ls "$HOME"/.ssh/*.pub 2>/dev/null | sed 's|.*/|  |; s|\.pub$||' >&2
    return 1
  fi

  ssh-add -D 2>/dev/null
  ssh-add "$key"
  printf 'Active SSH key: %s\n' "$1"
}

if (( $+commands[yazi] )); then
  y() {
    local cwd_file
    cwd_file="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$cwd_file"
    if local next_dir="$(command cat -- "$cwd_file")"; then
      if [[ -n "$next_dir" && "$next_dir" != "$PWD" ]]; then
        builtin cd -- "$next_dir"
      fi
    fi
    command rm -f -- "$cwd_file"
  }
fi

if [[ "${TERM_PROGRAM:-}" == "vscode" ]] && [[ -r "$HOME/.config/starship-vscode.toml" ]]; then
  export STARSHIP_CONFIG="$HOME/.config/starship-vscode.toml"
fi

if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

if [[ -n "$HOMEBREW_PREFIX" ]] && [[ -r "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6c7086'
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

if [[ -r "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi

# This plugin must remain last so it can observe every widget definition.
if [[ -n "$HOMEBREW_PREFIX" ]] && [[ -r "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
