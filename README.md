# zsh-dotfiles

A comprehensive dotfiles management system using [chezmoi](https://www.chezmoi.io/) for ZSH configuration and customization.

## Overview

This repository contains dotfiles managed with chezmoi, focusing on:

- ZSH configuration and customization
- Shell aliases and functions
- Plugin management with [sheldon](https://sheldon.cli.rs/)
- Cross-platform compatibility (macOS, Linux)
- AI-powered documentation and analysis

## Repository Structure

```
.
├── .cursor/                     # Cursor editor configuration
│   └── rules/                   # Cursor rules for AI assistance
├── .github/                     # GitHub configuration and workflows
├── .vscode/                     # VS Code configuration
├── ai_docs/                     # AI-generated documentation
│   ├── reports/                 # Analysis reports
│   └── summaries/               # Code summaries
├── hack/                        # Development scripts and tools
├── home/                        # Main dotfiles directory (chezmoi root)
│   ├── dot_zshrc                # ZSH main configuration file
│   ├── dot_zshenv               # ZSH environment variables
│   ├── private_dot_config/      # Configuration files (.config directory)
│   └── ...                      # Other dotfiles managed by chezmoi
├── .chezmoiroot                 # Specifies home as the chezmoi root directory
├── .chezmoiversion              # Specifies the minimum chezmoi version
├── Makefile                     # Build automation
├── conftest.py                  # Pytest configuration
├── test_dotfiles.py             # Dotfiles tests
└── requirements-test.txt        # Test dependencies
```

## Installation

### One-line Installation

```sh
sh -c "$(curl -fsLS chezmoi.io/get)" -- init -R --debug -v --apply https://github.com/bossjones/zsh-dotfiles.git
```

### Manual Installation

1. Install chezmoi:
   ```sh
   sh -c "$(curl -fsLS chezmoi.io/get)"
   ```

2. Initialize with this repository:
   ```sh
   chezmoi init -R --debug -v --apply https://github.com/bossjones/zsh-dotfiles.git
   ```

## Usage

### Updating Dotfiles

Pull the latest changes from the repository:

```sh
chezmoi git pull -- --autostash --rebase
```

Apply the changes:

```sh
chezmoi apply
```

### Customizing Your Configuration

Chezmoi uses Go's text/template system to transform template files into actual configuration files. This allows for dynamic configuration based on your system environment.

#### Common Template Variables

| Variable | Description | Example Values |
|----|----|---|
| `.chezmoi.os` | Operating system | "darwin", "linux" |
| `.chezmoi.arch` | Architecture | "amd64", "arm64" |
| `.chezmoi.hostname` | Host name | "macbook-pro" |
| `.chezmoi.username` | User name | "username" |

#### Example Transformations

| Original Template | Rendered Result | Description |
|----|-----|----|
| `{{ if eq .chezmoi.os "darwin" }}source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh{{ else }}source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh{{ end }}` | `source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh` (on macOS) | Loads zsh-autosuggestions from the appropriate location based on OS |

## Troubleshooting

If you encounter issues with template rendering:

1. Use `chezmoi execute-template` to test template rendering:
   ```bash
   chezmoi execute-template < ~/.local/share/chezmoi/dot_zshrc.tmpl
   ```

2. Check the values of variables:
   ```bash
   chezmoi data
   ```

3. Verify template syntax:
   ```bash
   chezmoi doctor
   ```

## Additional Resources

- [Chezmoi Documentation](https://www.chezmoi.io/user-guide/command-overview/)
- [Go Templates Documentation](https://pkg.go.dev/text/template)
- [Sheldon Plugin Manager](https://sheldon.cli.rs/)

<details>
    <summary>Notes</summary>

## Manual steps

</details>
