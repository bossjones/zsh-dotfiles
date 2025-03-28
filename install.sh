#!/bin/sh
# install.sh - POSIX-compliant installation script for zsh-dotfiles
# This script mimics the functionality in the GitHub Actions workflow
#
# Usage:
#   1. Make this script executable: chmod +x install.sh
#   2. Run the script: ./install.sh
#   3. Or pipe directly to sh:
#      curl -fsSL https://raw.githubusercontent.com/bossjones/zsh-dotfiles/main/install.sh | sh
#
#   Environment variables you can set:
#   - ZSH_DOTFILES_PREP_GITHUB_USER: GitHub username (default: bossjones)
#   - ZSH_DOTFILES_PREP_SKIP_BREW_BUNDLE: Skip brew bundle (default: 1)
#   - ZSH_DOTFILES_PREP_DEBUG: Enable debug output (default: 1)
#   - ZSH_DOTFILES_SKIP_LUNARVIM: Skip LunarVim installation (default: 0)
#   - ZSH_DOTFILES_SKIP_TESTS: Skip running tests (default: 0)
#
#   Example with environment variables:
#   curl -fsSL https://raw.githubusercontent.com/bossjones/zsh-dotfiles/main/install.sh | \
#   ZSH_DOTFILES_PREP_GITHUB_USER=yourusername ZSH_DOTFILES_SKIP_LUNARVIM=1 sh

# CHECKLIST:
# [x] Set up environment variables
# [x] Install required brew packages (wget, curl, retry, go, trash)
# [x] Set up PATH to include user bin directories
# [x] Download and run zsh-dotfiles-prereq-installer
# [x] Run chezmoi init and apply
# [x] Run post-install-chezmoi
# [x] Install LunarVim (optional)
# [x] Run tests
# [x] Make compatible with curl piping to sh
#   [x] Handle script downloading itself
#   [x] Ensure proper error handling for piped execution
#   [x] Handle lack of terminal interactivity
#   [x] Ensure proper directory detection
#   [x] Support environment variables passed through curl

# Exit on error
set -e

# Print commands before executing them (for debugging)
# set -x

echo "Starting zsh-dotfiles installation..."

# Detect if we're being piped to sh
is_piped_execution() {
    # Check if stdin is a terminal
    if [ -t 0 ]; then
        return 1  # Not piped
    else
        return 0  # Piped
    fi
}

# Set up environment variables with defaults
ZSH_DOTFILES_PREP_DEBUG=${ZSH_DOTFILES_PREP_DEBUG:-1}
ZSH_DOTFILES_PREP_GITHUB_USER=${ZSH_DOTFILES_PREP_GITHUB_USER:-"bossjones"}
ZSH_DOTFILES_PREP_SKIP_BREW_BUNDLE=${ZSH_DOTFILES_PREP_SKIP_BREW_BUNDLE:-1}
ZSH_DOTFILES_SKIP_LUNARVIM=${ZSH_DOTFILES_SKIP_LUNARVIM:-0}
ZSH_DOTFILES_SKIP_TESTS=${ZSH_DOTFILES_SKIP_TESTS:-0}

# Check if running in CI environment
if [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ]; then
    ZSH_DOTFILES_PREP_CI=1
    echo "Running in CI environment"
else
    ZSH_DOTFILES_PREP_CI=0
    echo "Running in local environment"
fi

# If being piped, set non-interactive mode
if is_piped_execution; then
    echo "Detected piped execution (curl | sh), setting non-interactive mode"
    ZSH_DOTFILES_NONINTERACTIVE=1
else
    ZSH_DOTFILES_NONINTERACTIVE=0
fi

export ZSH_DOTFILES_PREP_DEBUG
export ZSH_DOTFILES_PREP_GITHUB_USER
export ZSH_DOTFILES_PREP_SKIP_BREW_BUNDLE
export ZSH_DOTFILES_PREP_CI
export ZSH_DOTFILES_NONINTERACTIVE
export ZSH_DOTFILES_SKIP_LUNARVIM
export ZSH_DOTFILES_SKIP_TESTS

