# mise Overview

First-stop reference for `mise` (a.k.a. `mise-en-place`, `jdx/mise`) — the tool this repo is migrating to from `asdf` on the `feature-asdf-to-mise` branch. Optimized for Claude: only the small, stable, frequently-needed bits live inline. Anything reference-grade or fast-changing has a link with a *"WebFetch when..."* note so future sessions can decide whether the click is worth it.

Sister docs: [mise_configuration.md](./mise_configuration.md) · [asdf-to-mise-migration.md](../workflows/asdf-to-mise-migration.md)

## What mise is

A single Rust-based CLI that does three jobs at once:

1. **Dev-tool version manager** — installs and selects per-project versions of node, python, ruby, go, kubectl, etc.
2. **Environment-variable manager** — sets/clears env vars when you `cd` into a project.
3. **Task runner** — runs scripted tasks defined in `mise.toml` (think `make` / `just` replacement).

It is a **drop-in replacement for asdf**: it reads `.tool-versions` and can use asdf plugins, but it ditches asdf's shim layer in favor of `PATH` activation. Result: ~120ms shim overhead per command call disappears, replaced by a ~5–10ms Rust hook on directory change.

Homepage: <https://mise.jdx.dev>. Source: <https://github.com/jdx/mise>.

## Install

Inline what's likely to be used here; link out for the rest.

```bash
# macOS
brew install mise

# Linux (universal)
curl https://mise.run | sh
```

Distro packages exist for Debian/Ubuntu (`apt`), Fedora/RHEL (`dnf`), Arch (`pacman`), Alpine (`apk`).

> **WebFetch <https://mise.jdx.dev/installing-mise.html>** when you need: per-distro repo setup, GPG/APT signing keys, Windows install, or verifying release signatures.

## Shell activation (zsh)

This repo is zsh-first, so this is the canonical wiring:

```zsh
eval "$(mise activate zsh)"
```

That single line replaces the entire `~/.asdf/asdf.sh` + shim-PATH song-and-dance. Activation:

- adds the `mise` shims dir to `PATH` automatically (you don't need `mise` itself on `PATH` first);
- registers a `chpwd`-style hook so tool versions and env vars switch when you change directory;
- prints nothing by default — set `[settings.status].show_tools = true` in `mise.toml` if you want feedback.

**Activation vs shims** — both ship; you usually want activation. Shims are a fallback for non-interactive contexts (cron, IDE invocations) where the activation hook never runs. With activation, tools resolve via `PATH` rewrites — no per-call shim shell-script overhead.

Bash/fish equivalents and Windows PowerShell: see <https://mise.jdx.dev/installing-mise.html>.

## Core commands

The 90% of day-to-day usage. One-liners; none of these need WebFetch to use safely.

| Command | What it does |
|---|---|
| `mise use <tool>@<ver>` | Install (if needed) **and** add to nearest `mise.toml`. Primary command. |
| `mise install` | Install everything pinned by configs without modifying them. Run after `git clone`. |
| `mise run <task>` | Run a task defined in `[tasks]` (or `mise-tasks/`). Loads tools + env first. |
| `mise exec <tool>@<ver> -- <cmd>` | One-shot: run `cmd` with that tool active. No config edit. |
| `mise upgrade [--bump]` | Update installed tool versions. `--bump` allows major-version jumps. |
| `mise set KEY=VAL` | Add an env var to `mise.toml` `[env]`. |
| `mise ls` / `mise current` | List installed versions / show what's active here. |
| `mise which <bin>` | Print full path mise resolved a binary to (debugging PATH issues). |
| `mise doctor` | Health check — config files seen, plugins, shims, activation status. |
| `mise config ls` | Show every config file mise loaded for the current dir, in precedence order. |
| `mise trust [path]` | Mark a `mise.toml` as safe to load (security gate). |

## Comparison to asdf (key points)

- **Compatibility:** mise reads `.tool-versions` and can install asdf plugins via its `asdf:` backend. Existing asdf install **directories are not reused** — tools must be reinstalled under mise.
- **No shim tax:** asdf shims add ~120ms to every binary call. mise activates by rewriting `PATH`; the per-`cd` hook costs ~5–10ms (Rust).
- **Native backends:** mise installs from `core` (mise-curated), `aqua`, `ubi`, `npm:`, `cargo:`, `pipx:`, `go:`, etc. — fewer hops through unmaintained third-party plugins.
- **One-step install + select:** `mise use node@20` does what asdf needed `plugin add` + `install` + `local`/`global` for.
- **Windows support** for non-asdf backends (asdf has none).
- **Known gotcha:** `asdf-go` ≥ 0.16 dropped `local`/`global` for `asdf set`, conflicting with mise's `set`. Use mise's native `go` backend instead of the asdf plugin.

> **WebFetch <https://mise.jdx.dev/dev-tools/comparison-to-asdf.html>** when evaluating compatibility edge cases or deciding whether to keep an asdf plugin around.

## When to dig deeper

| Need | URL | When to fetch |
|---|---|---|
| End-to-end walkthrough | <https://mise.jdx.dev/walkthrough.html> | First time touching mise; want a tutorial flow. |
| Backends (cargo/npm/ubi/aqua/go/pipx) | <https://mise.jdx.dev/dev-tools/backends/> | Picking a backend prefix, or a tool isn't in the registry. |
| Tasks reference | <https://mise.jdx.dev/tasks/> | Authoring non-trivial tasks: dependencies, args, file-based tasks, `usage` integration. |
| Environment variables | <https://mise.jdx.dev/environments/> | Doing anything fancy in `[env]`: secret backends, templating, redactions. |
| Settings catalog (~80 keys) | <https://mise.jdx.dev/configuration/settings.html> | Looking up any setting not covered in [mise_configuration.md](./mise_configuration.md). |
| Lockfiles / `locked` mode | <https://mise.jdx.dev/configuration/settings.html#locked> | Hardening CI installs against upstream-API drift. |
| `mise.toml` reference | <https://mise.jdx.dev/configuration.html> | Confirming exact precedence, environment-specific configs (`mise.<env>.toml`), `MISE_ENV`. |

## Repo-specific note

This repo is on `feature-asdf-to-mise`. For the migration plan (current asdf footprint, tool inventory, step-by-step swap), see [asdf-to-mise-migration.md](../workflows/asdf-to-mise-migration.md). For authoring `mise.toml`, see [mise_configuration.md](./mise_configuration.md).
