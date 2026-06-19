# agent-stack: AI 開発用 Docker コンテナスタック

## Overview

AI エージェント開発で使うツール群（RTK, mise, APM, Claude Code, Codex）を Docker コンテナとしてまとめ、再現可能な開発環境を構築する。ホスト OS の agent-browser（Vercel Labs）と連携し、ブラウザテストも統合する。

## Architecture

```
┌─ Host OS (macOS) ──────────────────────────────────────┐
│                                                        │
│  agent-browser (Chrome, port 9223)                     │
│  環境変数を env var として注入                          │
│                                                        │
└────────────────────────┬───────────────────────────────┘
                         │ host.docker.internal
┌─ Docker Compose ───────┴───────────────────────────────┐
│                                                        │
│  ┌─ workspace ───────────────────────────────────────┐ │
│  │                                                   │ │
│  │  Tools: RTK, mise, Claude Code, Codex, APM, gh, rg │ │
│  │                                                   │ │
│  │  Volumes:                                         │ │
│  │    - /workspace ← project source (bind mount)     │ │
│  │    - ~/.claude  ← claude-home (named volume)      │ │
│  │    - ~/.codex   ← codex-home (named volume)       │ │
│  │    - ~/.local/share/mise ← mise-data (named vol)  │ │
│  │                                                   │ │
│  └───────────────────────────────────────────────────┘ │
│                                                        │
└────────────────────────────────────────────────────────┘
```

## Components

### Tools in Container

| Tool | Version | Purpose | Install Method |
|------|---------|---------|----------------|
| **RTK** | 0.42.4 | Token-optimized CLI proxy (60-90% savings) | GitHub Releases からプリビルドバイナリ |
| **mise** | latest | Dev tool version manager (Node, Ruby, etc.) | curl https://mise.run |
| **Claude Code** | latest | Anthropic's AI CLI | curl https://claude.ai/install.sh |
| **Codex** | latest | OpenAI's AI CLI | curl https://chatgpt.com/codex/install.sh |
| **APM** | 0.16+ | Agent Package Manager | curl https://aka.ms/apm-unix |
| **gh** | latest | GitHub CLI | apt install |

### RTK が利用する外部コマンド

RTK は内部で外部コマンドを呼び出してフィルタリングする。コンテナに含める必要がある。

#### 必須（RTK が直接実行）

| Command | Purpose | Install |
|---------|---------|---------|
| **git** | VCS 操作 | apt |
| **grep** | テキスト検索（rg がない場合のフォールバック） | apt (coreutils) |
| **tree** | ディレクトリ表示 | apt |
| **curl** | HTTP client | apt |
| **wc** | 行数カウント等 | apt (coreutils) |

#### 推奨（RTK が自動検出して利用、大幅なトークン削減）

| Command | Purpose | Install | Savings |
|---------|---------|---------|---------|
| **rg** (ripgrep) | 高速 grep、RTK が自動的に利用 | apt or cargo | grep 比 80% 削減 |

#### プロキシ対象（開発で使うもの、RTK がラップ）

| Command | Purpose | Install |
|---------|---------|---------|
| **gh** | GitHub CLI | apt |
| **docker** | コンテナ操作（DinD/socket mount 時） | 必要に応じて |

> **Note:** RTK は単一 Rust バイナリで、外部ツールがなくても graceful に degradation する。
> `rg` は特に重要 — RTK の grep フィルタが自動で ripgrep を利用し、トークン消費を大幅削減する。

### Host OS Services

| Service | Purpose | Connection |
|---------|---------|------------|
| **agent-browser** | Browser automation with real Chrome | WebSocket on port 9223 |
| **環境変数** | Secret management | ホスト側で解決済みの値を env var で注入 |

## File Structure

```
agent-stack/
├── docker/
│   └── Dockerfile              # Single-stage build (debian:bookworm-slim)
├── config/
│   ├── claude/
│   │   ├── settings.json       # RTK hook + permission allowlist
│   │   └── CLAUDE.md           # Container-specific instructions
│   ├── codex/
│   │   └── instructions.md     # Container-specific instructions
│   └── mise/
│       └── config.toml         # Runtime versions (Node 23, Ruby, etc.)
├── compose.yml                 # Docker Compose orchestration
├── apm.yml                     # APM manifest
├── .mise.toml                  # Project-level mise config
├── .env.example                # Required environment variables
├── .gitignore
├── Makefile                    # Build/run/manage commands
├── architecture.md             # This file
└── CLAUDE.md                   # Project instructions
```

## Dockerfile Design

Single-stage build。全ツールがプリビルドバイナリまたはインストーラー（`curl`）で導入できるため、マルチステージ不要。

```
debian:bookworm-slim
       │
  ┌────┴──────────┐
  │               │
  │ build-essential│
  │ locales (UTF-8)│
  │ RTK (deb)     │
  │ mise, gh      │
  │ rg, tree      │
  │ claude, codex │
  │ user: agent   │
  │               │
  └───────────────┘
```

## Docker Compose Services

### workspace

メインの開発コンテナ。全ツールを含み、プロジェクトソースをバインドマウント。

- **Build target**: `dev`
- **Volumes**: project source (bind), claude config (named), codex config (named), mise data (named)
- **Environment**: API keys via `.env`
- **Network**: `host.docker.internal` でホストの agent-browser に接続

## Secret Management

```
┌─ .env (gitignored) ─────────────────────┐
│ ANTHROPIC_API_KEY=sk-ant-...            │
│ OPENAI_API_KEY=sk-...                   │
│ GITHUB_PERSONAL_ACCESS_TOKEN=ghp_...    │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─ Docker Compose ────────────────────────┐
│ env_file: .env                          │
│   → workspace container                 │
└─────────────────────────────────────────┘
```

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make build` | Docker イメージビルド |
| `make dev` | 開発環境起動 |
| `make shell` | workspace コンテナにシェルで入る |
| `make claude` | コンテナ内で Claude Code 起動 |
| `make codex` | コンテナ内で Codex 起動 |
| `make ab-start` | ホストの agent-browser 起動 |
| `make clean` | コンテナ・ボリューム削除 |

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **agent-browser はホスト実行** | Chrome とディスプレイが必要。コンテナからは WebSocket で接続 |
| **MCP は後日対応** | まずコアツール（RTK, mise, Claude Code, Codex, APM）で動く環境を優先 |
| **シークレットは env var で注入** | `.env` ファイル経由でホストからコンテナに環境変数を渡す |
| **RTK はプリビルドバイナリ** | GitHub Releases に .deb / .tar.gz あり。Rust ビルダー不要 |
| **Debian Bookworm slim** | glibc 互換（Alpine の musl は Rust バイナリで問題）、Ubuntu より軽量 |
| **rg (ripgrep) を同梱** | RTK の grep フィルタが自動利用、80% のトークン削減 |

## Future Scope (v2)

- **MCP servers**: brave-search, context7, agent-browser MCP 等の統合
- **CI profile**: GitHub Actions 用 headless テスト環境
- **Sandbox profile**: ネットワーク制限付き Claude Code 実行環境
- **Cloud browser backends**: CI での Browserbase/Browserless 連携
- **Multi-architecture**: ARM64 (Apple Silicon) + AMD64 ビルド
