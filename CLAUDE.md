# agent-stack

AI 開発用 Docker コンテナスタック。

## Commands

- `make build` — イメージビルド
- `make dev` — コンテナ起動
- `make shell` — コンテナに入る
- `make claude` — Claude Code 起動
- `make codex` — Codex 起動
- `make clean` — コンテナ・ボリューム削除

## RTK

Always prefix commands with `rtk`:
```bash
rtk git status
rtk git diff
rtk grep <pattern>
```
