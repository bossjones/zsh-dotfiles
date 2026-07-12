# Feature Flags Reference

Complete reference for all configuration flags, environment variables, and feature toggles in the zsh-dotfiles repository.

**Table of Contents:**
- [Chezmoi Feature Booleans](#chezmoi-feature-booleans)
- [Version Manager Selection](#version-manager-selection)
- [Identity Configuration](#identity-configuration)
- [Installation-Time Environment Variables](#installation-time-environment-variables)
- [Runtime Shell Variables](#runtime-shell-variables)
- [External CI Variables](#external-ci-variables)
- [Planned / Not Yet Live](#planned--not-yet-live)

---

## Chezmoi Feature Booleans

These boolean flags are collected by `home/.chezmoi.yaml.tmpl` and stored in your chezmoi
`data:`. Each is prompted with `promptBool` in interactive runs (default `false`).

> ⚠️ **Not every flag is wired up.** Toggling a flag only matters if some template actually
> reads it. As of this writing, only **`pyenv`**, **`opencv`**, and **`cuda`** are consumed by
> any `.tmpl`; **`ruby`, `nodejs`, `k8s`, and `fnm` are recorded but inert** — no template
> reads them, so flipping them changes nothing about what gets installed. This is verifiable
> with `grep -rl '\.<flag>' home/ --include='*.tmpl'`. See [Gotchas](gotchas.md#6-several-feature-flags-are-inert)
> for the full analysis. The table's **Actually consumed by** column reflects the *verified*
> reality, not the original intent.

| Flag | Default | Status | Actually consumed by (verified) |
|------|---------|--------|---------------------------------|
| `pyenv` | `false` | ✅ **Live** | `home/compat.sh.tmpl`, `home/compat.bash.tmpl`, `home/.chezmoiscripts/run_onchange_before_02-macos-install-pyenv.sh.tmpl`, `run_before-00-prereq-{centos,ubuntu}-pyenv.sh.tmpl` |
| `opencv` | `false` | ✅ **Live (Linux)** | `home/.chezmoiscripts/run_onchange_before_02-{centos,ubuntu}-install-opencv-deps.sh.tmpl` |
| `cuda` | `false` | ✅ **Live (Ubuntu/Oracle)** | `home/dot_sheldon/plugins.toml.tmpl`, `home/private_dot_config/sheldon/plugins.toml.tmpl` (loads the `cuda` module) |
| `ruby` | `false` | ⚠️ **Inert** | *(no `.tmpl` reads `.ruby`)* |
| `nodejs` | `false` | ⚠️ **Inert** | *(no `.tmpl` reads `.nodejs`)* |
| `k8s` | `false` | ⚠️ **Inert** | *(no `.tmpl` reads `.k8s`)* |
| `fnm` | `false` | ⚠️ **Inert** | *(no `.tmpl` reads `.fnm`)* |

### Prompt / Reuse Mechanism

- **Interactive mode only**: When running `chezmoi init` from a terminal (`stdinIsATTY`), the template prompts for each feature using `promptBool "flagname"`.
- **Caching**: Responses are cached in `~/.config/chezmoi/chezmoi.yaml` under `data:` after the first prompt.
- **Re-prompt**: To change a feature flag after initial setup, run:
  ```bash
  chezmoi init --data=false
  ```
  This clears cached data and shows all prompts again.
- **Non-interactive**: In CI or piped execution (`curl | sh`), `promptBool` uses the `--promptBool flag=value` CLI argument or falls back to the default (`false`).

**Example usage:**
```bash
# Interactive: will prompt in terminal
chezmoi init --source=.

# Non-interactive: use defaults
chezmoi init --source=. --promptBool ruby=true --promptBool k8s=true

# Re-prompt all data
chezmoi init --data=false
```

---

## Version Manager Selection

| Flag | Default | Prompt Key | What It Does | Notes |
|------|---------|-----------|--------------|-------|
| `version_manager` | `"asdf"` | `version_manager` | Selects runtime version manager (asdf or mise) | Prompted **outside** `if $interactive` block intentionally; CLI `--promptString version_manager=X` matches this key in non-TTY runs (Docker, CI) |

### Threading Behavior

The `version_manager` flag threads through the entire system:

1. **Prompt stage** (`home/.chezmoi.yaml.tmpl`): User selects asdf or mise
2. **Chezmoi data**: Stored in `~/.config/chezmoi/chezmoi.yaml` as `version_manager: asdf|mise`
3. **Template export** (`home/dot_zshrc.tmpl`): Exported as `export ZSH_DOTFILES_VERSION_MANAGER={{ .version_manager }}`
4. **Module gating** (`home/shell/asdf/env.zsh` and `home/shell/mise/path.zsh`): Check `ZSH_DOTFILES_VERSION_MANAGER` to decide which to source
5. **Sheldon plugins** (`home/dot_sheldon/plugins.toml.tmpl`): Conditionally loads asdf plugin only when `version_manager==asdf`
6. **Installation scripts** (`run_onchange_after_50-*.sh.tmpl`): Install tools via selected manager

For more details, see **[Version Managers](version-managers.md)**.

---

## Identity Configuration

These variables personalize the installation. Interactive prompts only; no boolean defaults.

| Variable | Default | Env Override | Prompt Shown | Purpose |
|----------|---------|--------------|--------------|---------|
| `name` | `"Malcolm Jones"` | None | Yes | Full name, used in git commits and system identity |
| `email` | `"bossjones@theblacktonystark.com"` | None | Yes | Email address, used in git commits |
| `computer_name` | `"boss workstation"` | `CM_computer_name` | Yes | macOS computer name (scutil --set ComputerName) |
| `hostname` | `"bossworkstation"` | `CM_hostname` | Yes | System hostname (scutil --set LocalHostName) |

**Example:**
```bash
# Override via environment variables
CM_computer_name="my-mac" CM_hostname="my-mac" chezmoi init --source=.

# CLI prompts (interactive)
chezmoi init --source=.
# Then enter name, email, computer name, hostname when prompted
```

---

## Installation-Time Environment Variables

Set by `install.sh` and consumed throughout the provisioning pipeline. Defined and exported in `install.sh`, also consumed by `scripts/smoke-test-docker.sh` and `.github/workflows/tests.yml`.

| Variable | Default | When Set | Purpose | File Consumed In |
|----------|---------|----------|---------|-----------------|
| `ZSH_DOTFILES_PREP_DEBUG` | `1` | `install.sh:57` | Enable debug output in prereq installer and chezmoi | `install.sh`, `scripts/smoke-test-docker.sh` |
| `ZSH_DOTFILES_PREP_GITHUB_USER` | `bossjones` | `install.sh:58` | GitHub username for cloning repos (bossjones/zsh-dotfiles-prep) | `install.sh:251`, `scripts/smoke-test-docker.sh:50` |
| `ZSH_DOTFILES_PREP_SKIP_BREW_BUNDLE` | `1` | `install.sh:59` | Skip `brew bundle` (heavy package installation) during prereq | `install.sh`, `scripts/smoke-test-docker.sh:51` |
| `ZSH_DOTFILES_PREP_CI` | `1` if `$CI` or `$GITHUB_ACTIONS` else `0` | `install.sh:68-72` | Indicates running in CI environment (GitHub Actions, etc.) | `install.sh`, `scripts/smoke-test-docker.sh:48` |
| `ZSH_DOTFILES_NONINTERACTIVE` | `1` if piped execution (`curl \| sh`), else `0` | `install.sh:76-82` | Indicates non-interactive mode (piped, no TTY) | `install.sh` (used to clone repo vs. use local) |
| `ZSH_DOTFILES_SKIP_LUNARVIM` | `0` (default: install) | `install.sh:60` | Skip LunarVim installation | `install.sh:374-393` |
| `ZSH_DOTFILES_SKIP_TESTS` | `0` (default: run tests) | `install.sh:61` | Skip running pytest suite after install | `install.sh:428-447` |
| `SHELDON_VERSION` | `"0.6.6"` | `install.sh:63` | Sheldon plugin manager version to install | `install.sh:152-205` |
| `SHELDON_CONFIG_DIR` | `"$HOME/.sheldon"` | `install.sh:64` | Sheldon config directory | `install.sh`, `home/.chezmoi.yaml.tmpl:scriptEnv` |
| `SHELDON_DATA_DIR` | `"$HOME/.sheldon"` | `install.sh:65` | Sheldon data directory | `install.sh`, `home/.chezmoi.yaml.tmpl:scriptEnv` |

### Setting Install-Time Variables

```bash
# Set via environment when piping install script
export ZSH_DOTFILES_PREP_DEBUG=1
export ZSH_DOTFILES_SKIP_LUNARVIM=1
curl -fsSL https://raw.githubusercontent.com/bossjones/zsh-dotfiles/main/install.sh | sh

# Or inline
ZSH_DOTFILES_PREP_DEBUG=1 ZSH_DOTFILES_SKIP_TESTS=1 ./install.sh
```

---

## Runtime Shell Variables

Set by chezmoi templates during `chezmoi init --apply` and available in the running shell (`~/.zshrc`).

| Variable | Set In | Consumed By | Purpose |
|----------|--------|------------|---------|
| `ZSH_DOTFILES_VERSION_MANAGER` | `home/dot_zshrc.tmpl:9` | `home/shell/asdf/env.zsh`, `home/shell/asdf/path.zsh`, `home/shell/mise/env.zsh`, `home/shell/mise/path.zsh` | Determines which version manager (asdf or mise) to initialize. Checked by conditional `if [ "${ZSH_DOTFILES_VERSION_MANAGER}" = "asdf" ]` in env/path modules. |

### Functions That Use It

- `enable_asdf()` / `enable_mise()` / `enable_version_manager()` in `home/shell/customs/aliases.zsh` - switch between managers at runtime
- Sheldon conditional plugin loading: asdf plugin only loaded when `version_manager==asdf`

**Example:**
```bash
# Check which version manager is active
echo $ZSH_DOTFILES_VERSION_MANAGER  # Output: asdf or mise

# In shell code
if [ "$ZSH_DOTFILES_VERSION_MANAGER" = "asdf" ]; then
    # asdf-specific setup
fi
```

---

## External CI Variables

These are set by the CI environment (GitHub Actions, Docker, Codespaces) and detected by `install.sh` and `scripts/smoke-test-docker.sh`.

| Variable | Set By | Detected As | Purpose |
|----------|--------|------------|---------|
| `$CI` | GitHub Actions, generic CI | Generic CI flag (supported by most CI systems) | Triggers non-interactive mode, skips user prompts |
| `$GITHUB_ACTIONS` | GitHub Actions specifically | GitHub Actions flag | Triggers CI-specific setup (retries, caching) |
| `$CODESPACES` | GitHub Codespaces | Codespaces development environment | Indicates running in ephemeral dev container |

**Detection logic** (`install.sh:68-74`):
```bash
if [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ]; then
    ZSH_DOTFILES_PREP_CI=1
else
    ZSH_DOTFILES_PREP_CI=0
fi
```

When `ZSH_DOTFILES_PREP_CI=1`:
- Prompts are suppressed (non-interactive mode)
- Retries are enabled for flaky network operations
- LunarVim is auto-installed (skip prompt)
- Tests run automatically (if `ZSH_DOTFILES_SKIP_TESTS=0`)

---

## Planned / Not Yet Live

These flags appear in design specs (`specs/migrate-asdf-to-mise.md`) or logs but are **not yet implemented** in active source code. Confirmed by grep showing they do not exist in `install.sh`.

| Variable | Planned Purpose | Status | Notes |
|----------|-----------------|--------|-------|
| `ZSH_DOTFILES_PREP_SKIP_ASDF` | Skip asdf installation during prereq phase | Planned | Would allow switching to mise-only installs earlier; not yet in `install.sh` |
| `ZSH_DOTFILES_PREP_STEP` | Control which install step to run (lint, build, test, etc.) | Planned | Fine-grained control over install phases; smoke-test-docker.sh uses stages instead |
| `ZSH_DOTFILES_PREP_INTERACTIVE` | Force interactive mode in piped execution | Planned | Currently detected automatically; might be useful for unattended prompts |
| `ZSH_DOTFILES_PREP_ISSUES_URL` | Override GitHub Issues URL for diagnostics | Planned | Would route error reporting; not yet implemented |

These may be implemented in a future migration to [mise](https://mise.jdx.dev/) as the primary version manager.

---

## Cross-References

- **[Version Managers](version-managers.md)** - Deep-dive on asdf ⇄ mise threading
- **[Testing &amp; CI](testing-and-ci.md)** - GitHub workflows and how they set these flags
- **[Installation](installation.md)** - Complete installation guide
- **[Gotchas](gotchas.md)** - Inert flags and other known warts
- **[Tutorial: switch version manager](tutorials/04-switch-version-manager.md)** - How to switch between asdf and mise
- **[home/.chezmoi.yaml.tmpl](../home/.chezmoi.yaml.tmpl)** - Source: feature boolean defaults and templates
- **[install.sh](../install.sh)** - Source: installation-time variables and logic
- **[scripts/smoke-test-docker.sh](../scripts/smoke-test-docker.sh)** - Source: Docker smoke test variable consumption
