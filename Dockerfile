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
    # Required by Codex
    bubblewrap \
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

# Install mise
ARG MISE_VERSION=2026.4.18
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
    MISE_URL="https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/mise-v${MISE_VERSION}-linux-${MISE_ARCH}"; \
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
ENV PATH="/root/.local/share/mise/shims:${PATH}"
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
# Install Codex
ARG CODEX_VERSION=0.122.0
RUN mise use -g codex@"$CODEX_VERSION"
# Install Go
ARG GO_VERSION=1.25.8
RUN mise use -g go@"$GO_VERSION"
# Install Node
ARG NODE_VERSION=22.22.2
RUN mise use -g node@"$NODE_VERSION"
# Install OpenCode
ARG OPENCODE_VERSION=1.14.28
RUN mise use -g opencode@"$OPENCODE_VERSION"
# Install Python
ARG PYTHON_VERSION=3.12.13
RUN mise use -g python@"$PYTHON_VERSION"
# Install Ruby
ARG RUBY_VERSION=3.4.9
RUN mise settings ruby.compile=false && mise use -g ruby@"$RUBY_VERSION"
# Install usage
ARG USAGE_VERSION=3.2.1
RUN mise use -g usage@"$USAGE_VERSION"
# Install uv
ARG UV_VERSION=0.11.7
RUN mise use -g uv@"$UV_VERSION"

WORKDIR /root

CMD ["zsh"]