# Display configuration
echo "Configuration:"
echo "- GitHub User: $ZSH_DOTFILES_PREP_GITHUB_USER"
echo "- Skip Brew Bundle: $ZSH_DOTFILES_PREP_SKIP_BREW_BUNDLE"
echo "- Debug Mode: $ZSH_DOTFILES_PREP_DEBUG"
echo "- CI Mode: $ZSH_DOTFILES_PREP_CI"
echo "- Non-interactive Mode: $ZSH_DOTFILES_NONINTERACTIVE"
echo "- Skip LunarVim: $ZSH_DOTFILES_SKIP_LUNARVIM"
echo "- Skip Tests: $ZSH_DOTFILES_SKIP_TESTS"

# Create a temporary directory for downloads
setup_temp_dir() {
    TEMP_DIR=$(mktemp -d)
    if [ ! -d "$TEMP_DIR" ]; then
        echo "Failed to create temporary directory"
        exit 1
    fi

    # Clean up temp directory on exit
    trap 'rm -rf "$TEMP_DIR"' EXIT

    echo "Created temporary directory: $TEMP_DIR"
}

# Check if brew is installed
if ! command -v brew >/dev/null 2>&1; then
    echo "Error: Homebrew is not installed. Please install Homebrew first."
    echo "Visit https://brew.sh for installation instructions."
    exit 1
fi

# Install required brew packages
echo "Installing required brew packages..."
brew tap schniz/tap || true
brew install wget || true
brew install curl || true
brew install kadwanev/brew/retry || true
brew install go || true
brew install trash || true


# Set up PATH to include user bin directories
echo "Setting up PATH..."
mkdir -p "$HOME/bin" "$HOME/.bin" "$HOME/.local/bin"
PATH="$HOME/.bin:$HOME/bin:$HOME/.local/bin:$PATH"
export PATH

echo "PATH is now: $PATH"

# Create temp directory for downloads
setup_temp_dir

# Download and run zsh-dotfiles-prereq-installer
echo "Downloading and running zsh-dotfiles-prereq-installer..."
cd "$TEMP_DIR"
wget https://raw.githubusercontent.com/bossjones/zsh-dotfiles-prep/main/bin/zsh-dotfiles-prereq-installer
chmod +x zsh-dotfiles-prereq-installer

# Run the installer with retry for reliability
if command -v retry >/dev/null 2>&1; then
    retry -t 4 -- ./zsh-dotfiles-prereq-installer --debug
else
    # Simple retry function if retry command is not available
    max_attempts=4
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt of $max_attempts"
        if ./zsh-dotfiles-prereq-installer --debug; then
            break
        else
            if [ $attempt -eq $max_attempts ]; then
                echo "Failed after $max_attempts attempts"
                exit 1
            fi
            echo "Attempt failed, retrying in 5 seconds..."
            sleep 5
            attempt=$((attempt + 1))
        fi
    done
fi

# Clone the repository if we're in piped execution
if [ "$ZSH_DOTFILES_NONINTERACTIVE" -eq 1 ]; then
    echo "Cloning zsh-dotfiles repository..."
    REPO_DIR="$HOME/.zsh-dotfiles"
    if [ -d "$REPO_DIR" ]; then
        echo "Directory $REPO_DIR already exists. Updating..."
        cd "$REPO_DIR"
        git pull
    else
        git clone https://github.com/bossjones/zsh-dotfiles.git "$REPO_DIR"
        cd "$REPO_DIR"
    fi
    DOTFILES_SOURCE="$REPO_DIR"
else
    # In local execution, assume we're already in the repository
    DOTFILES_SOURCE="."
fi

# Run chezmoi init and apply
echo "Running chezmoi init and apply..."
if [ ! -f "$HOME/.bin/chezmoi" ]; then
    echo "Error: chezmoi not found at $HOME/.bin/chezmoi"
    echo "The zsh-dotfiles-prereq-installer may have failed to install chezmoi."
    exit 1
fi

