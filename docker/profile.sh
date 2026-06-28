eval "$(git wt --init "${ZSH_VERSION:+zsh}" "${ZSH_VERSION:-bash}")"

claude_config_dir=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
codex_home=${CODEX_HOME:-$HOME/.codex}

[ -f "$claude_config_dir/RTK.md" ] || rtk init -g --auto-patch 2>/dev/null
[ -f "$codex_home/RTK.md" ] || rtk init -g --codex 2>/dev/null
