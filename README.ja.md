# agent-stack

[English README](README.md)

## 前提条件

- macOS + Docker バックエンドとして [Colima](https://github.com/abiosoft/colima) が起動していること。shell launcher は SSH agent socket の解決や起動確認のために `colima ssh` / `colima status` を呼び出すため、Docker Desktop など他のバックエンドは標準ではサポートしていません。

[Claude Code](https://claude.ai/code), [Codex](https://github.com/openai/codex), [RTK](https://github.com/rtk-ai/rtk), [mise](https://mise.jdx.dev/), [APM](https://github.com/microsoft/apm), [entire](https://entire.io), [git-wt](https://github.com/k1LoW/git-wt) などをプリインストールした、AI エージェント開発向けコンテナです。

## クイックスタート

まず `~/.zshrc` で plugin を読み込みます。

```bash
source /path/to/agent-stack/agent-stack.plugin.zsh
```

その後、現在のディレクトリをマウントしてコンテナを起動します。

```bash
agent
```

- **Docker socket**: ホストの Docker をコンテナ内から操作するために使います。`docker build` `docker run` `docker exec` などが必要なときだけ `agent --docker` を使ってください。
- **Bind mount (`~/.agent-stack`)**: コンテナ専用の設定をホスト側へ保持します。`Codex` は `~/.agent-stack/.codex`、`Claude` は `~/.agent-stack/.claude` を使うので、ホストの `~/.codex` や `~/.claude` と分離できます。
- **Named volume (`agent-mise-data`)**: `mise` で入れたランタイムをコンテナ再作成後も保持します。
- **gitconfig**: ホストの git 設定を read-only でマウントし、コンテナ内でも `git commit` や `git push` を使えるようにします。
- **SSH agent**: Colima VM 内の forwarded agent socket を解決してコンテナへマウントします。Colima 側で `ssh.forwardAgent: true` を有効にしてください。

プリインストール済みの [sheldon](https://github.com/rossmacarthur/sheldon) を使うと、追加の shell plugin を `~/.agent-stack/.sheldon/plugins.toml` でユーザー側から管理できます。たとえば:

```toml
[plugins.entire-fzf]
github = "Syati/entire-fzf"
```

初回実行時に `~/.agent-stack/.env` `~/.agent-stack/.claude` `~/.agent-stack/.codex` `~/.agent-stack/.chrome-agent` `~/.agent-stack/.sheldon/plugins.toml` を自動作成します。

デフォルトではホストの Docker socket はマウントしません。コンテナ内からホスト Docker を使う必要がある場合だけ `agent --docker` を使ってください。

`agent` は `colima ssh` を使って Colima VM 内の `SSH_AUTH_SOCK` を取得し、その forwarded socket をコンテナへマウントします。コンテナ内で SSH 認証が必要なら、Colima の `ssh.forwardAgent: true` を有効にし、設定変更後は Colima を再起動してください。

コンテナ内で実行するコマンドをそのまま渡せます。たとえば `agent claude` `agent codex` `agent zsh -lc 'uname -a'` のように使えます。

複数インスタンスの並行起動も可能です。`agent` を呼ぶたびに独立したコンテナが立ち上がるため、複数エージェントで同じリポジトリを触る場合は [git-wt](https://github.com/k1LoW/git-wt) の worktree を使うのが安全です。

## コンテナユーザー

非 root ユーザー `agent` で動作します。ホームディレクトリは `/home/agent`、シェルは `zsh`、作業ディレクトリは `/workspace` です。

## 同梱ツール

| ツール | 説明 |
|------|-------------|
| [Claude Code](https://claude.ai/code) | Anthropic の AI コーディング CLI |
| [Codex](https://github.com/openai/codex) | OpenAI の AI コーディング CLI |
| [RTK](https://github.com/rtk-ai/rtk) | トークン使用量を抑える CLI プロキシ |
| [mise](https://mise.jdx.dev/) | 開発ツールのバージョン管理 |
| [APM](https://github.com/microsoft/apm) | MCP / skills 用の Agent Package Manager |
| [entire](https://entire.io) | AI セッションの git 記録ツール |
| [git-wt](https://github.com/k1LoW/git-wt) | シンプルな git worktree 管理 |
| [sheldon](https://github.com/rossmacarthur/sheldon) | ユーザー管理の shell 拡張向け plugin manager |
| [gh](https://cli.github.com/) | GitHub CLI |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | 高速 grep |
| [agent-browser](https://github.com/vercel-labs/agent-browser) | AI エージェント向けブラウザ自動化 |
| build-essential | C/C++ ビルドツールチェーン |

## 環境変数

`~/.agent-stack/.env` は任意です。shell launcher 経由で追加の環境変数を渡したいときだけ使ってください。たとえば:

```bash
GH_TOKEN=op://Private/github-pat/credential
CHROME_REMOTE_PORT=9222
AGENT_TCP_BRIDGES=127.0.0.1:64342->host.docker.internal:64342
```

[1Password CLI](https://developer.1password.com/docs/cli/) (`op`) が使える環境では、`op://` 参照を `op inject` で自動展開します。`op` がない場合は、そのまま `--env-file` として渡します。

`AGENT_TCP_BRIDGES` は任意です。コンテナ起動時に 1 個以上の TCP bridge を先に立ち上げます。ホスト側サービスが `localhost` 前提のままリクエストを受けたい場合に、`listen_host:listen_port->target_host:target_port` をカンマ区切りで指定してください。

たとえば RubyMine MCP をホスト側で動かしたまま、コンテナ側 Codex から `http://127.0.0.1:64342/stream` を維持したい場合は次のように使えます。

```bash
AGENT_TCP_BRIDGES=127.0.0.1:64342->host.docker.internal:64342
```

複数の bridge を使いたい場合は、`,` 区切りで並べて指定できます。

```bash
AGENT_TCP_BRIDGES=127.0.0.1:64342->host.docker.internal:64342,127.0.0.1:9223->host.docker.internal:9223
```

`agent` はコンテナ内で次のパスを明示的に設定します。

```bash
CODEX_HOME=/home/agent/.agent-stack/.codex
CLAUDE_CONFIG_DIR=/home/agent/.agent-stack/.claude
```

これにより、ホストの `~/.codex` や `~/.claude` と認証情報や設定を分離できます。初回起動時はコンテナ内で一度ログインしてください。Codex は `codex login --device-auth`、Claude Code は `claude` を起動して通常の対話ログインを完了すれば使えます。

## ローカルビルド

```bash
git clone https://github.com/Syati/agent-stack.git
cd agent-stack
docker build -t agent-stack:local -f docker/Dockerfile .
AGENT_STACK_IMAGE=agent-stack:local agent
```

## agent-browser 連携

[agent-browser](https://github.com/vercel-labs/agent-browser) はコンテナにプリインストールされています。ホスト側で Chrome を remote debugging 付きで起動し、コンテナ側から接続してください。

**ホスト側** (`agent chrome` または手動起動):

```bash
agent chrome
```

**コンテナ側** (`chrome-connect` で WebSocket URL を解決して接続):

```bash
chrome-connect
```

`agent chrome` は `~/.agent-stack/.env` の `CHROME_REMOTE_PORT` を読み取り、未設定なら `9222` を使います。Chrome プロファイルは `~/.agent-stack/.chrome-agent` に保存されるので、ブラウザ状態も `agent-stack` 用に分離されます。plugin ランチャーは現状 macOS 専用で、標準の `/Applications/Google Chrome.app/...` パスを前提にしています。

## License

MIT
