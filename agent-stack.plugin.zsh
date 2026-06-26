_agent_run() {
  local env_file=${HOME}/.agent-stack.env
  local env_args=()
  if [[ -f "$env_file" ]]; then
    if command -v op &>/dev/null; then
      while IFS= read -r line; do
        [[ -n "$line" && "$line" != \#* ]] && env_args+=(-e "$line")
      done < <(op inject -i "$env_file")
    else
      env_args=(--env-file "$env_file")
    fi
  fi

  docker run -it \
    -v $(pwd):/workspace \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v ${HOME}/.gitconfig:/home/agent/.gitconfig:ro \
    -v ${HOME}/.claude:/home/agent/.claude \
    -v ${HOME}/.codex:/home/agent/.codex \
    -v agent-mise-data:/home/agent/.local/share/mise \
    ${env_args[@]} \
    --add-host host.docker.internal:host-gateway \
    ghcr.io/syati/agent-stack:latest zsh
}

_agent_update() {
  docker pull ghcr.io/syati/agent-stack:latest
}

_agent_help() {
  echo "Usage: agent [command]"
  echo ""
  echo "Commands:"
  echo "  (none)   Start agent container in current directory"
  echo "  update   Pull latest image from ghcr.io"
  echo "  help     Show this help"
}

agent() {
  case "$1" in
    update)      _agent_update ;;
    help|--help|-h) _agent_help ;;
    *)           _agent_run ;;
  esac
}
