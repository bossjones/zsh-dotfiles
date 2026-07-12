# Tutorial 01: Daily Workflow

> The everyday loop: pull upstream changes, preview them, apply them, and edit a managed file the chezmoi way.

**See also:** [Tutorial 00: First-Time Setup](00-first-time-setup.md) · [Tutorials index](README.md) · [docs/architecture.md](../architecture.md)

---

## What you'll learn

- How to pull the latest repo changes without losing local edits
- How to preview a `chezmoi apply` before it touches your home directory
- How to edit a managed dotfile the correct way (through its chezmoi source, not the deployed copy)

**Prerequisites:** [Tutorial 00](00-first-time-setup.md) completed — chezmoi already initialized on this machine.

**Time estimate:** 5 minutes.

---

## Step 1: Pull the latest changes

```sh
chezmoi git pull -- --autostash --rebase
```

This runs `git pull --autostash --rebase` inside chezmoi's source directory (`~/.local/share/chezmoi` by default). `--autostash` stashes and restores any local uncommitted edits to the source around the rebase, so you don't lose in-progress work; `--rebase` keeps history linear instead of creating merge commits.

Source: [README.md](../../README.md#updating-dotfiles).

---

## Step 2: Preview before applying

Don't apply blind — see what would change first:

```sh
chezmoi diff
```

or, equivalently:

```sh
chezmoi apply --dry-run --verbose
```

Both show you the exact diff between the current target state (your home directory) and what chezmoi would write, without touching anything.

---

## Step 3: Apply

Once the diff looks right:

```sh
chezmoi apply
```

Add `-v` for verbose output while it runs:

```sh
chezmoi apply -v
```

This is also the point where any `run_onchange_*` scripts whose rendered content changed (a version bump, a new conditional, etc.) will re-run. See [docs/provisioning-scripts.md](../provisioning-scripts.md) for the full script lifecycle.

---

## Step 4: Edit a managed file

Don't edit the deployed file directly (e.g. `~/.zshrc`) — your changes will be silently overwritten on the next `chezmoi apply`. Instead, edit the **source** file through chezmoi:

```sh
chezmoi edit ~/.zshrc
```

This opens the corresponding source template (`home/dot_zshrc.tmpl` in the chezmoi source directory) in `$EDITOR`. After saving, preview and apply the same way as above:

```sh
chezmoi diff
chezmoi apply -v
```

If the file you edited is a `.tmpl`, you can render it in isolation first to make sure the template syntax is valid before applying:

```sh
chezmoi execute-template < ~/.local/share/chezmoi/home/dot_zshrc.tmpl
```

---

## Verify

```sh
# Confirm the pull actually moved the source forward (or reports already up to date)
chezmoi git -- log --oneline -1

# Confirm there's nothing outstanding to apply
chezmoi diff
# (no output = target state matches source state)

# Confirm chezmoi itself is still healthy after your edits
chezmoi doctor
```

If `chezmoi diff` shows unexpected output after you thought you'd applied everything, re-run `chezmoi apply -v` — some `run_onchange_*` scripts only re-trigger on the *next* apply after their rendered content changes.

---

## Next steps

- **[Tutorial 02: Add a Tool Module](02-add-a-tool-module.md)** — extend the shell with your own tool config
- **[Tutorial 03: Toggle a Feature Flag](03-toggle-a-feature-flag.md)** — turn an optional install on or off
- **[docs/installation.md](../installation.md)** — full installation reference
