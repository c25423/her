FROM debian:13.4

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

# Configure mise
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
# Install pi
ARG PI_VERSION=0.84.2
RUN mise use -g pi@"$PI_VERSION"
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
