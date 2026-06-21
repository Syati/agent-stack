autoload -Uz compinit && compinit
autoload -Uz colors && colors

PROMPT='%F{cyan}%n%f:%F{blue}%~%f%# '

alias ls='ls --color=auto'
alias grep='grep --color=auto'

source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

. ~/.profile.sh
