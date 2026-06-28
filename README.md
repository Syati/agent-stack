# agent-stack

AI agent development container with [Claude Code](https://claude.ai/code), [Codex](https://github.com/openai/codex), [RTK](https://github.com/rtk-ai/rtk), [mise](https://mise.jdx.dev/), [APM](https://github.com/microsoft/apm), [entire](https://entire.io), and [git-wt](https://github.com/k1LoW/git-wt) pre-installed.

## Quick Start

Add to your project's `compose.yml`:

```yaml
services:
  agent:
    image: ghcr.io/syati/agent-stack:latest
    volumes:
      - .:/workspace
      - /var/run/docker.sock:/var/run/docker.sock  # host Docker access
      - ${HOME}/.gitconfig:/home/agent/.gitconfig:ro    # git config
      - ${HOME}/.agent-stack:/home/agent/.agent-stack
      - mise-data:/home/agent/.local/share/mise
    env_file:
      - .env
    environment:
      CODEX_HOME: /home/agent/.agent-stack/.codex
      CLAUDE_CONFIG_DIR: /home/agent/.agent-stack/.claude
    extra_hosts:
      - "host.docker.internal:host-gateway"

volumes:
  mise-data:
```

- **Docker socket**: allows the container to control host Docker (`docker compose run`, `docker exec`, etc.). Remove if not needed.
- **Bind mount (`~/.agent-stack`)**: persists container-only agent settings on the host. `Codex` uses `~/.agent-stack/.codex`, `Claude` uses `~/.agent-stack/.claude`, so they stay separated from host-side `~/.codex` and `~/.claude`.
- **Named volume (`mise-data`)**: persists mise-installed runtimes across container recreations. Cleared by `docker compose down -v`.
- **gitconfig**: mounts host git config (read-only) so `git commit` and `git push` work inside the container.

Start the container and connect:

```bash
docker compose up -d
docker compose exec -it agent bash
```

Use `docker compose exec` (not `docker attach`). Each `exec` spawns an independent process, so multiple agents can run in parallel without stdin conflicts.

## Shell Function (no compose.yml needed)

With [sheldon](https://github.com/rossmacarthur/sheldon), add to `~/.config/sheldon/plugins.toml`:

```toml
[plugins.agent-stack]
github = "Syati/agent-stack"
```

Or source the plugin directly in your `~/.zshrc`:

```bash
source /path/to/agent-stack/agent-stack.plugin.zsh
```

Initialize the container-specific config area:

```bash
agent init
```

This creates `~/.agent-stack/.env`, `~/.agent-stack/.claude`, and `~/.agent-stack/.codex`.

Multiple instances can run in parallel — each `agent` call creates a separate container. Use [git-wt](https://github.com/k1LoW/git-wt) worktrees to avoid file conflicts when multiple agents work on the same repo.

## Container User

Runs as non-root user `agent` (home: `/home/agent`, shell: `zsh`). Working directory is `/workspace`.

## What's Inside

| Tool | Description |
|------|-------------|
| [Claude Code](https://claude.ai/code) | Anthropic's AI coding CLI |
| [Codex](https://github.com/openai/codex) | OpenAI's AI coding CLI |
| [RTK](https://github.com/rtk-ai/rtk) | Token-optimized CLI proxy (60-90% token savings) |
| [mise](https://mise.jdx.dev/) | Dev tool version manager |
| [APM](https://github.com/microsoft/apm) | Agent Package Manager for MCP/skills |
| [entire](https://entire.io) | AI session capture for git |
| [git-wt](https://github.com/k1LoW/git-wt) | Simplified git worktree management |
| [gh](https://cli.github.com/) | GitHub CLI |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Fast grep (auto-used by RTK) |
| [agent-browser](https://github.com/vercel-labs/agent-browser) | Browser automation for AI agents |
| build-essential | C/C++ compiler toolchain |

## Environment Variables

Create `~/.agent-stack/.env` (used by the shell function):

```
ANTHROPIC_API_KEY=op://Private/anthropic/credential
OPENAI_API_KEY=op://Private/openai/credential
GH_TOKEN=op://Private/github-pat/credential
```

If you already have `~/.agent-stack.env`, move its contents into `~/.agent-stack/.env`.

When [1Password CLI](https://developer.1password.com/docs/cli/) (`op`) is available, `op://` references are resolved via `op inject` automatically. Without `op`, the file is passed as-is.

`agent` sets these paths explicitly inside the container:

```bash
CODEX_HOME=/home/agent/.agent-stack/.codex
CLAUDE_CONFIG_DIR=/home/agent/.agent-stack/.claude
```

This keeps container auth and settings separate from host-side `~/.codex` and `~/.claude`. On first launch, authenticate `codex` and `claude` once inside the container to populate the new directories.

## Local Build

See [compose.yml](compose.yml) for a working example.

```bash
git clone https://github.com/Syati/agent-stack.git
cd agent-stack
cp .env.example .env
# edit .env with your keys

make build             # build image
make dev               # start container
make shell             # open shell
make claude            # run Claude Code
make codex             # run Codex
make update-versions   # update tool versions in Dockerfile
make clean             # stop and remove
```

## agent-browser Integration

[agent-browser](https://github.com/vercel-labs/agent-browser) is pre-installed in the container. Start Chrome on the host with remote debugging, then connect from the container.

**Host side** (`make chrome` or manually):

```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222 \
  --remote-debugging-address=0.0.0.0 \
  --user-data-dir=$HOME/.chrome-agent \
  --no-first-run \
  --no-default-browser-check \
  --password-store=basic \
  --disable-blink-features=AutomationControlled
```

**Container side** (run `chrome-connect` to resolve WebSocket URL and connect):

```bash
chrome-connect
```

Port is configurable via `CHROME_REMOTE_PORT` in `.env` (default: 9222).

## License

MIT
