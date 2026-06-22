#!/bin/sh
set -eu

FILE="docker/Dockerfile"
cd "$(git rev-parse --show-toplevel)"

latest() {
  gh api "repos/$1/releases/latest" --jq '.tag_name' | sed "s/^$2//"
}

codex_latest() {
  gh api "repos/openai/codex/releases" --jq '[.[] | select(.tag_name | startswith("rust-v")) | .tag_name][0]' | sed 's/^rust-v//'
}

update_arg() {
  arg="$1"; new="$2"
  old=$(grep "^ARG ${arg}=" "$FILE" | cut -d= -f2)
  if [ "$old" != "$new" ] && [ -n "$new" ]; then
    sed -i.bak "s/^ARG ${arg}=.*/ARG ${arg}=${new}/" "$FILE"
    rm -f "$FILE.bak"
    printf '  %s: %s → %s\n' "$arg" "$old" "$new"
  fi
}

update_arg RTK_VERSION "$(latest rtk-ai/rtk v)"
update_arg CODEX_VERSION "$(codex_latest)"
update_arg GIT_WT_VERSION "$(latest k1LoW/git-wt v)"
update_arg AGENT_BROWSER_VERSION "$(latest vercel-labs/agent-browser v)"
