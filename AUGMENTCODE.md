# AUGMENTCODE.md

This file provides comprehensive guidance to Augment Code when working with this zsh-dotfiles repository.

## Repository Overview

A sophisticated dotfiles management system using **chezmoi** for cross-platform ZSH configuration and customization. This repository manages shell configuration, aliases, functions, plugin management with **sheldon**, and supports macOS, Ubuntu, CentOS, and Oracle Linux environments.

## Prerequisites & Dependencies

### System Requirements
- **Operating Systems**: macOS (arm64/x86_64), Ubuntu 20.04+, CentOS 8/9 Stream, Oracle Linux Server, RHEL 8/9
- **Shell**: ZSH (primary), Bash (compatibility)
- **Package Managers**:
  - macOS: Homebrew
  - Ubuntu: apt
  - CentOS/RHEL: dnf/yum + EPEL repository
  - Oracle Linux: dnf + EPEL repository

### Core Dependencies
- **chezmoi**: Dotfiles manager (minimum version specified in `.chezmoiversion`)
- **Git**: Version control and repository management
- **Python 3.10+**: For testing framework and scripts
- **Go 1.20.5+**: For chezmoi operations and some tools
- **Rust**: For compiling sheldon on arm64 macOS

### Essential Tools Installed
- **sheldon**: ZSH plugin manager (compiled from source on arm64 macOS)
- **asdf**: Multi-language runtime version manager
- **fnm**: Fast Node.js version manager
- **fzf**: Fuzzy finder
- **ripgrep**: Fast text search
- **fd**: Fast file finder
- **tmux**: Terminal multiplexer
- **neovim**: Modern Vim editor

## Installation Methods

### One-Line Installation (Recommended)
```bash
sh -c "$(curl -fsLS chezmoi.io/get)" -- init -R --debug -v --apply https://github.com/bossjones/zsh-dotfiles.git
```

### Alternative Installation Script
```bash
curl -fsSL https://raw.githubusercontent.com/bossjones/zsh-dotfiles/main/install.sh | sh
```

### Manual Installation
1. Install chezmoi:
   ```bash
   sh -c "$(curl -fsLS chezmoi.io/get)"
   ```

2. Initialize with this repository:
   ```bash
   chezmoi init -R --debug -v --apply https://github.com/bossjones/zsh-dotfiles.git
   ```

### Environment Variables for Installation
- `ZSH_DOTFILES_PREP_GITHUB_USER`: GitHub username (default: bossjones)
- `ZSH_DOTFILES_PREP_SKIP_BREW_BUNDLE`: Skip brew bundle (default: 1)
- `ZSH_DOTFILES_PREP_DEBUG`: Enable debug output (default: 1)
- `ZSH_DOTFILES_SKIP_LUNARVIM`: Skip LunarVim installation (default: 0)
- `ZSH_DOTFILES_SKIP_TESTS`: Skip running tests (default: 0)
- `ZSH_DOTFILES_PREP_CI`: CI mode flag
- `ZSH_DOTFILES_NONINTERACTIVE`: Non-interactive mode

## Development Commands

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

### CI/CD Setup (Manual)
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
- OS-specific conditions: `{{ if eq .chezmoi.os "darwin" }}` blocks
- Distribution-specific: `{{ if eq .chezmoi.osRelease.name "Ubuntu" }}` blocks

### Directory Structure
```
.
├── .cursor/                     # Cursor editor configuration
│   └── rules/                   # Cursor rules for AI assistance
├── .devcontainer/               # Development container configuration
├── .github/                     # GitHub configuration and workflows
│   ├── dependabot.yml          # Dependency updates
│   └── workflows/               # CI/CD workflows
├── .vscode/                     # VS Code configuration
├── ai_docs/                     # AI-generated documentation
├── hack/                        # Development scripts and tools
│   └── drafts/cursor_rules/     # Cursor AI rules source
├── home/                        # Main dotfiles directory (chezmoi root)
│   ├── .chezmoiscripts/         # Installation and setup scripts
│   ├── dot_sheldon/             # Sheldon plugin configuration
│   ├── private_dot_config/      # Configuration files (.config directory)
│   └── shell/                   # Modular ZSH configuration components
├── venv/                        # Python virtual environment
├── Makefile                     # Build automation
├── conftest.py                  # Pytest configuration
├── test_dotfiles.py             # Dotfiles tests
├── requirements-test.txt        # Test dependencies
├── install.sh                   # Standalone installation script
└── .pre-commit-config.yaml      # Pre-commit hooks configuration
```

### Shell Configuration Structure
- `/home/shell/` - Modular ZSH configuration components
- `/home/shell/init.zsh` - Core initialization
- `/home/shell/customs/aliases.zsh` - Custom aliases and functions
- `/home/shell/zsh_dot_d/` - Before/after hooks for tool initialization
- `/home/shell/{tool}/` - Tool-specific modules (asdf, brew, fzf, go, rust, etc.)

### Plugin Management with Sheldon
- Configuration in `/home/dot_sheldon/plugins.toml.tmpl` and `/home/private_dot_config/sheldon/plugins.toml.tmpl`
- Uses deferred loading with `zsh-defer` for performance
- Template-driven plugin configuration with OS-specific plugins
- Key plugins: pure prompt, zsh-completions, syntax highlighting, autosuggestions
- Cross-platform support: Ubuntu, CentOS Linux, Oracle Linux Server, macOS

