# Development Environment Checker

A comprehensive Python script to verify your development environment setup, including Homebrew packages, Sheldon, Chezmoi, and ASDF-managed tools.

## Features

- ✅ Checks all required Homebrew packages (formulas and casks)
- ✅ Verifies Sheldon installation (version 0.6.6, location ~/.local/bin)
- ✅ Verifies Chezmoi installation
- ✅ Checks all ASDF-managed tools and their versions
- ✅ Colored output for easy reading
- ✅ Detailed summary report
- ✅ Exit codes for CI/CD integration

## Requirements

- Python 3.6+
- Homebrew installed
- ASDF installed (optional, for ASDF checks)

## Usage

### Basic Usage

```bash
./check_dev_environment.py
```

or

```bash
python3 check_dev_environment.py
```

### What It Checks

#### 1. Homebrew Packages

Verifies installation of all packages from your setup history including:

- **Utilities**: duf, dust, dua-cli, ncdu, peco, bat, fzf, ripgrep, etc.
- **Development tools**: git, gh, neovim, vim, docker, etc.
- **Languages**: python, ruby, node, lua, etc.
- **Fonts**: Nerd Fonts and various monospace fonts
- **Libraries**: openssl, readline, sqlite, ffmpeg, etc.

#### 2. Sheldon

Checks:
- ✅ Installation status
- ✅ Location (should be in `~/.local/bin/sheldon`)
- ✅ Version (should be `0.6.6`)

If not installed, provides the installation command:
```bash
curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | \
  bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin --tag 0.6.6
```

#### 3. Chezmoi

Checks:
- ✅ Installation status
- ✅ Location
- ✅ Version

If not installed, provides the installation command:
```bash
sh -c "$(curl -fsLS chezmoi.io/get)" -- init -R --debug -v --apply https://github.com/bossjones/zsh-dotfiles.git
```

#### 4. ASDF-Managed Tools

Verifies the following tools and their versions:

| Tool | Expected Version |
|------|-----------------|
| github-cli | 2.35.0 |
| golang | 1.20.5 |
| helm-docs | 1.13.1 |
| helm | 3.14.2 |
| helmfile | 0.162.0 |
| k9s | 0.32.4 |
| kubectl | 1.26.12 |
| kubectx | 0.9.5 |
| kubetail | 1.6.20 |
| mkcert | 1.4.4 |
| neovim | 0.11.3 |
| opa | 0.62.1 |
| ruby | 3.2.1 |
| rye | 0.33.0 |
| shellcheck | 0.10.0 |
| shfmt | 3.7.0 |
| tmux | 3.5a |
| yq | 4.34.1 |

## Output Format

The script provides color-coded output:

- 🟢 **Green ✓**: Item is correctly installed
- 🔴 **Red ✗**: Item is missing or incorrect
- 🟡 **Yellow ⚠**: Warning (e.g., wrong version but still installed)

### Example Output

```
======================================================================
Checking Homebrew Packages
======================================================================

✓ duf
✓ dust
✗ dua-cli - NOT INSTALLED
✓ bat
...

Summary: 85/90 packages installed
5 packages missing

======================================================================
Checking Sheldon
======================================================================

✓ Sheldon is installed
  Location: /Users/username/.local/bin/sheldon
  Version: 0.6.6
✓ Location is correct (~/.local/bin/sheldon)
✓ Version is correct (0.6.6)

======================================================================
Checking Chezmoi
======================================================================

✓ Chezmoi is installed
  Location: /usr/local/bin/chezmoi
  Version: 2.47.0

======================================================================
Checking ASDF-Managed Tools
======================================================================

✓ github-cli @ 2.35.0
✓ golang @ 1.20.5
⚠ helm @ 3.15.0 (expected: 3.14.2)
✗ k9s - NOT INSTALLED (expected: 0.32.4)
...

======================================================================
Final Report
======================================================================

Brew Packages: 85/90 installed
ASDF Tools: 16/18 installed (15 correct versions)
Sheldon: ✓
Chezmoi: ✓

Issues Found: 7
```

## Exit Codes

- `0`: All checks passed
- `1`: One or more checks failed

This makes it suitable for use in CI/CD pipelines:

```bash
./check_dev_environment.py || echo "Environment setup incomplete!"
```

## Customization

You can modify the script to:

1. **Add more packages**: Edit the `packages` list in `check_all_brew_packages()`
2. **Change expected versions**: Edit the `tools` dictionary in `check_all_asdf_tools()`
3. **Skip certain checks**: Comment out the check methods in `run_all_checks()`

## Troubleshooting

### "Command not found: brew"

Install Homebrew first:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### "Command not found: asdf"

Install ASDF first:
```bash
brew install asdf
```

Then add to your shell configuration:
```bash
echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ~/.zshrc
source ~/.zshrc
```

### Missing Packages

To install all missing brew packages at once:

```bash
# Extract missing packages from the output
./check_dev_environment.py 2>&1 | grep "NOT INSTALLED" | awk '{print $2}' > missing_packages.txt

# Install them
xargs brew install < missing_packages.txt
```

## Integration with Your Dotfiles

You can add this script to your dotfiles repository and run it as part of your setup process:

```bash
# In your install.sh or similar
python3 check_dev_environment.py
if [ $? -ne 0 ]; then
    echo "⚠️  Some packages are missing. Continue anyway? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
```

## License

MIT

## Author

Based on the environment setup from bossjones/zsh-dotfiles
