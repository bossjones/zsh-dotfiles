# Smoke test container matching CI environment
# Reproduces .github/workflows/smoke.yml locally for faster iteration
#
# Usage:
#   make smoke-build   # Build and run full smoke test
#   make smoke-lint    # Run linting only
#   make smoke-shell   # Interactive shell for debugging
#
FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# Install base dependencies (includes packages from before-00-prereq-ubuntu.sh to avoid permission issues)
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash-completion \
    bc \
    build-essential \
    ca-certificates \
    curl \
    direnv \
    ffmpeg \
    file \
    fzf \
    gawk \
    gettext \
    git \
    gnupg \
    jq \
    libgmp-dev \
    libmediainfo-dev \
    libreadline-dev \
    libssl-dev \
    libyaml-dev \
    locales \
    perl \
    procps \
    software-properties-common \
    sudo \
    tar \
    tmux \
    unzip \
    vim \
    wget \
    zsh \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://raw.githubusercontent.com/kadwanev/retry/master/retry -o /usr/local/bin/retry \
    && chmod +x /usr/local/bin/retry

# Create /.dockerenv marker for scripts that check for Docker environment
RUN touch /.dockerenv

# Set up locale (required for some tools)
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Create test user with sudo access (matches CI runner user setup)
# Use sudoers.d drop-in file for cleaner configuration
RUN useradd -m -s /bin/zsh -G sudo tester && \
    echo "tester ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/tester && \
    chmod 0440 /etc/sudoers.d/tester && \
    visudo -c

# Switch to test user for Homebrew installation
USER tester
ENV HOME=/home/tester
WORKDIR /home/tester

# Install Homebrew (Linux) - requires NONINTERACTIVE for Docker
ENV NONINTERACTIVE=1
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to PATH and verify installation
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
ENV HOMEBREW_NO_AUTO_UPDATE=1
ENV HOMEBREW_NO_ANALYTICS=1

# Verify Homebrew installation and install core tools (matching CI workflow)
RUN /home/linuxbrew/.linuxbrew/bin/brew --version && \
    brew install chezmoi neovim mise go

# Install Python, pre-commit, linting tools, and CI dependencies
# These match packages installed in .github/workflows/tests.yml
RUN brew install python@3.12 pre-commit actionlint && \
    brew install openssl@3 readline libyaml gmp autoconf || true

# Create standard bin directories (matching CI PATH setup)
RUN mkdir -p "$HOME/.bin" "$HOME/bin" "$HOME/.local/bin"

# CI environment variables (matching .github/workflows/tests.yml)
ENV ZSH_DOTFILES_PREP_CI=1
ENV ZSH_DOTFILES_PREP_DEBUG=1
ENV ZSH_DOTFILES_PREP_GITHUB_USER=bossjones
ENV ZSH_DOTFILES_PREP_SKIP_BREW_BUNDLE=1

# Add user bin directories to PATH (matching CI workflow)
ENV PATH="/home/tester/.bin:/home/tester/bin:/home/tester/.local/bin:${PATH}"

# Copy dotfiles source
COPY --chown=tester:tester . /tmp/dotfiles
WORKDIR /tmp/dotfiles

# Default: run full smoke test (lint + build)
CMD ["/tmp/dotfiles/scripts/smoke-test-docker.sh"]
