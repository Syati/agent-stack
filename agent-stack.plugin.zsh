_agent_stack_home() {
  echo "${HOME}/.agent-stack"
}

_agent_env_lines() {
  local stack_home
  stack_home=$(_agent_stack_home)
  local env_file=${stack_home}/.env

  if [[ ! -f "$env_file" ]]; then
    return 0
  fi

  if command -v op &>/dev/null; then
    op inject -i "$env_file"
  else
    cat "$env_file"
  fi
}

_agent_env_value() {
  local key=$1
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    if [[ "$line" == "${key}="* ]]; then
      echo "${line#*=}"
      return 0
    fi
  done < <(_agent_env_lines)
}

_agent_ensure_home() {
  local stack_home
  stack_home=$(_agent_stack_home)

  mkdir -p "${stack_home}/.claude" "${stack_home}/.codex" "${stack_home}/.chrome-agent"

  if [[ ! -f "${stack_home}/.env" ]]; then
    touch "${stack_home}/.env"
  fi
}

_agent_chrome() {
  local stack_home
  stack_home=$(_agent_stack_home)
  local chrome_bin="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  local chrome_port

  _agent_ensure_home

  if [[ "$OSTYPE" != darwin* ]]; then
    echo "agent chrome currently supports macOS only" >&2
    return 1
  fi

  if [[ ! -x "$chrome_bin" ]]; then
    echo "Google Chrome not found at ${chrome_bin}" >&2
    return 1
  fi

  chrome_port=$(_agent_env_value CHROME_REMOTE_PORT)
  if [[ -z "$chrome_port" ]]; then
    chrome_port=9222
  fi

  "$chrome_bin" \
    --remote-debugging-port="${chrome_port}" \
    --remote-debugging-address=0.0.0.0 \
    --user-data-dir="${stack_home}/.chrome-agent" \
    --no-first-run \
    --no-default-browser-check \
    --password-store=basic \
    --disable-blink-features=AutomationControlled
}

_agent_run() {
  local stack_home
  stack_home=$(_agent_stack_home)
  local env_file=${stack_home}/.env
  local env_args=()

  _agent_ensure_home

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
  echo "  chrome   Start host Chrome with remote debugging for agent-browser"
  echo "  update   Pull latest image from ghcr.io"
  echo "  help     Show this help"
}

agent() {
  case "$1" in
    chrome)      _agent_chrome ;;
    update)      _agent_update ;;
    help|--help|-h) _agent_help ;;
    *)           _agent_run ;;
  esac
}
