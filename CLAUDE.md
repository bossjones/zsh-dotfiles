# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

A comprehensive dotfiles management system using **chezmoi** for ZSH configuration and customization. The repository manages shell configuration, aliases, functions, plugin management with **sheldon**, and cross-platform compatibility (macOS/Linux).

## Common Development Commands

### Testing
```bash
make test           # Run pytest with retries and tmux-based integration tests
make test-pdb       # Run tests with debugger (bpdb)
```

### Development Tasks
```bash
make update-cursor-rules  # Update .cursor/rules from hack/drafts/cursor_rules/ (changes .md to .mdc)
make install-hooks       # Install pre-commit hooks using uv
```

### CI/CD Setup
```bash
# Manual test environment setup (mirrors CI)
python -m venv venv
source ./venv/bin/activate
pip install -U pip setuptools wheel
pip install -U -r requirements-test.txt
```

### Chezmoi Operations
```bash
chezmoi git pull -- --autostash --rebase  # Pull latest changes
chezmoi apply                              # Apply changes to dotfiles
chezmoi execute-template < file.tmpl       # Test template rendering
chezmoi data                              # Check template variables
chezmoi doctor                            # Verify template syntax
```

## Architecture & Code Organization

### Template System
- **chezmoi** uses Go templates with `.tmpl` files that render based on OS/environment
- Template variables: `.chezmoi.os` (darwin/linux), `.chezmoi.arch`, `.chezmoi.hostname`, `.chezmoi.username`
- Conditional OS configuration using `{{ if eq .chezmoi.os "darwin" }}` blocks

### Directory Structure
- `/home/` - Main dotfiles directory (chezmoi root)
- `/home/shell/` - Modular ZSH configuration components
- `/home/shell/init.zsh` - Core initialization
- `/home/shell/customs/aliases.zsh` - Custom aliases and functions
- `/home/shell/zsh_dot_d/` - Before/after hooks for tool initialization
- `/home/shell/{tool}/` - Tool-specific modules (asdf, brew, fzf, go, rust, etc.)

### Plugin Management with Sheldon
- Configuration in `/home/dot_sheldon/plugins.toml.tmpl`
- Uses deferred loading with `zsh-defer` for performance
- Template-driven plugin configuration with OS-specific plugins
- Key plugins: pure prompt, zsh-completions, syntax highlighting, autosuggestions

### Testing Framework
- Uses `pytest` with `libtmux` for tmux-based integration testing
- Tests ZSH functionality, aliases, and tool setup in isolated tmux sessions
- `conftest.py` provides tmux fixtures for test isolation
- Tests verify prompt setup, alias functionality, and tool availability
- Dependencies managed via `requirements-test.txt` (includes pytest, libtmux, bpython)

### AI Development Tools
- `/hack/drafts/cursor_rules/` - Cursor AI rules for development assistance
- `/ai_docs/` - AI-generated documentation and reports
- Custom workflows for autogenerating documentation

## Key Patterns

### Modular Configuration Loading
- Tool-specific modules with conditional loading based on availability
- Separation of environment variables (`env.zsh`) and PATH modifications (`path.zsh`)
- Before/after hooks in `zsh_dot_d/` for proper initialization order

### Cross-Platform Compatibility
- OS detection using chezmoi template variables
- Conditional package manager and path handling
- Tool-specific configuration based on platform (homebrew vs package managers)

### Performance Optimization
- Deferred plugin loading using `zsh-defer`
- Lazy loading of completions and heavy plugins
- Modular sourcing to minimize startup time

## Development Notes

- The repository uses `uv` for Python dependency management
- Pre-commit hooks are available via `make install-hooks`
- Tests are designed for local development and may be skipped in CI
- Template rendering can be tested independently using `chezmoi execute-template`
- When modifying templates, always test rendering with `chezmoi doctor`

## CI/CD Pipeline

### GitHub Actions Workflow
- **Platforms**: Tests run on `macos-14` and `macos-latest`
- **Python**: Uses Python 3.12 with pip caching
- **Go**: Uses Go 1.20.5 for chezmoi operations
- **Prerequisites**: Uses external `zsh-dotfiles-prep` installer for system setup
- **Environment Variables**:
  - `ZSH_DOTFILES_PREP_CI=1` - CI mode flag
  - `ZSH_DOTFILES_PREP_DEBUG=1` - Debug mode
  - `ZSH_DOTFILES_PREP_SKIP_BREW_BUNDLE=1` - Skip heavy brew installations

### Installation Process
1. **System Setup**: Installs essential tools via brew (wget, curl, retry, tmux, etc.)
2. **Dotfiles Prep**: Downloads and runs `zsh-dotfiles-prereq-installer` with retries
3. **Chezmoi Install**: Full chezmoi initialization with `--force --source=.`
4. **Post-Install**: Runs `post-install-chezmoi` script
5. **LunarVim**: Installs LunarVim with dependencies
6. **Testing**: Creates Python venv and runs pytest suite

### Platform-Specific Handling
- **macOS 15**: Requires special OpenSSL 3 configuration and rbenv tap
- **ASDF Integration**: Sets up ASDF environment variables and PATH
- **Ruby**: Installs Ruby 3.2.1 with OpenSSL 3 support

