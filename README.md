# agent-stack

AI agent development container with [Claude Code](https://claude.ai/code), [Codex](https://github.com/openai/codex), [RTK](https://github.com/rtk-ai/rtk), [mise](https://mise.jdx.dev/), [APM](https://github.com/microsoft/apm), [entire](https://entire.io), and [git-wt](https://github.com/k1LoW/git-wt) pre-installed.

## Quick Start

Pull from ghcr.io:

```bash
docker run -it -v $(pwd):/workspace --env-file .env ghcr.io/syati/agent-stack bash
```

Or use in your project's `compose.yml`:

```yaml
services:
  agent:
    image: ghcr.io/syati/agent-stack:latest
    volumes:
      - .:/workspace
    env_file:
      - .env
    extra_hosts:
      - "host.docker.internal:host-gateway"
    stdin_open: true
    tty: true
```

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
| build-essential | C/C++ compiler toolchain |

## Environment Variables

Create a `.env` file:

```
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
GITHUB_PERSONAL_ACCESS_TOKEN=ghp_...
```

## Local Build

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

[agent-browser](https://github.com/vercel-labs/agent-browser) runs on the host OS (requires Chrome). The container connects via `host.docker.internal`:

```bash
# On host
agent-browser stream enable --port 9223

# In container, agent-browser CLI connects to host
```

## Architecture

See [architecture.md](architecture.md) for design details.

## License

MIT
