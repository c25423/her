FROM debian:13.4

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bubblewrap \
    build-essential \
    ca-certificates \
    curl \
    dnsutils \
    git \
    gnupg \
    jq \
    just \
    lsof \
    openssh-client \
    openssl \
    ripgrep \
    sudo \
    tree \
    wget \
    yq \
    zsh \
    # Install q from the natesales APT repository
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://repo.natesales.net/apt/gpg.key -o /tmp/natesales.key \
    && gpg --dearmor -o /etc/apt/keyrings/natesales.gpg /tmp/natesales.key \
    && rm /tmp/natesales.key \
    && echo "deb [signed-by=/etc/apt/keyrings/natesales.gpg] https://repo.natesales.net/apt * *" > /etc/apt/sources.list.d/natesales.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends q \
    # Install mise from the mise repository enabled with extrepo
    && apt-get install -y --no-install-recommends extrepo \
    && extrepo enable mise \
    && apt-get update \
    && apt-get install -y --no-install-recommends mise \
    # Cleanup
    && rm -rf /var/lib/apt/lists/*

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
RUN set -eux; \
    if ! grep -qxF 'ZSH_COMPDUMP=$HOME/.zcompdump' /root/.zshrc; then \
        sed -i '1i ZSH_COMPDUMP=$HOME/.zcompdump' /root/.zshrc; \
    fi; \
    rm -f /root/.zcompdump-*
ENV SHELL=/bin/zsh

# Use zsh for subsequent RUN commands
SHELL ["/bin/zsh", "-e", "-o", "pipefail", "-c"]

RUN set -eux; \
    # Setup mise autocompletion https://mise.jdx.dev/getting-started.html#autocompletion
    mise completion bash --install; \
    mise completion zsh --install; \
    # Add mise shims to path https://mise.jdx.dev/dev-tools/shims.html#how-to-add-mise-shims-to-path
    echo 'eval "$(mise activate bash)"' >> /root/.profile; \
    echo 'eval "$(mise activate zsh)"' >> /root/.zprofile

# Install Bun
ARG BUN_VERSION=1.3.14
RUN mise use -g bun@"$BUN_VERSION"
# Install Claude Code
ARG CLAUDE_CODE_VERSION=2.1.233
RUN mise use -g claude-code@"$CLAUDE_CODE_VERSION"
# Install Codex
ARG CODEX_VERSION=0.147.0
RUN mise use -g codex@"$CODEX_VERSION"
# Install Go
ARG GO_VERSION=1.25.8
RUN mise use -g go@"$GO_VERSION"
# Install Node
ARG NODE_VERSION=22.22.2
RUN mise use -g node@"$NODE_VERSION"
# Install Nub
ARG NUB_VERSION=0.8.3
RUN mise use -g nub@"$NUB_VERSION"
# Install pi
ARG PI_VERSION=0.84.2
RUN mise use -g pi@"$PI_VERSION"
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
