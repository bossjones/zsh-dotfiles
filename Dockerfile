# syntax=docker/dockerfile:1.4
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
    gcc-12 \
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
# Uses BuildKit secret mount to pass HOMEBREW_GITHUB_API_TOKEN without persisting in image
RUN --mount=type=secret,id=homebrew_token \
    HOMEBREW_GITHUB_API_TOKEN=$(cat /run/secrets/homebrew_token 2>/dev/null || true) \
    /home/linuxbrew/.linuxbrew/bin/brew --version && \
    brew install chezmoi neovim mise go

# Install Python, pre-commit, linting tools, and CI dependencies
# These match packages installed in .github/workflows/tests.yml
# Uses BuildKit secret mount to pass HOMEBREW_GITHUB_API_TOKEN without persisting in image
RUN --mount=type=secret,id=homebrew_token \
    HOMEBREW_GITHUB_API_TOKEN=$(cat /run/secrets/homebrew_token 2>/dev/null || true) \
    brew install python@3.12 pre-commit actionlint && \
    brew install openssl@3 readline libyaml gmp autoconf && \
    brew install rust openssl readline sqlite3 xz zlib tcl-tk pkg-config autogen bash bzip2 libffi cheat python@3.10 cmake \
    curl diff-so-fancy direnv fd gnutls findutils fnm fpp fzf gawk gcc gh git gnu-indent gnu-sed gnu-tar grep gzip \
    hub jq less lesspipe libxml2 lsof luarocks luv moreutils neofetch neovim nnn node tree pyenv pyenv-virtualenv pyenv-virtualenvwrapper \
    ruby-build rbenv ripgrep rsync screen screenfetch shellcheck shfmt unzip urlview vim watch wget zlib zsh openssl@1.1 git-delta \
    tmux && \
    brew tap rbenv/tap && \
    brew install rbenv/tap/openssl@1.1  && \
    brew install gnu-getopt || true

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
