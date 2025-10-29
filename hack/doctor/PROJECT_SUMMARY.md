# Development Environment Verification Suite

A complete toolkit for checking and setting up your macOS development environment based on your zsh-dotfiles configuration.

## 📦 What's Included

### Core Scripts

| File | Purpose | Type |
|------|---------|------|
| `check_dev_environment.py` | Main verification script | Python 3.6+ |
| `install_missing.sh` | Automated package installer | Bash |
| `Makefile` | Convenient command shortcuts | Make |

### Documentation

| File | Contents |
|------|----------|
| `README.md` | Full documentation and usage guide |
| `QUICKSTART.md` | Quick reference and common commands |
| `example_output.txt` | Sample checker output |

## 🚀 Quick Start (3 Commands)

```bash
# 1. Check what you have
make check

# 2. Install what's missing
make install

# 3. Verify everything
make test
```

## 📋 What Gets Verified

### ✅ Homebrew Packages (118 total)

**Terminal Utilities**
- Modern CLI tools: bat, fzf, ripgrep, fd, git-delta
- File managers: nnn, broot
- Monitoring: duf, dust, ncdu
- Search: peco, pdfgrep

**Development Tools**
- Editors: neovim, vim
- Git: git, gh, hub, diff-so-fancy
- Shells: zsh, bash
- Linters: shellcheck, shfmt

**Programming Languages & Runtimes**
- Python: python@3.10, pyenv
- Ruby: ruby-build, rbenv
- Node: node, fnm
- Go: (via ASDF)

**Nerd Fonts (24 fonts)**
- Fira Code, JetBrains Mono, Hack
- Meslo, Sauce Code Pro, Ubuntu
- Liberation, Noto, Victor Mono
- And 15 more!

**System Libraries**
- Compression: xz, zlib, bzip2
- Crypto: openssl, gnutls
- Media: ffmpeg, imagemagick, graphicsmagick
- Databases: sqlite3
- And many more...

### ✅ Sheldon

- Version: 0.6.6 (exact)
- Location: ~/.local/bin/sheldon (exact)
- Shell plugin manager for managing zsh plugins

### ✅ Chezmoi

- Version: Any
- Dotfile manager for syncing configurations

### ✅ ASDF Tools (18 tools)

| Tool | Version | Purpose |
|------|---------|---------|
| golang | 1.20.5 | Go programming language |
| kubectl | 1.26.12 | Kubernetes CLI |
| helm | 3.14.2 | Kubernetes package manager |
| k9s | 0.32.4 | Kubernetes TUI |
| neovim | 0.11.3 | Modern Vim |
| ruby | 3.2.1 | Ruby language |
| shellcheck | 0.10.0 | Shell script linter |
| shfmt | 3.7.0 | Shell formatter |
| tmux | 3.5a | Terminal multiplexer |
| yq | 4.34.1 | YAML processor |
| github-cli | 2.35.0 | GitHub CLI |
| helm-docs | 1.13.1 | Helm documentation |
| helmfile | 0.162.0 | Helm release manager |
| kubectx | 0.9.5 | Kubernetes context switcher |
| kubetail | 1.6.20 | Kubernetes log viewer |
| mkcert | 1.4.4 | Local certificate generator |
| opa | 0.62.1 | Policy engine |
| rye | 0.33.0 | Python package manager |

## 🎯 Usage Examples

### Using the Python Script Directly

```bash
# Basic check
./check_dev_environment.py

# With specific focus (edit script to customize)
./check_dev_environment.py

# Capture output
./check_dev_environment.py > env_check.log
```

### Using the Install Script

```bash
# Install everything automatically
./install_missing.sh

# Preview what would be installed (dry run)
# Edit the script to add: echo "Would install: $package"
```

### Using Make Commands

```bash
# Show all available commands
make help

# Check environment
make check

# Install missing packages
make install

# Full setup from scratch
make setup-all

# Individual components
make install-homebrew
make install-sheldon
make install-chezmoi
make install-asdf

# Show versions
make version

# Clean temporary files
make clean
```

## 🔧 Configuration

### Customize Packages

Edit `check_dev_environment.py`:

```python
# Line ~220: Add/remove brew packages
packages = [
    'your-package-here',
    # ...
]

# Line ~357: Modify ASDF tools and versions
tools = {
    'your-tool': 'version',
    # ...
}
```

