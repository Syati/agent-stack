autoload -Uz compinit && compinit

alias ls='ls --color=auto'
alias grep='grep --color=auto'

source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

export SHELDON_CONFIG_FILE="$HOME/.agent-stack/.sheldon/plugins.toml"

if [[ -f "$SHELDON_CONFIG_FILE" ]]; then
  eval "$(sheldon source)"
fi

eval "$(starship init zsh)"
eval "$(fzf --zsh)"
export _ZO_DATA_DIR="$HOME/.agent-stack/.zoxide"
eval "$(zoxide init zsh)"

. ~/.profile.sh