# Run with retry for reliability
if command -v retry >/dev/null 2>&1; then
    retry -t 4 -- "$HOME/.bin/chezmoi" init -R --debug -v --apply --force --source="$DOTFILES_SOURCE"
else
    # Simple retry function if retry command is not available
    max_attempts=4
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt of $max_attempts"
        if "$HOME/.bin/chezmoi" init -R --debug -v --apply --force --source="$DOTFILES_SOURCE"; then
            break
        else
            if [ $attempt -eq $max_attempts ]; then
                echo "Failed after $max_attempts attempts"
                exit 1
            fi
            echo "Attempt failed, retrying in 5 seconds..."
            sleep 5
            attempt=$((attempt + 1))
        fi
    done
fi

# Run post-install-chezmoi
echo "Running post-install-chezmoi..."
if command -v retry >/dev/null 2>&1; then
    retry -t 4 -- post-install-chezmoi
else
    # Simple retry function if retry command is not available
    max_attempts=4
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt of $max_attempts"
        if post-install-chezmoi; then
            break
        else
            if [ $attempt -eq $max_attempts ]; then
                echo "Failed after $max_attempts attempts"
                exit 1
            fi
            echo "Attempt failed, retrying in 5 seconds..."
            sleep 5
            attempt=$((attempt + 1))
        fi
    done
fi

# Install LunarVim (optional)
install_lunarvim() {
    echo "Installing LunarVim..."
    export LUNARVIM_LOG_LEVEL="debug"
    export LV_BRANCH="release-1.3/neovim-0.9"
    curl -s "https://raw.githubusercontent.com/LunarVim/LunarVim/${LV_BRANCH}/utils/installer/install.sh" | bash -s -- --install-dependencies -y
}

# Check if we should install LunarVim
if [ "$ZSH_DOTFILES_SKIP_LUNARVIM" -eq 0 ]; then
    # Ask user if they want to install LunarVim (skip in CI or non-interactive mode)
    if [ "$ZSH_DOTFILES_PREP_CI" -eq 0 ] && [ "$ZSH_DOTFILES_NONINTERACTIVE" -eq 0 ]; then
        printf "Do you want to install LunarVim? (y/N): "
        read -r install_lv
        case "$install_lv" in
            [Yy]*)
                install_lunarvim
                ;;
            *)
                echo "Skipping LunarVim installation."
                ;;
        esac
    else
        # In CI or non-interactive mode, install LunarVim automatically
        install_lunarvim
    fi
else
    echo "Skipping LunarVim installation as requested."
fi

# Run tests
run_tests() {
    echo "Running tests..."

    # Create Python virtual environment
    python -m venv venv

    # Source the virtual environment
    # shellcheck disable=SC1091
    . ./venv/bin/activate

    # Install dependencies
    pip install -U pip setuptools wheel
    pip install -U -r requirements-test.txt

    # Set up ASDF if available
    if [ -d "$HOME/.asdf" ]; then
        export ASDF_DIR="$HOME/.asdf"
        export ASDF_COMPLETIONS="$ASDF_DIR/completions"
        # shellcheck disable=SC1091
        . "$HOME/.asdf/asdf.sh"
        PATH="$HOME/.asdf/bin:$HOME/.asdf/shims:$PATH"
        export PATH
    fi

    # Run tests using make
    make test

    # Deactivate virtual environment
    deactivate
}

# Check if we should run tests
if [ "$ZSH_DOTFILES_SKIP_TESTS" -eq 0 ]; then
    # Ask user if they want to run tests (skip in CI or non-interactive mode)
    if [ "$ZSH_DOTFILES_PREP_CI" -eq 0 ] && [ "$ZSH_DOTFILES_NONINTERACTIVE" -eq 0 ]; then
        printf "Do you want to run tests? (y/N): "
        read -r run_tests_input
        case "$run_tests_input" in
            [Yy]*)
                run_tests
                ;;
            *)
                echo "Skipping tests."
                ;;
        esac
    else
        # In CI or non-interactive mode, run tests automatically
        run_tests
    fi
else
    echo "Skipping tests as requested."
fi

echo "Installation completed successfully!"
