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
      - claude-home:/home/agent/.claude
      - codex-home:/home/agent/.codex
      - mise-data:/home/agent/.local/share/mise
    env_file:
      - .env
    extra_hosts:
      - "host.docker.internal:host-gateway"

volumes:
  claude-home:
  codex-home:
  mise-data:
```

- **Docker socket**: allows the container to control host Docker (`docker compose run`, `docker exec`, etc.). Remove if not needed.
- **Named volumes**: persist Claude Code/Codex session history and mise-installed runtimes across container recreations. Only cleared by `docker compose down -v`.
- **gitconfig**: mounts host git config (read-only) so `git commit` and `git push` work inside the container.

Start the container and connect:

```bash
docker compose up -d
docker compose exec -it agent bash
```

Use `docker compose exec` (not `docker attach`). Each `exec` spawns an independent process, so multiple agents can run in parallel without stdin conflicts.

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

Create a `.env` file:

```
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
GITHUB_PERSONAL_ACCESS_TOKEN=ghp_...
```

## Local Build

See [compose.yml](compose.yml) for a working example.

```bash
git clone https://github.com/Syati/agent-stack.git
cd agent-stack
cp .env.example .env
# edit .env with your keys

make build   # build image
make dev     # start container
make shell   # open shell
make claude  # run Claude Code
make codex   # run Codex
make clean   # stop and remove
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