### Customize Installation

Edit `install_missing.sh`:

```bash
# Line ~70: Core packages
CORE_PACKAGES=(
    "your-package"
    # ...
)

# Line ~147: ASDF tools
declare -A ASDF_TOOLS=(
    ["your-tool"]="version"
    # ...
)
```

## 📊 Output Format

### Color Coding

- 🟢 **Green ✓**: Correctly installed
- 🔴 **Red ✗**: Missing or incorrect  
- 🟡 **Yellow ⚠**: Warning (installed but wrong version)

### Exit Codes

- `0`: All checks passed
- `1`: One or more failures

### Sample Output

```
======================================================================
Checking Homebrew Packages
======================================================================

✓ bat
✓ fzf
✗ ripgrep - NOT INSTALLED
⚠ neovim - version mismatch

Summary: 116/118 packages installed

======================================================================
Final Report
======================================================================

Brew Packages: 116/118 installed
ASDF Tools: 17/18 installed (16 correct versions)
Sheldon: ✓
Chezmoi: ✓

Issues Found: 3
```

## 🔄 Typical Workflow

### First Time Setup (New Mac)

```bash
# 1. Clone this repo or download files
cd ~/Downloads/env-checker

# 2. Full automated setup
make setup-all

# 3. Restart shell
exec zsh

# 4. Verify everything
make check

# 5. Initialize dotfiles
chezmoi init --apply https://github.com/bossjones/zsh-dotfiles.git
```

### Regular Maintenance

```bash
# Check for missing packages after dotfiles update
make check

# Update specific tools
brew upgrade <package>
asdf install <tool> <new-version>

# Verify updates
make test
```

### Before Sharing Your Setup

```bash
# Verify your environment
make check > my_environment.log

# Share the log with team members
# They can see what you have installed
```

## 🐛 Troubleshooting

### Common Issues

**Issue: Python not found**
```bash
brew install python@3.10
```

**Issue: Permission denied**
```bash
chmod +x *.py *.sh
```

**Issue: Brew command not found**
```bash
make install-homebrew
```

**Issue: ASDF tools not found after install**
```bash
# Add to ~/.zshrc
. $(brew --prefix asdf)/libexec/asdf.sh

# Restart shell
exec zsh
```

**Issue: Fonts not showing**
```bash
# Refresh font cache
fc-cache -f -v
```

### Debug Mode

For more verbose output, edit scripts to add:

```bash
# In bash scripts
set -x  # Enable debug mode

# In Python
import logging
logging.basicConfig(level=logging.DEBUG)
```

## 🔐 Security Notes

- Scripts install packages from official sources only
- Homebrew: https://brew.sh
- Sheldon: https://github.com/rossmacarthur/sheldon
- Chezmoi: https://chezmoi.io
- ASDF: https://asdf-vm.com

Review scripts before running:
```bash
cat check_dev_environment.py
cat install_missing.sh
```

## 📚 Additional Resources

- [Homebrew Documentation](https://docs.brew.sh)
- [ASDF Documentation](https://asdf-vm.com/guide/getting-started.html)
- [Sheldon Documentation](https://sheldon.cli.rs)
- [Chezmoi Documentation](https://www.chezmoi.io)
- [Your dotfiles repo](https://github.com/bossjones/zsh-dotfiles)

## 🤝 Contributing

To add more checks:

1. Edit `check_dev_environment.py`
2. Add packages to appropriate lists
3. Run `make check` to test
4. Update documentation

## 📝 License

MIT - Use freely for your own setup!

## 🎉 Credits

Based on the environment from:
- GitHub: bossjones/zsh-dotfiles
- User: @bossjones

---

## Quick Command Reference Card

```bash
# Essential Commands
make check          # Check current setup
make install        # Install missing packages
make setup-all      # Full setup from scratch
make help           # Show all commands

# Individual Tools
make install-homebrew
make install-sheldon
make install-chezmoi
make install-asdf

# Direct Script Usage
./check_dev_environment.py
./install_missing.sh

# Verify Everything
make test
make version
```

---

**Remember**: After installation, always restart your shell!

```bash
exec zsh
```

Or open a new terminal window.
