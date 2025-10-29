#!/usr/bin/env bash
# install_missing.sh - Install all missing packages detected by check_dev_environment.py

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR=$(mktemp -d)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE}Development Environment Setup${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo ""

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${RED}✗ Homebrew is not installed${NC}"
    echo -e "${YELLOW}Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

echo -e "${GREEN}✓ Homebrew is installed${NC}"
echo ""

# Install Sheldon if missing
echo -e "${BLUE}Checking Sheldon...${NC}"
if [[ ! -f "$HOME/.local/bin/sheldon" ]]; then
    echo -e "${YELLOW}Installing Sheldon...${NC}"
    mkdir -p "$HOME/.local/bin"
    curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | \
        bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin --tag 0.6.6
    echo -e "${GREEN}✓ Sheldon installed${NC}"
else
    echo -e "${GREEN}✓ Sheldon already installed${NC}"
fi
echo ""

# Install Chezmoi if missing
echo -e "${BLUE}Checking Chezmoi...${NC}"
if ! command -v chezmoi &> /dev/null; then
    echo -e "${YELLOW}Installing Chezmoi...${NC}"
    sh -c "$(curl -fsLS chezmoi.io/get)"
    echo -e "${GREEN}✓ Chezmoi installed${NC}"
else
    echo -e "${GREEN}✓ Chezmoi already installed${NC}"
fi
echo ""

# Install ASDF if missing
echo -e "${BLUE}Checking ASDF...${NC}"
if ! command -v asdf &> /dev/null; then
    echo -e "${YELLOW}Installing ASDF...${NC}"
    brew install asdf
    echo -e "${GREEN}✓ ASDF installed${NC}"
    echo -e "${YELLOW}⚠ Please add the following to your ~/.zshrc:${NC}"
    echo -e "  . \$(brew --prefix asdf)/libexec/asdf.sh"
else
    echo -e "${GREEN}✓ ASDF already installed${NC}"
fi
echo ""

# Install critical brew packages
echo -e "${BLUE}Installing critical Homebrew packages...${NC}"
echo ""

# Core utilities
CORE_PACKAGES=(
    # Terminal utilities
    "bat"
    "fzf"
    "ripgrep"
    "fd"
    "git-delta"
    "tree"
    "jq"
    "yq"
    
    # Development tools
    "neovim"
    "vim"
    "git"
    "gh"
    
    # Shell tools
    "zsh"
    "shellcheck"
    "shfmt"
    
    # Languages
    "python@3.10"
    "node"
    
    # System libraries
    "openssl"
    "readline"
    "sqlite3"
    "xz"
    "zlib"
    "pkg-config"
)

for package in "${CORE_PACKAGES[@]}"; do
    if brew list --formula | grep -q "^${package}$" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $package"
    else
        echo -e "${YELLOW}⟳${NC} Installing $package..."
        brew install "$package" || echo -e "${RED}✗ Failed to install $package${NC}"
    fi
done

echo ""
echo -e "${BLUE}Installing Nerd Fonts...${NC}"
echo ""

# Nerd Fonts
FONTS=(
    "font-fira-code-nerd-font"
    "font-jetbrains-mono-nerd-font"
    "font-hack-nerd-font"
    "font-meslo-lg-nerd-font"
    "font-sauce-code-pro-nerd-font"
)

for font in "${FONTS[@]}"; do
    if brew list --cask | grep -q "^${font}$" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $font"
    else
        echo -e "${YELLOW}⟳${NC} Installing $font..."
        brew install --cask "$font" || echo -e "${RED}✗ Failed to install $font${NC}"
    fi
done

echo ""
echo -e "${BLUE}Installing ASDF plugins and tools...${NC}"
echo ""

# ASDF tools
declare -A ASDF_TOOLS=(
    ["golang"]="1.20.5"
    ["kubectl"]="1.26.12"
    ["helm"]="3.14.2"
    ["k9s"]="0.32.4"
    ["neovim"]="0.11.3"
    ["ruby"]="3.2.1"
    ["shellcheck"]="0.10.0"
    ["shfmt"]="3.7.0"
    ["tmux"]="3.5a"
    ["yq"]="4.34.1"
)

if command -v asdf &> /dev/null; then
    for tool in "${!ASDF_TOOLS[@]}"; do
        version="${ASDF_TOOLS[$tool]}"
        
        # Add plugin if not exists
        if ! asdf plugin list | grep -q "^${tool}$"; then
            echo -e "${YELLOW}⟳${NC} Adding asdf plugin: $tool"
            asdf plugin add "$tool" 2>/dev/null || true
        fi
        
        # Install version if not exists
        if ! asdf list "$tool" 2>/dev/null | grep -q "$version"; then
            echo -e "${YELLOW}⟳${NC} Installing $tool $version"
            asdf install "$tool" "$version" || echo -e "${RED}✗ Failed to install $tool $version${NC}"
        else
            echo -e "${GREEN}✓${NC} $tool $version"
        fi
        
        # Set global version
        asdf global "$tool" "$version" 2>/dev/null || true
    done
else
    echo -e "${YELLOW}⚠ ASDF not available, skipping tool installations${NC}"
fi

echo ""
echo -e "${BLUE}==================================================================${NC}"
echo -e "${GREEN}Setup complete!${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo ""
echo -e "Next steps:"
echo -e "  1. Restart your shell or run: ${YELLOW}source ~/.zshrc${NC}"
echo -e "  2. Run the checker: ${YELLOW}./check_dev_environment.py${NC}"
echo -e "  3. Initialize chezmoi: ${YELLOW}chezmoi init --apply https://github.com/bossjones/zsh-dotfiles.git${NC}"
echo ""
