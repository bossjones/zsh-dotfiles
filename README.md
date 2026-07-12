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

## Chezmoi Run Modes

### Interactive (default)

On first run, chezmoi prompts for your configuration. Answers are cached in `~/.config/chezmoi/chezmoi.yaml` and reused on subsequent runs.

```sh
chezmoi init -R --debug -v --apply https://github.com/bossjones/zsh-dotfiles.git
```

### Re-run Prompts

Reset cached answers and re-enter all prompts:

```sh
chezmoi init --data=false https://github.com/bossjones/zsh-dotfiles.git
```

### Non-interactive with Environment Variables

`CM_computer_name` and `CM_hostname` pre-populate those prompts so they are skipped silently:

```sh
CM_computer_name="my-mac" CM_hostname="mymac" chezmoi init --apply https://github.com/bossjones/zsh-dotfiles.git
```

### Dry-run (preview without applying)

See what would change without touching any files:

```sh
chezmoi apply --dry-run --verbose
```

### Verbose Apply

```sh
chezmoi apply -v
```

### Interactive Prompts Reference

All prompts surfaced during first-time `chezmoi init`. Cached answers from a previous run are reused automatically.

| Prompt | Type | Default | Description |
|--------|------|---------|-------------|
| `Name` | string | `Malcolm Jones` | Your full name |
| `Email` | string | *(your email)* | Your email address |
| `Computer name` | string | `boss workstation` | Human-readable machine name |
| `Host name` | string | `bossworkstation` | Short hostname |
| `Version manager (asdf or mise)` | string | `asdf` | Runtime version manager to install |
| `ruby` | bool | `false` | Install Ruby via version manager |
| `pyenv` | bool | `false` | Install pyenv for Python version management |
| `nodejs` | bool | `false` | Install Node.js via version manager |
| `k8s` | bool | `false` | Install Kubernetes toolchain |
| `cuda` | bool | `false` | Install CUDA support |
| `fnm` | bool | `false` | Install fnm (Fast Node Manager) |
| `opencv` | bool | `false` | Install OpenCV system dependencies |
| `fzf_tab` | bool | `false` | Replace zsh's completion menu with an fzf selector ([fzf-tab](https://github.com/Aloxaf/fzf-tab)) |

---

## Installed Features

The main tools and features installed and configured by this repo. Optional features are gated behind interactive prompts (noted below).

| Tool | Description |
|------|-------------|
| **zsh** | Shell with extensive config, history, keybindings, and completions |
| **sheldon** | ZSH plugin manager with deferred loading for fast startup |
| **pure** | Minimal async ZSH prompt |
| **tmux** | Terminal multiplexer with tpm and oh-my-tmux config |
| **neovim** | Text editor installed via version manager (AstroVim config) |
| **fzf** | Fuzzy finder with custom keybindings and shell integration |
| **ripgrep** | Fast recursive text search (`rg`) |
| **fd** | Fast file finder |
| **jq** | Lightweight command-line JSON processor |
| **yq** | YAML / JSON processor (jq-style) |
| **gh** | GitHub CLI for PRs, issues, and repo management |
| **direnv** | Per-directory environment variable manager |
| **uv** | Fast Python package and project manager (Astral) |
| **asdf** | Multi-language runtime version manager *(default; use mise as alternative)* |
| **mise** | Modern polyglot runtime version manager *(alternative to asdf)* |
| **pyenv** | Python version manager *(optional — `pyenv` prompt)* |
| **ruby** | Ruby runtime via version manager *(optional — `ruby` prompt)* |
| **golang** | Go runtime via version manager |
| **fnm** | Fast Node Manager for Node.js versions *(optional — `fnm` prompt)* |
| **bun** | JavaScript runtime, bundler, and package manager |
| **deno** | Secure JavaScript/TypeScript runtime |
| **shellcheck** | Shell script static analysis / linter |
| **shfmt** | Shell script formatter |
| **mkcert** | Create locally-trusted SSL certificates |
| **cheat** | CLI cheatsheet tool with community and personal sheets |
| **kubectl** | Kubernetes CLI *(optional — `k8s` prompt)* |
| **helm** | Kubernetes package manager *(optional — `k8s` prompt)* |
| **k9s** | Interactive Kubernetes cluster TUI *(optional — `k8s` prompt)* |
| **krew** | kubectl plugin manager *(optional — `k8s` prompt)* |
| **kubectx** | Switch between Kubernetes contexts *(optional — `k8s` prompt)* |
| **opa** | Open Policy Agent CLI *(optional — `k8s` prompt)* |
| **fzf-tab** | fzf-powered Tab completion *(optional — `fzf_tab` prompt)* |

---

## fzf-tab (optional)

[fzf-tab](https://github.com/Aloxaf/fzf-tab) replaces zsh's completion menu with an fzf
selector. It is **off by default** and gated behind the `fzf_tab` chezmoi flag; with the
flag off, the rendered shell configuration is byte-identical to a checkout without the
feature.

> Full tutorial (activation, keybindings, toggling, troubleshooting): [docs/fzf-tab.md](docs/fzf-tab.md)

### Enabling

```bash
chezmoi init --promptBool fzf_tab=true   # first init (or non-TTY / CI)
chezmoi apply
exec zsh
```

Requires `fzf` on `$PATH` (already provisioned by this repo). If fzf is missing, fzf-tab
is never sourced and stock Tab completion keeps working.

### Daily use

- **Tab** opens the fzf selector; type to filter, **Enter** accepts.
- **F1 / F2** switch between completion groups (e.g. files vs. options).
- **/** (continuous trigger) accepts the current match and immediately re-triggers
  completion — handy for descending directories.
- **Ctrl-Space** multi-selects candidates.
- Inside tmux ≥ 3.2 the selector renders in a tmux popup (`ftb-tmux-popup`); elsewhere it
  falls back to inline fzf.
- Optional speedup for very large directories: run `build-fzf-tab-module` once by hand
  and restart zsh (needs a C toolchain, git, and network; deliberately not part of
  provisioning).

### Switching back — three toggle layers, cheapest first

1. **`toggle-fzf-tab`** — plugin built-in, instant, current shell only
   (`disable-fzf-tab` / `enable-fzf-tab` for one-way switches).
2. **`fzf-tab-off` / `fzf-tab-on`** — persistent across all new shells, no chezmoi.
   Backed by the sentinel file
   `${XDG_CONFIG_HOME:-$HOME/.config}/zsh-dotfiles/fzf-tab-disabled`; while it exists,
   new shells never even source fzf-tab.
3. **Full removal** — after the first init the flag is stored in
   `~/.config/chezmoi/chezmoi.yaml`, and because of the `hasKey` pattern a later
   `chezmoi init --promptBool fzf_tab=false` will **not** flip it (stored keys
   short-circuit the prompt). Edit `data.fzf_tab: false` in that file, then
   `chezmoi apply && exec zsh` (or `chezmoi init --data=false` to re-prompt
   everything). This restores the byte-identical stock config.

---

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
