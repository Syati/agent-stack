# agent-stack

AI agent development container with [Claude Code](https://claude.ai/code), [Codex](https://github.com/openai/codex), [RTK](https://github.com/rtk-ai/rtk), [mise](https://mise.jdx.dev/), [APM](https://github.com/microsoft/apm), [entire](https://entire.io), and [git-wt](https://github.com/k1LoW/git-wt) pre-installed.

[日本語版 README](README.ja.md)

## Prerequisites

- macOS + [Colima](https://github.com/abiosoft/colima) running as the Docker backend. The shell launcher calls `colima ssh` / `colima status` to resolve the SSH agent socket and to check readiness, so Docker Desktop or other backends are not supported out of the box.
- Colima should use the following config:

  ```yaml
  vmType: vz
  mountType: virtiofs
  forwardAgent: true
  ```

  If `mountType` is left on `sshfs`, `entire` can hang on the mounted workspace.

## Overview

- Start from your current project directory with `agent`.
- Add `agent --docker` only when the container must control host Docker.
- Container-only state lives under `~/.agent-stack`, separate from host dotfiles.

## Quick Start

Source the plugin in your `~/.zshrc`:

```bash
source /path/to/agent-stack/agent-stack.plugin.zsh
```

If you manage shell plugins with [sheldon](https://github.com/rossmacarthur/sheldon), add it to `~/.config/sheldon/plugins.toml` instead:

```toml
[plugins.agent-stack]
github = "Syati/agent-stack"
use = ["agent-stack.plugin.zsh"]
```

Then start a container from the current directory:

```bash
agent
```

- `agent` bind-mounts the current directory at the same absolute path on the host and sets `-w "$(pwd)"` so the container starts there.
- This is intentional: when `agent --docker` exposes the host Docker socket, `docker run` and `docker build` executed inside the container still have their bind-mount paths and build contexts resolved by the host Docker daemon.
- If the in-container path differs from the host path, nested Docker commands can target a non-existent path or the wrong build context.

Run a tool directly instead of starting an interactive shell when needed:

```bash
agent codex
agent claude
agent zsh -lc 'uname -a'
```

## Runtime Behavior

- `agent --docker` mounts `/var/run/docker.sock` so the container can control host Docker.
- By default, the host Docker socket is not mounted. Use `agent --docker` only when needed.
- The launcher resolves `SSH_AUTH_SOCK` from inside the Colima VM via `colima ssh` and mounts the forwarded socket into the container.
- Multiple instances can run in parallel. If several agents work on the same repo, use [git-wt](https://github.com/k1LoW/git-wt) worktrees to avoid conflicts.

## Persistent Data

- `~/.agent-stack` stores container-only settings and auth state.
- `~/.agent-stack/.codex` is used as `CODEX_HOME`.
- `~/.agent-stack/.claude` is used as `CLAUDE_CONFIG_DIR`.
- `~/.agent-stack/.mise` stores global `mise` config and state.
- `agent-mise-data` keeps installed `mise` tool payloads under `/home/agent/.local/share/mise` across container recreations.
- Host `~/.gitconfig` is mounted read-only so `git commit` and `git push` work inside the container.

On first use, the plugin automatically creates these paths:

```text
~/.agent-stack/.env
~/.agent-stack/.claude
~/.agent-stack/.codex
~/.agent-stack/.chrome-agent
~/.agent-stack/.mise/state
~/.agent-stack/.sheldon/plugins.toml
```

Authenticate once inside the container to populate them:

- Codex: `codex login --device-auth`
- Claude Code: run `claude` and complete the normal interactive login flow

With preinstalled [sheldon](https://github.com/rossmacarthur/sheldon), optional shell plugins can be added in `~/.agent-stack/.sheldon/plugins.toml`. For example:

```toml
shell = "zsh"

[plugins.entire-fzf]
github = "Syati/entire-fzf"
```

For anything else (aliases, env vars, arbitrary shell config), drop a `~/.agent-stack/.zshrc.local` and/or `~/.agent-stack/.bashrc.local` — they're sourced automatically at the end of `.zshrc` / `.bashrc` if present.

## Container User

Runs as non-root user `agent` (home: `/home/agent`, shell: `zsh`). The image default working directory is `/workspace`, but the `agent` launcher overrides it at runtime to the current directory (`$(pwd)`).

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
MISE_GLOBAL_CONFIG_FILE=/home/agent/.agent-stack/.mise/config.toml
MISE_STATE_DIR=/home/agent/.agent-stack/.mise/state
```

This keeps container auth and settings separate from host-side dotfiles while making `mise use -g ...` persistent in the agent stack. The installed tool payloads still live in the named Docker volume mounted at `/home/agent/.local/share/mise`. On first launch, authenticate inside the container once to populate those directories. For Codex, use `codex login --device-auth`. For Claude Code, run `claude` and complete the normal interactive login flow.

## Local Build

```bash
git clone https://github.com/Syati/agent-stack.git
cd agent-stack
make build
AGENT_STACK_IMAGE=agent-stack:local agent
```

Need a different tag or Dockerfile? Override the Make variables, for example `make build IMAGE=agent-stack:dev` or `make build DOCKERFILE=docker/Dockerfile`.

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
