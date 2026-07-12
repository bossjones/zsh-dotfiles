#!/usr/bin/env bash
# Smoke test script for Docker container or host environment
# Reproduces .github/workflows/tests.yml locally
#
# Usage:
#   ./scripts/smoke-test-docker.sh                       # Run all stages (asdf default)
#   ./scripts/smoke-test-docker.sh lint                  # Run lint stage only
#   ./scripts/smoke-test-docker.sh build                 # Run build stage only
#   ./scripts/smoke-test-docker.sh provision             # Build w/o pytest (used by Dockerfile.full)
#   VERSION_MANAGER=mise ./scripts/smoke-test-docker.sh build   # Build with mise
#   ./scripts/smoke-test-docker.sh build mise            # Same, via positional arg
#
set -euo pipefail

# Colors for output
BLUE='\033[34m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

# Parse command line arguments
STAGE="${1:-all}"
VERSION_MANAGER="${2:-${VERSION_MANAGER:-asdf}}"
case "$VERSION_MANAGER" in
    asdf|mise) ;;
    *)
        echo "❌ VERSION_MANAGER must be 'asdf' or 'mise', got: $VERSION_MANAGER" >&2
        exit 1
        ;;
esac
export VERSION_MANAGER

# Avoid Homebrew's interactive "ask mode" confirmation for brew install below
export HOMEBREW_NO_ASK=1