### Installation Scripts (Chezmoi Scripts)
Located in `/home/.chezmoiscripts/`, these scripts handle platform-specific installations:

#### Prerequisites Scripts
- `run_before-00-prereq-{ubuntu,centos}.sh.tmpl` - System prerequisites
- `run_before-00-prereq-{ubuntu,centos}-pyenv.sh.tmpl` - Python environment setup

#### Package Installation Scripts
- `run_onchange_before_01-{ubuntu,centos}-install-packages.sh.tmpl` - Core system packages
- `run_onchange_before_02-*-install-*.sh.tmpl` - Tool-specific installations (asdf, fd, fnm, opencv-deps, sheldon)
- `run_onchange_before_03-*-install-krew.sh.tmpl` - Kubernetes krew plugin manager

#### Configuration Scripts
- `run_onchange_after_50-*-install-asdf-plugins.sh.tmpl` - ASDF plugins and tools
- `run_after-00-adhoc-*.sh.tmpl` - Post-installation tasks
- `run_onchange_before_99-*-write-completions.sh.tmpl` - Shell completions

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
- `.cursor/rules/` - Processed Cursor rules (generated from drafts)

## Key Patterns

### Modular Configuration Loading
- Tool-specific modules with conditional loading based on availability
- Separation of environment variables (`env.zsh`) and PATH modifications (`path.zsh`)
- Before/after hooks in `zsh_dot_d/` for proper initialization order

### Cross-Platform Compatibility
- OS detection using chezmoi template variables
- Distribution-specific package management and path handling
- Tool-specific configuration based on platform (homebrew vs package managers)
- Support for Ubuntu, CentOS, Oracle Linux, and macOS

### Performance Optimization
- Deferred plugin loading using `zsh-defer`
- Lazy loading of completions and heavy plugins
- Modular sourcing to minimize startup time

## Development Notes

### Package Management
- The repository uses `uv` for Python dependency management
- Pre-commit hooks are available via `make install-hooks`
- Always use package managers for dependency management instead of manually editing package files

### Template Development
- Tests are designed for local development and may be skipped in CI
- Template rendering can be tested independently using `chezmoi execute-template`
- When modifying templates, always test rendering with `chezmoi doctor`
- Use `chezmoi data` to inspect available template variables

### External Dependencies
External repositories managed via `.chezmoiexternal.yaml`:
- `dev/bossjones/oh-my-tmux` - Custom tmux configuration
- `dev/bossjones/boss-cheatsheets` - Personal cheatsheets collection

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
- **uv**: Python package and project manager (Astral)
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

### CentOS/RHEL-Specific Packages
**Package Manager Translation:**
- `apt update` → `dnf check-update`
- `apt install` → `dnf install`
- `build-essential` → `groupinstall "Development Tools"`

**Repository Requirements:**
- **EPEL**: Extra Packages for Enterprise Linux
- **PowerTools** (CentOS 8) / **CRB** (CentOS 9): Code Ready Builder
- **RPM Fusion**: Multimedia packages

**Common Package Mappings:**
- `python3-dev` → `python3-devel`
- `libssl-dev` → `openssl-devel`
- `pkg-config` → `pkgconf-pkg-config`
- `libbz2-dev` → `bzip2-devel`
- `libffi-dev` → `libffi-devel`

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

**CentOS/Oracle Linux:**
- EPEL repository setup for additional packages
- Development tools group installation
- SELinux considerations for some installations

## Quality Assurance

### Pre-commit Hooks
Configured in `.pre-commit-config.yaml`:
- **Text Processing**: Fix smart quotes, ligatures, alphabetize CODEOWNERS
- **Code Formatting**: Prettier for YAML/JSON
- **Code Quality**: AST validation, JSON validation, merge conflict detection
- **GitHub Actions**: Actionlint for workflow validation
- **Security**: Check for unicode replacement characters

### Testing Strategy
- **Unit Tests**: Python-based tests using pytest
- **Integration Tests**: tmux-based shell testing with libtmux
- **Template Tests**: Chezmoi template rendering validation
- **Cross-Platform Tests**: CI testing on multiple macOS versions

### Dependency Management
- **Dependabot**: Automated dependency updates for GitHub Actions
- **Python**: Requirements pinned in `requirements-test.txt`
- **Pre-commit**: Automated hook updates

## Troubleshooting

### Template Issues
1. Test template rendering:
   ```bash
   chezmoi execute-template < ~/.local/share/chezmoi/dot_zshrc.tmpl
   ```

2. Check template variables:
   ```bash
   chezmoi data
   ```

3. Verify template syntax:
   ```bash
   chezmoi doctor
   ```

### Installation Issues
- Ensure Homebrew is installed on macOS
- Check that required repositories (EPEL) are enabled on CentOS/RHEL
- Verify network connectivity for downloading external tools
- Check PATH includes `$HOME/.bin`, `$HOME/bin`, `$HOME/.local/bin`

### Testing Issues
- Ensure tmux is installed and accessible
- Check Python virtual environment is properly activated
- Verify all test dependencies are installed via `requirements-test.txt`

## Additional Resources

- [Chezmoi Documentation](https://www.chezmoi.io/user-guide/command-overview/)
- [Go Templates Documentation](https://pkg.go.dev/text/template)
- [Sheldon Plugin Manager](https://sheldon.cli.rs/)
- [ASDF Version Manager](https://asdf-vm.com/)
- [ZSH Documentation](https://zsh.sourceforge.io/Doc/)
