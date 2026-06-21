autoload -Uz compinit && compinit

alias ls='ls --color=auto'
alias grep='grep --color=auto'

source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

eval "$(starship init zsh)"

. ~/.profile.sh