### Development Dependencies
Key packages installed during CI:
- Essential: `openssl@3`, `readline`, `libyaml`, `gmp`, `autoconf`, `tmux`
- Tools: `git`, `fzf`, `ripgrep`, `jq`, `gh`, `neovim`, `pyenv`, `rbenv`
- Python: `python@3.10` with venv support

## Installed Tools & Packages

### Package Managers & Environment Tools
- **asdf**: Multi-language runtime version manager
- **sheldon**: ZSH plugin manager (compiled from source on arm64 macOS)
- **rye**: Python project & dependency management tool with uv backend
- **fnm**: Fast Node.js version manager
- **pyenv**: Python version management (Ubuntu)

### Development Tools via ASDF
**Core Languages & Runtimes:**
- Ruby (with foreman, tmuxinator gems)
- Go/Golang (with gopls language server)
- Node.js/fnm (with pure-prompt, docker utilities)
- Neovim
- tmux

**DevOps & Infrastructure:**
- kubectl, helm, helmfile, helm-docs
- k9s, kubectx, kubetail
- mkcert (local SSL certificates)
- opa (Open Policy Agent)

**Code Quality & Formatting:**
- shellcheck (shell script linting)
- shfmt (shell script formatting)
- yq (YAML/JSON processing)
- github-cli (gh command)

### Ubuntu-Specific Packages
**Essential Development Libraries:**
- Build tools: `build-essential`, `autotools-dev`, `automake`, `cmake`, `meson`, `ninja-build`
- Image processing: `libjpeg-dev`, `libtiff-dev`, `libpng-dev`, `libwebp-dev`, `libfreetype6-dev`, `imagemagick`
- Database: `libmysqlclient-dev`, `libpq-dev`, `postgresql-client`, `sqlite3`, `libhdf5-serial-dev`
- XML/Text: `libxml2-dev`, `libxslt-dev`, `pandoc`, `doxygen`
- Compression: `libbz2-dev`, `zlib1g-dev`, `xz-utils`
- SSL/Crypto: `libssl-dev`, `libffi-dev`, `libgnutls28-dev`
- Python deps: `libreadline-dev`, `liblzma-dev`, `libncursesw5-dev`, `python3-numpy`, `python3-scipy`, `python3-matplotlib`

**Multimedia & Video Processing:**
- **ffmpeg**: Core video/audio processing framework with comprehensive codec support
- Video codecs: `libx264-dev`, `libx265-dev`, `libvpx-dev`, `libxvidcore-dev`, `libaom-dev`
- Audio codecs: `libmp3lame-dev`, `libopus-dev`, `libfdk-aac-dev`, `libvorbis-dev`, `libass-dev`, `libtheora-dev`
- Streaming: `libavcodec-dev`, `libavformat-dev`, `libswscale-dev`, `libv4l-dev`
- Hardware acceleration: `libva-dev`, `libvdpau-dev`
- SDL/Graphics: `libsdl2-dev`, `libsdl2-image-dev`, `libsdl2-mixer-dev`, `libsdl2-ttf-dev`
- Gstreamer: `libgstreamer1.0-dev`, `libgstreamer-plugins-base1.0-dev`

**Computer Vision & OpenCV:**
- OpenCV: `libopencv-dev`, `python3-opencv`
- Math libraries: `libopenblas-dev`, `liblapack-dev`, `libatlas-base-dev`, `libeigen3-dev`
- Threading: `libtbb-dev`, `libtbb2`, `libomp-dev`
- Graphics: `libgtk-3-dev`, `openexr`, `libopenexr-dev`

**Network & Download Tools:**
- Download utilities: `aria2`, `atomicparsley`, `nmap`
- Network libraries: `libaria2-dev`, `python3-netaddr`
- OCR: `tesseract-ocr` (version 5 from PPA)

**CLI Tools:**
- Search: `fd-find`, `ripgrep`, `silversearcher-ag`, `fzf`
- File operations: `tree`, `parallel`, `file`, `jq`, `fdupes`
- System: `curl`, `git`, `vim`, `direnv`, `ccze`, `linux-headers`
- Development: `pkg-config`, `git-core`, `mercurial`, `graphviz`

### Kubernetes Tools (krew plugins)
- **Debugging**: `node-shell`, `netshoot`, `pod-inspect`, `explore`
- **Resource Management**: `resource-capacity`, `images`, `get-all`
- **Security**: `permissions`, `access-matrix`, `view-secret`
- **Monitoring**: `ktop`, `node-logs`, `clog`
- **Utilities**: `kurt`, `gadget`, `ingress-nginx`, `slice`, `neat`

### Documentation & Cheat Sheets
- **cheat**: Command-line cheatsheet tool (v4.3.1)
- **Community cheatsheets**: From official cheat/cheatsheets repo
- **Personal cheatsheets**: From bossjones/boss-cheatsheets repo

### Platform-Specific Considerations
**macOS arm64:**
- Rust toolchain for compiling sheldon from source
- OpenSSL 3 configuration for Ruby compilation
- Homebrew prefix handling for arm64 vs x86_64

**Ubuntu:**
- System package dependencies for Python/Node.js compilation
- Manual installation of tools not available via apt
- FD binary symlinked as `fd` (conflicts with existing package)
