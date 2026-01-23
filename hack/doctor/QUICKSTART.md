# Quick Start Guide

## Files Included

1. **check_dev_environment.py** - Main checker script
2. **install_missing.sh** - Automated installer for missing packages
3. **README.md** - Comprehensive documentation
4. **example_output.txt** - Sample output from the checker

## Quick Usage

### Step 1: Check Your Current Setup

```bash
chmod +x check_dev_environment.py
./check_dev_environment.py
```

This will show you what's installed and what's missing.

### Step 2: Install Missing Packages (Optional)

If you want to auto-install everything:

```bash
chmod +x install_missing.sh
./install_missing.sh
```

Or manually install specific items based on the checker output.

### Step 3: Verify Everything

Run the checker again to confirm:

```bash
./check_dev_environment.py
```

## What Gets Checked

✅ **118 Homebrew packages** including:
- Terminal utilities (bat, fzf, ripgrep, git-delta, etc.)
- Development tools (neovim, git, docker, etc.)
- Programming languages (Python, Ruby, Node, Go)
- Nerd Fonts (24 different fonts)
- System libraries (OpenSSL, FFmpeg, etc.)

✅ **Sheldon** (shell plugin manager)
- Version: 0.6.6
- Location: ~/.local/bin/sheldon

✅ **Chezmoi** (dotfile manager)
- Any version
- Any location in PATH

✅ **18 ASDF-managed tools** including:
- golang (1.20.5)
- kubectl (1.26.12)
- helm (3.14.2)
- k9s (0.32.4)
- neovim (0.11.3)
- ruby (3.2.1)
- And 12 more...

## Installation Commands Reference

### Manual Installation

If you prefer to install things manually:

#### Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### Sheldon
```bash
curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | \
  bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin --tag 0.6.6
```

#### Chezmoi
```bash
sh -c "$(curl -fsLS chezmoi.io/get)" -- init -R --debug -v --apply https://github.com/bossjones/zsh-dotfiles.git
```

#### ASDF
```bash
brew install asdf
echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ~/.zshrc
source ~/.zshrc
```

## Troubleshooting

### Script Permission Denied
```bash
chmod +x check_dev_environment.py
chmod +x install_missing.sh
```

### Command Not Found: python3
```bash
brew install python@3.10
```

### Brew Command Not Found
Install Homebrew first (see above)

### ASDF Tools Not Found
1. Install ASDF (see above)
2. Restart your shell: `exec zsh`
3. Run the checker again

## Exit Codes

- `0` = All checks passed ✅
- `1` = One or more checks failed ❌

Perfect for CI/CD:
```bash
./check_dev_environment.py && echo "Ready to go!" || echo "Setup incomplete"
```

## Customization

Edit `check_dev_environment.py` to:
- Add more packages to check
- Change expected versions
- Skip certain checks
- Modify output format

See README.md for detailed customization instructions.

## Support

For issues or questions:
1. Check the full README.md
2. Review example_output.txt to see expected output
3. Run with verbose output to debug

## Integration

Add to your dotfiles setup script:

```bash
#!/bin/bash
# setup.sh

# Check environment
python3 check_dev_environment.py
if [ $? -ne 0 ]; then
    echo "Some packages are missing. Install them? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        ./install_missing.sh
    fi
fi
```

---

**Pro Tip**: Run this checker after:
- Fresh macOS installations
- Setting up a new Mac
- Cloning your dotfiles to a new machine
- Major system updates
- Sharing your setup with team members
