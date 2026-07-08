autoload -Uz compinit && compinit

alias ls='ls --color=auto'
alias grep='grep --color=auto'

source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

export SHELDON_CONFIG_FILE="$HOME/.agent-stack/.sheldon/plugins.toml"
export SHELDON_DATA_DIR="$HOME/.agent-stack/.sheldon"

. ~/.profile.sh

if [[ -f "$SHELDON_CONFIG_FILE" ]]; then
  eval "$(sheldon source)"
fi

eval "$(starship init zsh)"
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi
export _ZO_DATA_DIR="$HOME/.agent-stack/.zoxide"
eval "$(zoxide init zsh)"
