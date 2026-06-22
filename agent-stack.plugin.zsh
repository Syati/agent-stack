agent() {
  local env_file=${HOME}/.agent-stack.env
  local env_arg=()
  if [[ -f "$env_file" ]]; then
    if command -v op &>/dev/null; then
      env_arg=(--env-file =(op inject -i "$env_file"))
    else
      env_arg=(--env-file "$env_file")
    fi
  fi

  docker run -it \
    -v $(pwd):/workspace \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v ${HOME}/.gitconfig:/home/agent/.gitconfig:ro \
    -v agent-claude-home:/home/agent/.claude \
    -v agent-codex-home:/home/agent/.codex \
    -v agent-mise-data:/home/agent/.local/share/mise \
    ${env_arg[@]} \
    --add-host host.docker.internal:host-gateway \
    ghcr.io/syati/agent-stack zsh
}
