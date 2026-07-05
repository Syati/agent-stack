FROM debian:trixie-slim

ARG RTK_VERSION=0.43.0
ARG CODEX_VERSION=0.143.0-alpha.35
ARG GIT_WT_VERSION=0.29.0
ARG AGENT_BROWSER_VERSION=0.31.1
ARG SHELDON_VERSION=0.8.3
ARG TARGETARCH

ENV LANG=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# System packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    fzf \
    git \
    git-lfs \
    grep \
    jq \
    locales \
    openssh-client \
    ripgrep \
    socat \
    tree \
    unzip \
    zoxide \
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    && sed -i 's/^# *\(C.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI + Docker CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && curl -fsSL https://download.docker.com/linux/debian/gpg \
      -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian trixie stable" \
      > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y --no-install-recommends gh docker-ce-cli docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# starship prompt
RUN curl -fsSL https://starship.rs/install.sh | sh -s -- -y

# sheldon
RUN case "${TARGETARCH}" in \
      amd64) SHELDON_ARCH="x86_64-unknown-linux-musl" ;; \
      arm64) SHELDON_ARCH="aarch64-unknown-linux-musl" ;; \
      *) echo "Unsupported arch: ${TARGETARCH}" && exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/rossmacarthur/sheldon/releases/download/${SHELDON_VERSION}/sheldon-${SHELDON_VERSION}-${SHELDON_ARCH}.tar.gz" \
      -o /tmp/sheldon.tar.gz \
    && tar xzf /tmp/sheldon.tar.gz -C /usr/local/bin sheldon \
    && chmod +x /usr/local/bin/sheldon \
    && rm /tmp/sheldon.tar.gz

# RTK
RUN case "${TARGETARCH}" in \
      amd64) RTK_PKG="rtk_${RTK_VERSION}-1_amd64.deb" ;; \
      arm64) RTK_PKG="rtk-aarch64-unknown-linux-gnu.tar.gz" ;; \
      *) echo "Unsupported arch: ${TARGETARCH}" && exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/rtk-ai/rtk/releases/download/v${RTK_VERSION}/${RTK_PKG}" -o "/tmp/${RTK_PKG}" \
    && if [ "${TARGETARCH}" = "amd64" ]; then \
         dpkg -i "/tmp/${RTK_PKG}"; \
       else \
         tar xzf "/tmp/${RTK_PKG}" -C /usr/local/bin; \
       fi \
    && rm -f "/tmp/${RTK_PKG}"

# agent-browser
RUN case "${TARGETARCH}" in \
      amd64) AB_ARCH="x64" ;; \
      arm64) AB_ARCH="arm64" ;; \
      *) echo "Unsupported arch: ${TARGETARCH}" && exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/vercel-labs/agent-browser/releases/download/v${AGENT_BROWSER_VERSION}/agent-browser-linux-${AB_ARCH}" \
      -o /usr/local/bin/agent-browser \
    && chmod +x /usr/local/bin/agent-browser

# git-wt
RUN curl -fsSL "https://github.com/k1LoW/git-wt/releases/download/v${GIT_WT_VERSION}/git-wt_${GIT_WT_VERSION}-1_${TARGETARCH}.deb" \
      -o /tmp/git-wt.deb \
    && dpkg -i /tmp/git-wt.deb \
    && rm /tmp/git-wt.deb

# Scripts
COPY docker/bin/chrome-connect /usr/local/bin/chrome-connect
COPY docker/bin/agent-entrypoint /usr/local/bin/agent-entrypoint
RUN chmod +x /usr/local/bin/chrome-connect /usr/local/bin/agent-entrypoint

# Non-root user
RUN git config --system --add safe.directory /workspace \
    && useradd -m -s /bin/zsh agent
COPY docker/profile.sh /home/agent/.profile.sh
COPY docker/.zshrc /home/agent/.zshrc
RUN echo '. ~/.profile.sh' >> /home/agent/.bashrc
USER agent
WORKDIR /home/agent

# Pre-seed known_hosts so git over SSH (e.g. git push to GitHub) works
# without an interactive host key prompt.
RUN mkdir -p -m 700 /home/agent/.ssh \
    && ssh-keyscan -H github.com >> /home/agent/.ssh/known_hosts \
    && chmod 600 /home/agent/.ssh/known_hosts

# mise
RUN curl -fsSL https://mise.run | sh
ENV PATH="/home/agent/.local/bin:${PATH}"

# Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash

# entire (AI session capture for git)
RUN curl -fsSL https://entire.io/install.sh | bash

# Codex
RUN case "${TARGETARCH}" in \
      amd64) CODEX_ARCH="x86_64" ;; \
      arm64) CODEX_ARCH="aarch64" ;; \
      *) echo "Unsupported arch: ${TARGETARCH}" && exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/openai/codex/releases/download/rust-v${CODEX_VERSION}/codex-${CODEX_ARCH}-unknown-linux-musl.tar.gz" \
      -o /tmp/codex.tar.gz \
    && tar xzf /tmp/codex.tar.gz -C /home/agent/.local/bin \
    && mv /home/agent/.local/bin/codex-*-unknown-linux-musl /home/agent/.local/bin/codex \
    && rm /tmp/codex.tar.gz

# APM (requires python3)
USER root
RUN apt-get update && apt-get install -y --no-install-recommends python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*
USER agent
RUN pip3 install --user --break-system-packages apm-cli

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/agent-entrypoint"]
CMD ["sleep", "infinity"]
