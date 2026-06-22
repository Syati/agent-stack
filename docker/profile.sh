eval "$(git wt --init "${ZSH_VERSION:+zsh}" "${ZSH_VERSION:-bash}")"

[ -f "$HOME/.claude/RTK.md" ] || rtk init -g --auto-patch 2>/dev/null
[ -f "$HOME/.codex/RTK.md" ] || rtk init -g --codex 2>/dev/null
