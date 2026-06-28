_agent_stack_home() {
  echo "${HOME}/.agent-stack"
}

_agent_init() {
  local stack_home
  stack_home=$(_agent_stack_home)

  mkdir -p "${stack_home}/.claude" "${stack_home}/.codex"

  if [[ ! -f "${stack_home}/.env" ]]; then
    touch "${stack_home}/.env"
  fi

  echo "Initialized ${stack_home}"
}

_agent_run() {
  local stack_home
  stack_home=$(_agent_stack_home)
  local env_file=${stack_home}/.env
  local env_args=()

  _agent_init >/dev/null

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
    -v "$(pwd)":/workspace \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "${HOME}/.gitconfig:/home/agent/.gitconfig:ro" \
    -v "${stack_home}:/home/agent/.agent-stack" \
    -v agent-mise-data:/home/agent/.local/share/mise \
    ${env_args[@]} \
    -e CODEX_HOME=/home/agent/.agent-stack/.codex \
    -e CLAUDE_CONFIG_DIR=/home/agent/.agent-stack/.claude \
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
  echo "  init     Create ~/.agent-stack, .env, .claude, and .codex"
  echo "  update   Pull latest image from ghcr.io"
  echo "  help     Show this help"
}

agent() {
  case "$1" in
    init)        _agent_init ;;
    update)      _agent_update ;;
    help|--help|-h) _agent_help ;;
    *)           _agent_run ;;
  esac
}
