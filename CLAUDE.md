# agent-stack

AI 開発用 Docker コンテナスタック。

## Commands

- `agent` — カレントディレクトリを `/workspace` にマウントしてシェル起動
- `agent claude` — コンテナ内で Claude Code 起動
- `agent codex` — コンテナ内で Codex 起動
- `agent --docker` — ホスト Docker socket をマウントして起動
- `docker build -t agent-stack:local -f docker/Dockerfile .` — ローカルイメージビルド
- `AGENT_STACK_IMAGE=agent-stack:local agent` — ローカルビルドしたイメージで起動
- `scripts/update-versions.sh` — Dockerfile のツールバージョンを最新に更新
