# Login-shell environment shared by Ghostty and other macOS terminals.

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

typeset -U path PATH
path=("$HOME/.local/bin" $path)

jetbrains_toolbox="$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
if [[ -d "$jetbrains_toolbox" ]]; then
  path+=("$jetbrains_toolbox")
fi
unset jetbrains_toolbox

export PATH
