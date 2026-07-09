# agent-stack

[English README](README.md)

## 前提条件

- macOS + Docker バックエンドとして [Colima](https://github.com/abiosoft/colima) が起動していること。shell launcher は SSH agent socket の解決や起動確認のために `colima ssh` / `colima status` を呼び出すため、Docker Desktop など他のバックエンドは標準ではサポートしていません。
- Colima は次の設定にしてください。

  ```yaml
  vmType: vz
  mountType: virtiofs
  forwardAgent: true
  ```

  `mountType` が `sshfs` のままだと、マウントした workspace 上で `entire` がハングすることがあります。

[Claude Code](https://claude.ai/code), [Codex](https://github.com/openai/codex), [RTK](https://github.com/rtk-ai/rtk), [mise](https://mise.jdx.dev/), [APM](https://github.com/microsoft/apm), [entire](https://entire.io), [git-wt](https://github.com/k1LoW/git-wt) などをプリインストールした、AI エージェント開発向けコンテナです。

## 概要

- プロジェクトのディレクトリで `agent` を実行すると、そのままコンテナに入れます。
- コンテナからホスト Docker を操作したいときだけ `agent --docker` を使います。
- コンテナ専用の設定や認証情報は `~/.agent-stack` に分離して保持します。

## クイックスタート

まず `~/.zshrc` で plugin を読み込みます。

```bash
source /path/to/agent-stack/agent-stack.plugin.zsh
```

その後、現在のディレクトリをマウントしてコンテナを起動します。

```bash
agent
```

- `agent` は現在のディレクトリをホストと同じ絶対パスに bind mount し、さらに `-w "$(pwd)"` でそのパスを作業ディレクトリにします。
- これは `agent --docker` でホストの Docker socket を渡したときに、コンテナ内で実行した `docker run` や `docker build` でも、bind mount と build context のパス解決が最終的にホスト側 Docker daemon で行われるためです。
- コンテナ内のパスがホストとずれると、存在しないパスを参照したり、誤った build context を使ったりします。

必要なら対話シェルではなくコマンドを直接渡せます。

```bash
agent codex
agent claude
agent zsh -lc 'uname -a'
```

## 実行時の挙動

- `agent --docker` は `/var/run/docker.sock` をマウントし、コンテナからホスト Docker を操作可能にします。
- デフォルトでは Docker socket はマウントしません。必要なときだけ `agent --docker` を使ってください。
- launcher は `colima ssh` で Colima VM 内の `SSH_AUTH_SOCK` を解決し、その forwarded socket をコンテナへマウントします。
- 複数インスタンスを並行起動できます。同じリポジトリを複数エージェントで触る場合は [git-wt](https://github.com/k1LoW/git-wt) の worktree を使うのが安全です。

## 永続化されるデータ

- `~/.agent-stack` にコンテナ専用の設定と認証状態を保持します。
- `~/.agent-stack/.codex` は `CODEX_HOME` として使います。
- `~/.agent-stack/.claude` は `CLAUDE_CONFIG_DIR` として使います。
- `~/.agent-stack/.mise` に `mise` のグローバル設定と state を置きます。
- `agent-mise-data` で `/home/agent/.local/share/mise` 配下の `mise` インストール実体をコンテナ再作成後も保持します。
- ホストの `~/.gitconfig` は read-only でマウントされ、コンテナ内でも `git commit` や `git push` を使えます。

初回実行時には次のパスを自動作成します。

```text
~/.agent-stack/.env
~/.agent-stack/.claude
~/.agent-stack/.codex
~/.agent-stack/.chrome-agent
~/.agent-stack/.mise/state
~/.agent-stack/.sheldon/plugins.toml
```

初回起動後はコンテナ内で一度ログインしてください。

- Codex: `codex login --device-auth`
- Claude Code: `claude` を起動して通常の対話ログインを完了

プリインストール済みの [sheldon](https://github.com/rossmacarthur/sheldon) を使うと、追加の shell plugin を `~/.agent-stack/.sheldon/plugins.toml` でユーザー側から管理できます。たとえば:

```toml
shell = "zsh"

[plugins.entire-fzf]
github = "Syati/entire-fzf"
```

## コンテナユーザー

非 root ユーザー `agent` で動作します。ホームディレクトリは `/home/agent`、シェルは `zsh` です。イメージのデフォルト作業ディレクトリは `/workspace` ですが、`agent` launcher 経由では実行時に現在のディレクトリ (`$(pwd)`) を作業ディレクトリとして使います。

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
MISE_GLOBAL_CONFIG_FILE=/home/agent/.agent-stack/.mise/config.toml
MISE_STATE_DIR=/home/agent/.agent-stack/.mise/state
```

これにより、ホスト側の dotfiles から認証情報や設定を分離しつつ、`mise use -g ...` の結果も `agent-stack` 側に永続化できます。実際のツール実体は Docker named volume として `/home/agent/.local/share/mise` に残ります。初回起動時はコンテナ内で一度ログインしてください。Codex は `codex login --device-auth`、Claude Code は `claude` を起動して通常の対話ログインを完了すれば使えます。

## ローカルビルド

```bash
git clone https://github.com/Syati/agent-stack.git
cd agent-stack
make build
AGENT_STACK_IMAGE=agent-stack:local agent
```

タグや Dockerfile を変えたい場合は Make 変数を上書きしてください。たとえば `make build IMAGE=agent-stack:dev` や `make build DOCKERFILE=docker/Dockerfile` のように使えます。

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
