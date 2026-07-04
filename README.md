# agent-stack

AI agent development container with [Claude Code](https://claude.ai/code), [Codex](https://github.com/openai/codex), [RTK](https://github.com/rtk-ai/rtk), [mise](https://mise.jdx.dev/), [APM](https://github.com/microsoft/apm), [entire](https://entire.io), and [git-wt](https://github.com/k1LoW/git-wt) pre-installed.

[日本語版 README](README.ja.md)

## Prerequisites

- macOS + [Colima](https://github.com/abiosoft/colima) running as the Docker backend. The shell launcher calls `colima ssh` / `colima status` to resolve the SSH agent socket and to check readiness, so Docker Desktop or other backends are not supported out of the box.

## Quick Start

Source the plugin in your `~/.zshrc`:

```bash
source /path/to/agent-stack/agent-stack.plugin.zsh
```

Then start a container from the current directory:

```bash
agent
```

- **Docker socket**: allows the container to control host Docker (`docker build`, `docker run`, `docker exec`, etc.). Remove if not needed.
- **Bind mount (`~/.agent-stack`)**: persists container-only agent settings on the host. `Codex` uses `~/.agent-stack/.codex`, `Claude` uses `~/.agent-stack/.claude`, so they stay separated from host-side `~/.codex` and `~/.claude`.
- **Named volume (`agent-mise-data`)**: persists mise-installed runtimes across container recreations.
- **gitconfig**: mounts host git config (read-only) so `git commit` and `git push` work inside the container.
- **SSH agent**: the shell launcher resolves the forwarded agent socket from the Colima VM and mounts it into the container. Set `ssh.forwardAgent: true` in Colima so the forwarded agent is available.

With preinstalled [sheldon](https://github.com/rossmacarthur/sheldon), optional shell plugins can be added in `~/.agent-stack/.sheldon/plugins.toml`. For example:

```toml
[plugins.entire-fzf]
github = "Syati/entire-fzf"
```

On first use, the plugin automatically creates `~/.agent-stack/.env`, `~/.agent-stack/.claude`, `~/.agent-stack/.codex`, `~/.agent-stack/.chrome-agent`, and `~/.agent-stack/.sheldon/plugins.toml`.

By default, `agent` does not mount the host Docker socket. Use `agent --docker` only when the container needs to run host Docker commands such as `docker build`, `docker run`, or `docker compose`.

`agent` reads `SSH_AUTH_SOCK` from inside the Colima VM by calling `colima ssh`, then mounts that forwarded socket into the container. If you need SSH credentials inside the container, enable `ssh.forwardAgent: true` in Colima and restart Colima after changing the config.

You can pass a container command directly, for example `agent claude`, `agent codex`, or `agent zsh -lc 'uname -a'`.

Multiple instances can run in parallel. Each `agent` call creates a separate container, so [git-wt](https://github.com/k1LoW/git-wt) worktrees are still the safest way to avoid file conflicts when several agents work on the same repo.

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
| [sheldon](https://github.com/rossmacarthur/sheldon) | Plugin manager for user-managed shell extensions |
| [gh](https://cli.github.com/) | GitHub CLI |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Fast grep (auto-used by RTK) |
| [agent-browser](https://github.com/vercel-labs/agent-browser) | Browser automation for AI agents |
| build-essential | C/C++ compiler toolchain |

## Environment Variables

`~/.agent-stack/.env` is optional. Use it only when you want to pass extra environment variables through the shell launcher, for example:

```
GH_TOKEN=op://Private/github-pat/credential
CHROME_REMOTE_PORT=9222
AGENT_TCP_BRIDGES=127.0.0.1:64342->host.docker.internal:64342
```

When [1Password CLI](https://developer.1password.com/docs/cli/) (`op`) is available, `op://` references are resolved via `op inject` automatically. Without `op`, the file is passed as-is.

`AGENT_TCP_BRIDGES` is optional. It starts one or more TCP bridges inside the container before your command runs. Use a comma-separated list of `listen_host:listen_port->target_host:target_port` entries when a host-side service only accepts requests that preserve `localhost` on the client side.

For example, this lets container-side Codex keep using `http://127.0.0.1:64342/stream` for RubyMine MCP while forwarding the traffic to the host:

```bash
AGENT_TCP_BRIDGES=127.0.0.1:64342->host.docker.internal:64342
```

Multiple bridges can be defined with commas:

```bash
AGENT_TCP_BRIDGES=127.0.0.1:64342->host.docker.internal:64342,127.0.0.1:9223->host.docker.internal:9223
```

`agent` sets these paths explicitly inside the container:

```bash
CODEX_HOME=/home/agent/.agent-stack/.codex
CLAUDE_CONFIG_DIR=/home/agent/.agent-stack/.claude
```

This keeps container auth and settings separate from host-side `~/.codex` and `~/.claude`. On first launch, authenticate inside the container once to populate those directories. For Codex, use `codex login --device-auth`. For Claude Code, run `claude` and complete the normal interactive login flow.

## Local Build

```bash
git clone https://github.com/Syati/agent-stack.git
cd agent-stack
docker build -t agent-stack:local -f docker/Dockerfile .
AGENT_STACK_IMAGE=agent-stack:local agent
```

## agent-browser Integration

[agent-browser](https://github.com/vercel-labs/agent-browser) is pre-installed in the container. Start Chrome on the host with remote debugging, then connect from the container.

**Host side** (`agent chrome` or manually):

```bash
agent chrome
```

**Container side** (run `chrome-connect` to resolve WebSocket URL and connect):

```bash
chrome-connect
```

`agent chrome` reads `CHROME_REMOTE_PORT` from `~/.agent-stack/.env` and defaults to `9222`. Its Chrome profile is stored in `~/.agent-stack/.chrome-agent`, so the browser state also stays scoped to `agent-stack`. The plugin launcher is currently macOS-only because it uses the standard `/Applications/Google Chrome.app/...` path.

## License

MIT
