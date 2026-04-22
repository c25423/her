FROM debian:13.4

ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    # Shell
    zsh \
    # Essentials
    build-essential \
    ca-certificates \
    curl \
    git \
    gnupg \
    openssh-client \
    sudo \
    wget \
    # Utils
    dnsutils \
    lsof \
    jq \
    just \
    openssl \
    ripgrep \
    tree \
    yq \
    && rm -rf /var/lib/apt/lists/*

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
RUN set -eux; \
    if ! grep -qxF 'ZSH_COMPDUMP=$HOME/.zcompdump' /root/.zshrc; then \
        sed -i '1i ZSH_COMPDUMP=$HOME/.zcompdump' /root/.zshrc; \
    fi; \
    rm -f /root/.zcompdump-*
ENV SHELL=/bin/zsh

# Back to bash
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Codex CLI
ARG CODEX_VERSION=0.121.0
ENV CODEX_INSTALL_PATH=/usr/local/bin/codex
RUN apt-get update && apt-get install -y --no-install-recommends \
    bubblewrap \
    && rm -rf /var/lib/apt/lists/*
RUN set -ex; \
    # Determine arch
    if [ -n "$TARGETARCH" ]; then \
        OS_ARCH="$TARGETARCH"; \
    else \
        OS_ARCH=$(uname -m); \
    fi; \
    \
    # Map arch
    case "$OS_ARCH" in \
        amd64|x86_64) \
            CODEX_ARCH="x86_64" ;; \
        arm64|aarch64) \
            CODEX_ARCH="aarch64" ;; \
        *) \
            echo "ERROR: Unsupported architecture: $OS_ARCH."; \
            exit 1 ;; \
    esac; \
    \
    # Install
    CODEX_URL="https://github.com/openai/codex/releases/download/rust-v${CODEX_VERSION}/codex-${CODEX_ARCH}-unknown-linux-musl.tar.gz"; \
    CODEX_BINARY="codex-${CODEX_ARCH}-unknown-linux-musl"; \
    CODEX_TMP_DIR="$(mktemp -d)"; \
    echo "Installing Codex CLI for $OS_ARCH (Target: $CODEX_ARCH) from $CODEX_URL"; \
    curl -fsSL "$CODEX_URL" -o "$CODEX_TMP_DIR/codex.tar.gz" \
    && tar -xzf "$CODEX_TMP_DIR/codex.tar.gz" -C "$CODEX_TMP_DIR" \
    && install -m 0755 "$CODEX_TMP_DIR/$CODEX_BINARY" "$CODEX_INSTALL_PATH" \
    && rm -rf "$CODEX_TMP_DIR"

# Install OpenCode
ARG OPENCODE_VERSION=1.14.20
ARG OPENCODE_INSTALL_PATH=/usr/local/bin/opencode
RUN set -ex; \
    # Determine arch
    if [ -n "$TARGETARCH" ]; then \
        OS_ARCH="$TARGETARCH"; \
    else \
        OS_ARCH=$(uname -m); \
    fi; \
    \
    # Map arch
    case "$OS_ARCH" in \
        amd64|x86_64) \
            OPENCODE_ARCH="x64" ;; \
        arm64|aarch64) \
            OPENCODE_ARCH="arm64" ;; \
        *) \
            echo "ERROR: Unsupported architecture: $OS_ARCH."; \
            exit 1 ;; \
    esac; \
    \
    # Install
    OPENCODE_URL="https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/opencode-linux-${OPENCODE_ARCH}.tar.gz"; \
    OPENCODE_BINARY="opencode"; \
    OPENCODE_TMP_DIR="$(mktemp -d)"; \
    echo "Installing OpenCode for $OS_ARCH (Target: $OPENCODE_ARCH) from $OPENCODE_URL"; \
    curl -fsSL "$OPENCODE_URL" -o "$OPENCODE_TMP_DIR/opencode.tar.gz" \
    && tar -xzf "$OPENCODE_TMP_DIR/opencode.tar.gz" -C "$OPENCODE_TMP_DIR" \
    && install -m 0755 "$OPENCODE_TMP_DIR/$OPENCODE_BINARY" "$OPENCODE_INSTALL_PATH" \
    && rm -rf "$OPENCODE_TMP_DIR"

# Install mise
ARG MISE_VERSION=v2026.4.15
ENV MISE_INSTALL_PATH=/usr/local/bin/mise
RUN set -ex; \
    # Determine arch
    if [ -n "$TARGETARCH" ]; then \
        OS_ARCH="$TARGETARCH"; \
    else \
        OS_ARCH=$(uname -m); \
    fi; \
    # Map arch
    case "$OS_ARCH" in \
        amd64|x86_64) \
            MISE_ARCH="x64" ;; \
        arm64|aarch64) \
            MISE_ARCH="arm64" ;; \
        *) \
            echo "ERROR: Unsupported architecture: $OS_ARCH."; \
            exit 1 ;; \
    esac; \
    # Install
    MISE_URL="https://github.com/jdx/mise/releases/download/${MISE_VERSION}/mise-${MISE_VERSION}-linux-${MISE_ARCH}"; \
    MISE_TMP_DIR="$(mktemp -d)"; \
    echo "Installing mise for $OS_ARCH (Target: $MISE_ARCH) from $MISE_URL"; \
    curl -fsSL "$MISE_URL" -o "$MISE_TMP_DIR/mise"; \
    install -m 0755 "$MISE_TMP_DIR/mise" "$MISE_INSTALL_PATH"; \
    rm -rf "$MISE_TMP_DIR"
# https://mise.jdx.dev/dev-tools/shims.html#how-to-add-mise-shims-to-path
RUN set -eux; \
    # bash
    touch /root/.bash_profile /root/.bashrc; \
    if ! grep -qxF 'eval "$(mise activate bash --shims)"' /root/.bash_profile; then \
        printf '%s\n' 'eval "$(mise activate bash --shims)"' >> /root/.bash_profile; \
    fi; \
    if ! grep -qxF 'eval "$(mise activate bash)"' /root/.bashrc; then \
        printf '%s\n' 'eval "$(mise activate bash)"' >> /root/.bashrc; \
    fi; \
    # zsh
    touch /root/.zprofile /root/.zshrc; \
    if ! grep -qxF 'eval "$(mise activate zsh --shims)"' /root/.zprofile; then \
        printf '%s\n' 'eval "$(mise activate zsh --shims)"' >> /root/.zprofile; \
    fi; \
    if ! grep -qxF 'eval "$(mise activate zsh)"' /root/.zshrc; then \
        printf '%s\n' 'eval "$(mise activate zsh)"' >> /root/.zshrc; \
    fi
# https://mise.jdx.dev/installing-mise.html#autocompletion
RUN if grep -q '^plugins=(' /root/.zshrc; then \
      grep -qE '^plugins=\(.*\bmise\b.*\)' /root/.zshrc || \
      sed -i 's/^plugins=(\(.*\))/plugins=(\1 mise)/' /root/.zshrc; \
    else \
      printf '\nplugins=(mise)\n' >> /root/.zshrc; \
    fi

# Install Bun
ARG BUN_VERSION=1.3.11
RUN mise use -g bun@"$BUN_VERSION"

# Install Go
ARG GO_VERSION=1.25.8
RUN mise use -g go@"$GO_VERSION"

# Install Node
ARG NODE_VERSION=22.22.2
RUN mise use -g node@"$NODE_VERSION"

# Install Python
ARG PYTHON_VERSION=3.12.13
RUN mise use -g python@"$PYTHON_VERSION"

# Install Ruby
ARG RUBY_VERSION=3.4.9
RUN mise settings ruby.compile=false && mise use -g ruby@"$RUBY_VERSION"

# Install uv
ARG UV_VERSION=0.11.7
RUN mise use -g uv@"$UV_VERSION"

WORKDIR /root

CMD ["zsh"]