log_info() { echo -e "${BLUE}ℹ️  $1${RESET}"; }
log_success() { echo -e "${GREEN}✅ $1${RESET}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${RESET}"; }
log_error() { echo -e "${RED}❌ $1${RESET}"; }
log_section() { echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; echo -e "${BLUE}📋 $1${RESET}"; echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"; }

# Setup initial environment variables (mirrors CI env vars)
setup_initial_environment() {
    log_section "Initial Environment Setup"

    # CI-compatible environment variables
    export ZSH_DOTFILES_PREP_CI=1
    export ZSH_DOTFILES_PREP_DEBUG=1
    export ZSH_DOTFILES_PREP_GITHUB_USER=bossjones
    export ZSH_DOTFILES_PREP_SKIP_BREW_BUNDLE=1

    # SHELDON configuration
    export SHELDON_CONFIG_DIR="$HOME/.sheldon"
    export SHELDON_DATA_DIR="$HOME/.sheldon"

    # Initial PATH modifications
    export PATH="${HOME}/.bin:${HOME}/bin:${HOME}/.local/bin:${PATH}"

    log_info "ZSH_DOTFILES_PREP_CI=$ZSH_DOTFILES_PREP_CI"
    log_info "ZSH_DOTFILES_PREP_DEBUG=$ZSH_DOTFILES_PREP_DEBUG"
    log_info "ZSH_DOTFILES_PREP_GITHUB_USER=$ZSH_DOTFILES_PREP_GITHUB_USER"
    log_info "ZSH_DOTFILES_PREP_SKIP_BREW_BUNDLE=$ZSH_DOTFILES_PREP_SKIP_BREW_BUNDLE"
    log_info "SHELDON_CONFIG_DIR=$SHELDON_CONFIG_DIR"
    log_info "SHELDON_DATA_DIR=$SHELDON_DATA_DIR"
    log_info "VERSION_MANAGER=$VERSION_MANAGER"

    log_success "Initial environment configured"
}

# Check and install dependencies
ensure_dependencies() {
    log_section "Dependency Check"

    # Ensure ~/.local/bin is in PATH for all tool installations
    # Set once at the start to avoid redundant PATH modifications
    export PATH="$HOME/.local/bin:$PATH"

    # Check for pre-commit
    if ! command -v pre-commit &> /dev/null; then
        log_warning "pre-commit not found, attempting to install..."
        # Check for uv first (uvx is just an alias for 'uv tool run')
        if command -v uv &> /dev/null; then
            log_info "Installing pre-commit via uv..."
            uv tool install pre-commit
        elif command -v pip3 &> /dev/null; then
            log_info "Installing pre-commit via pip3..."
            pip3 install --user pre-commit
        elif command -v pip &> /dev/null; then
            log_info "Installing pre-commit via pip..."
            pip install --user pre-commit
        else
            log_error "Cannot install pre-commit: no suitable package manager found"
            log_info "Please install pre-commit manually: pip install pre-commit"
            return 1
        fi
        # Verify installation
        if command -v pre-commit &> /dev/null; then
            log_success "pre-commit installed successfully"
        else
            log_error "pre-commit installation failed"
            return 1
        fi
    else
        log_success "pre-commit found: $(pre-commit --version)"
    fi

    # Check for chezmoi
    if ! command -v chezmoi &> /dev/null; then
        log_warning "chezmoi not found, attempting to install..."
        if command -v brew &> /dev/null; then
            log_info "Installing chezmoi via brew..."
            brew install chezmoi
        else
            log_info "Installing chezmoi via official installer..."
            sh -c "$(curl -fsSL https://www.chezmoi.io/get)" -- -b "$HOME/.local/bin"
        fi
        # Verify installation
        if command -v chezmoi &> /dev/null; then
            log_success "chezmoi installed successfully"
        else
            log_error "chezmoi installation failed"
            return 1
        fi
    else
        log_success "chezmoi found: $(chezmoi --version)"
    fi

    log_success "All dependencies satisfied"
}

# Setup Homebrew packages (mirrors CI brew install steps)
setup_brew_packages() {
    log_section "Homebrew Setup"

    if ! command -v brew &> /dev/null; then
        log_warning "Homebrew not installed, skipping brew setup"
        return 0
    fi

    log_info "Adding brew taps..."
    brew tap schniz/tap || true

    log_info "Installing initial packages..."
    brew install wget curl kadwanev/brew/retry go || true
    brew install openssl@3 readline libyaml gmp autoconf tmux || true

    log_info "Installing development tools..."
    brew install openssl readline sqlite3 xz zlib tcl-tk pkg-config autogen bash bzip2 libffi cheat python@3.10 || true
    brew install cmake || true
    brew install curl diff-so-fancy direnv fd gnutls findutils fnm fpp fzf gawk gcc gh git gnu-indent gnu-sed gnu-tar grep gzip || true
    brew install hub jq less lesspipe libxml2 lsof luarocks luv moreutils fastfetch neovim nnn node tree pyenv pyenv-virtualenv pyenv-virtualenvwrapper || true
    brew install ruby-build rbenv ripgrep rsync screen screenfetch shellcheck shfmt unzip urlview vim watch wget zlib zsh openssl@1.1 git-delta || true
    brew install tmux || true

    log_info "Installing OpenSSL and Ruby build dependencies..."
    brew install openssl@3 readline libyaml gmp autoconf || true
    brew tap rbenv/tap || true
    brew install rbenv/tap/openssl@1.1 || true
    brew install gnu-getopt || true

    log_info "Installing rust via rustup script..."
    curl --proto '=https' --tlsv1.2 https://sh.rustup.rs >rustup.sh
    cat rustup.sh
    chmod +x rustup.sh
    ./rustup.sh -y -q --no-modify-path && rm rustup.sh

    log_success "Brew packages installed"
}

# Ensure SUDO_ASKPASS is set and the askpass script exists before invoking
# zsh-dotfiles-prereq-installer. The Dockerfile creates it primarily; this is a
# safety net for the moment of need + a diagnostic so we can tell whether the
# file is missing or NOPASSWD just isn't applying.
ensure_sudo_askpass() {
    local askpass="${SUDO_ASKPASS:-$HOME/.sudo_askpass}"

    log_info "id: $(id)"
    log_info "SUDO_ASKPASS=$askpass"
    if [[ -e "$askpass" ]]; then
        log_info "askpass present: $(ls -la "$askpass")"
    else
        log_warning "askpass MISSING at $askpass — recreating"
    fi

    printf '#!/bin/sh\necho ""\n' > "$askpass"
    chmod 700 "$askpass"
    export SUDO_ASKPASS="$askpass"

    local sudo_rules
    sudo_rules="$(sudo -n -ln 2>&1 || true)"
    log_info "sudo -ln: ${sudo_rules}"
    if ! grep -q "NOPASSWD: ALL" <<<"$sudo_rules"; then
        log_warning "NOPASSWD: ALL not present in sudo -ln output — prereq-installer may hang or fail"
    fi
}

# Run the zsh-dotfiles-prereq-installer (mirrors CI prereq step)
run_prereq_installer() {
    log_section "Prerequisites Installer"

    ensure_sudo_askpass

    log_info "Downloading zsh-dotfiles-prereq-installer..."
    wget https://raw.githubusercontent.com/bossjones/zsh-dotfiles-prep/main/bin/zsh-dotfiles-prereq-installer
    chmod +x zsh-dotfiles-prereq-installer

    log_info "Running prereq installer with retry..."
    # `Defaults:tester !authenticate` in /etc/sudoers.d/tester makes
    # `sudo --askpass --validate` succeed without invoking the askpass helper,
    # so the installer's sudo_refresh works whether or not SUDO_ASKPASS is set
    # and whether or not a TTY is attached.
    if command -v retry &> /dev/null; then
        retry -t 4 -- ./zsh-dotfiles-prereq-installer --debug
    else
        ./zsh-dotfiles-prereq-installer --debug
    fi

    # Cleanup
    rm -f zsh-dotfiles-prereq-installer

    log_success "Prerequisites installed"
}

# Setup version manager (asdf or mise) and OpenSSL (called right before chezmoi).
# Mutual Exclusion Invariant (specs/migrate-asdf-to-mise.md lines 15-27): when
# VERSION_MANAGER=mise, NEVER source asdf.sh or set ASDF_DIR; symmetrically for asdf.
setup_version_manager() {
    log_section "Version Manager Setup ($VERSION_MANAGER)"

    # Shared: GNU getopt + OpenSSL 3 flags for Ruby compilation (apply to both managers)
    OPENSSL3_PREFIX=""
    if command -v brew &> /dev/null; then
        GNUGETOPT_BIN="$(brew --prefix gnu-getopt 2>/dev/null)/bin" || true
        if [[ -d "$GNUGETOPT_BIN" ]]; then
            export PATH="${GNUGETOPT_BIN}:${PATH}"
            log_info "GNU getopt added to PATH: $GNUGETOPT_BIN"
        fi

        OPENSSL3_PREFIX="$(brew --prefix openssl@3 2>/dev/null)" || true
        if [[ -n "$OPENSSL3_PREFIX" ]]; then
            export LDFLAGS="-L${OPENSSL3_PREFIX}/lib"
            export CPPFLAGS="-I${OPENSSL3_PREFIX}/include"
            log_info "OpenSSL 3 flags set: LDFLAGS=$LDFLAGS"
        fi
    fi

    if [[ "$VERSION_MANAGER" == "asdf" ]]; then
        export ASDF_DIR="${HOME}/.asdf"
        export ASDF_COMPLETIONS="$ASDF_DIR/completions"

        if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
            log_info "Sourcing asdf..."
            # shellcheck source=/dev/null
            . "$HOME/.asdf/asdf.sh"
        fi

        export PATH="${HOME}/.asdf/bin:${HOME}/.asdf/shims:${PATH}"

        if command -v asdf &> /dev/null && [[ -n "$OPENSSL3_PREFIX" ]]; then
            log_info "Installing Ruby 4.0.1 via asdf with OpenSSL 3..."
            asdf install ruby 4.0.1 -- --with-openssl-dir="${OPENSSL3_PREFIX}" || true
        fi

        log_info "ASDF_DIR=$ASDF_DIR"
        log_info "ASDF_COMPLETIONS=$ASDF_COMPLETIONS"
    else
        # mise lane — never source asdf.sh, never set ASDF_DIR (Mutual Exclusion Invariant)
        if command -v mise &> /dev/null; then
            log_info "Activating mise..."
            eval "$(mise activate bash)"

            log_info "Installing Ruby 4.0.1 via mise..."
            if [[ -n "$OPENSSL3_PREFIX" ]]; then
                RUBY_CONFIGURE_OPTS="--with-openssl-dir=${OPENSSL3_PREFIX}" \
                    mise use -g ruby@4.0.1 || true
            else
                mise use -g ruby@4.0.1 || true
            fi
        else
            log_warning "mise not found on PATH — skipping ruby install"
        fi
    fi

    log_success "Version manager configured: $VERSION_MANAGER"
}

# Stage: Lint
run_lint() {
    log_section "Stage: LINT"

    log_info "Running pre-commit hooks..."
    if pre-commit run --all-files; then
        log_success "pre-commit passed"
    else
        log_error "pre-commit failed"
        return 1
    fi

    # Initialize chezmoi to generate config from template
    # This processes .chezmoi.yaml.tmpl and makes data variables available
    log_info "Initializing chezmoi config (version_manager=$VERSION_MANAGER)..."
    if chezmoi init --source=. --force \
        --promptString version_manager="$VERSION_MANAGER" 2>&1; then
        log_success "chezmoi config initialized"
    else
        log_warning "chezmoi init had warnings (non-fatal)"
    fi

    # Validate source directory and templates
    # Note: chezmoi verify checks destination=target, which fails before apply.
    # Instead, use chezmoi diff to validate templates parse correctly.
    # diff returns exit 1 when there are differences (expected), so check stderr for errors.
    log_info "Running chezmoi diff (validates templates)..."
    local diff_errors
    diff_errors=$(chezmoi diff --source=. 2>&1 >/dev/null) || true
    if [[ -z "$diff_errors" ]]; then
        log_success "chezmoi templates validated"
    else
        log_error "chezmoi template validation failed"
        echo "$diff_errors"
        return 1
    fi

    log_success "Lint stage completed"
}

# Stage: Build
run_build() {
    log_section "Stage: BUILD"

    # Health checks
    log_info "Running environment health checks..."

    if command -v brew &> /dev/null; then
        log_info "Homebrew doctor..."
        if brew doctor 2>&1; then
            log_success "Homebrew is healthy"
        else
            log_warning "Homebrew has warnings (non-fatal)"
        fi
    else
        log_warning "Homebrew not installed, skipping brew doctor"
    fi

    if command -v mise &> /dev/null; then
        log_info "mise doctor..."
        if mise doctor 2>&1; then
            log_success "mise is healthy"
        else
            log_warning "mise has warnings"
        fi
    fi

    # Run chezmoi init with retry (like CI does)
    log_info "Running chezmoi init with retry..."
    local chezmoi_bin="${HOME}/.bin/chezmoi"
    if [[ ! -x "$chezmoi_bin" ]]; then
        chezmoi_bin="$(command -v chezmoi)"
    fi

    local chezmoi_exit_code=0
    if command -v retry &> /dev/null; then
        retry -t 4 -- "$chezmoi_bin" init -R --debug -v --apply --force \
            --promptString version_manager="$VERSION_MANAGER" --source=. || chezmoi_exit_code=$?
    else
        "$chezmoi_bin" init -R --debug -v --apply --force \
            --promptString version_manager="$VERSION_MANAGER" --source=. || chezmoi_exit_code=$?
    fi

    if [[ $chezmoi_exit_code -eq 0 ]]; then
        log_success "chezmoi init/apply succeeded"
    else
        log_error "chezmoi init/apply failed"
        return 1
    fi

    # Run post-install-chezmoi with retry
    log_info "Running post-install-chezmoi..."
    if command -v post-install-chezmoi &> /dev/null; then
        if command -v retry &> /dev/null; then
            retry -t 4 -- post-install-chezmoi || log_warning "post-install-chezmoi had warnings"
        else
            post-install-chezmoi || log_warning "post-install-chezmoi had warnings"
        fi
    else
        log_warning "post-install-chezmoi not found, skipping"
    fi

    # Test zsh initialization (if zsh is available)
    if command -v zsh &> /dev/null; then
        log_info "Testing zsh shell initialization..."
        if timeout 10s zsh -c "
            source ~/.zshrc
            if [[ -n \"\$ZSH_VERSION\" ]]; then
                echo '✅ zsh configuration loaded successfully'
            else
                echo '❌ zsh configuration failed to load'
                exit 1
            fi
            if [[ -n \"\$PROMPT\" ]] || [[ -n \"\$PS1\" ]]; then
                echo '✅ zsh prompt configured'
            else
                echo '❌ zsh prompt not configured'
                exit 1
            fi
        "; then
            log_success "zsh initialization test passed"
        else
            log_error "zsh initialization test failed"
            return 1
        fi
    else
        log_warning "zsh not installed, skipping shell initialization test"
    fi

    log_success "Build stage completed"
}

# Stage: Test (run pytest)
run_pytest() {
    log_section "Running Tests"

    log_info "Creating Python virtual environment..."
    python3 -m venv venv
    # shellcheck source=/dev/null
    source ./venv/bin/activate

    log_info "Installing test dependencies..."
    pip install -U pip setuptools wheel
    pip install -U -r requirements-test.txt

    log_info "Running pytest..."
    if pytest; then
        log_success "Tests passed"
    else
        log_error "Tests failed"
        deactivate
        return 1
    fi

    deactivate
    log_success "Test stage completed"
}

# Main execution
main() {
    log_section "Smoke Test Runner"
    log_info "Stage: ${STAGE}"
    log_info "Version manager: ${VERSION_MANAGER}"
    log_info "Working directory: $(pwd)"

    # 1. Setup initial environment (ZSH_DOTFILES_PREP_*, SHELDON_*, basic PATH)
    setup_initial_environment

    # 2. Ensure basic tools (pre-commit, chezmoi)
    ensure_dependencies

    case "$STAGE" in
        lint)
            run_lint
            ;;
        build)
            # 3. Install brew packages
            setup_brew_packages
            # 4. Run prereq installer
            run_prereq_installer
            # 5. Setup version manager + OpenSSL (right before chezmoi)
            setup_version_manager
            # 6. Run build (chezmoi init/apply + post-install)
            run_build
            # 7. Run tests
            run_pytest
            ;;
        provision)
            # Same as `build` but skips run_pytest. Used by Dockerfile.full
            # to bake chezmoi-applied home + post-install state into a layer.
            setup_brew_packages
            run_prereq_installer
            setup_version_manager
            run_build
            ;;
        all)
            run_lint
            setup_brew_packages
            run_prereq_installer
            setup_version_manager
            run_build
            run_pytest
            ;;
        *)
            log_error "Unknown stage: $STAGE"
            log_info "Usage: $0 [lint|build|provision|all]"
            exit 1
            ;;
    esac

    log_section "Smoke Test Complete"
    log_success "All stages passed!"
}

main "$@"
