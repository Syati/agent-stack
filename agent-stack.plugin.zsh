agent() {
  docker run -it \
    -v $(pwd):/workspace \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v ${HOME}/.gitconfig:/home/agent/.gitconfig:ro \
    -v agent-claude-home:/home/agent/.claude \
    -v agent-codex-home:/home/agent/.codex \
    -v agent-mise-data:/home/agent/.local/share/mise \
    --env-file ${HOME}/.agent-stack.env \
    --add-host host.docker.internal:host-gateway \
    ghcr.io/syati/agent-stack zsh
}
