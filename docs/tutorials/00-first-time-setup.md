# Tutorial 00: First-Time Setup

> Take a fresh macOS/Linux machine from nothing to a fully provisioned, chezmoi-managed zsh shell.

**See also:** [docs/installation.md](../installation.md) (full reference) · [Tutorials index](README.md) · [docs/feature-flags.md](../feature-flags.md)

---

## What you'll learn

- How to bootstrap this repo onto a brand-new machine using the one-liner or `install.sh`
- What every prompt during `chezmoi init` means and what to answer
- How to confirm the install actually succeeded

**Prerequisites:** macOS or Linux, a terminal, and (on macOS) [Homebrew](https://brew.sh) installed. No prior chezmoi experience required.

**Time estimate:** 20–45 minutes (mostly waiting on Homebrew/tool installs).

**Final result:** A new interactive zsh shell with the `pure` prompt, sheldon-managed plugins, and your chosen version manager (`asdf` or `mise`) ready to use.

---

## Step 1: Choose your install path

For a genuinely new machine, use either the one-liner or `install.sh` (which mirrors CI exactly, including the external prereq installer). Both are documented in full in [docs/installation.md](../installation.md); this tutorial walks the one-liner path.

```sh
# Installs chezmoi, fetches this repo, and prompts you before applying
sh -c "$(curl -fsLS chezmoi.io/get)" -- init -R --debug -v https://github.com/bossjones/zsh-dotfiles.git
```

> Notice this omits `--apply` on purpose, so you get to preview before anything touches your home directory — see Step 3.

---

## Step 2: Answer the prompts

`chezmoi init` walks you through these prompts (source: [`home/.chezmoi.yaml.tmpl`](../../home/.chezmoi.yaml.tmpl)):

| Prompt | What to enter | Default |
|--------|----------------|---------|
| `Name` | Your full name | `Malcolm Jones` |
| `Email` | Your email address | *(your email)* |
| `Computer name` | A human-readable name for this machine | `boss workstation` |
| `Host name` | A short hostname | `bossworkstation` |
| `version_manager` | `asdf` or `mise` | `asdf` |
| `ruby` | `true`/`false` — install Ruby? | `false` |
| `pyenv` | `true`/`false` — install pyenv? | `false` |
| `nodejs` | `true`/`false` — install Node.js? | `false` |
| `k8s` | `true`/`false` — install Kubernetes tools? | `false` |
| `cuda` | `true`/`false` — install CUDA support? | `false` |
| `fnm` | `true`/`false` — install fnm? | `false` |
| `opencv` | `true`/`false` — install OpenCV deps? | `false` |

If you're not sure, accepting the defaults (just Ruby/Python/Node.js/k8s/CUDA/fnm/OpenCV all off, `asdf` as the version manager) is a safe first run — you can always re-prompt later with `chezmoi init --data=false` (see [Tutorial 03](03-toggle-a-feature-flag.md)).

Answers are cached in `~/.config/chezmoi/chezmoi.yaml` so you won't be asked again on the next `chezmoi apply`.

---

## Step 3: Preview, then apply

```sh
# See exactly what chezmoi would change
chezmoi diff
# or
chezmoi apply --dry-run --verbose

# Looks right? Apply for real.
chezmoi apply -v
```

This is the point where your `~/.zshrc`, `~/.sheldon/plugins.toml`, and the rest of the managed dotfiles get written, and chezmoi's `run_` scripts install Homebrew/apt packages, your version manager, sheldon, and so on. See [docs/provisioning-scripts.md](../provisioning-scripts.md) if you want the full blow-by-blow of what runs when.

---

## Step 4: Run `post-install-chezmoi`

After `chezmoi apply` finishes, run the post-install script it deploys to `~/.bin/post-install-chezmoi`:

```sh
~/.bin/post-install-chezmoi
```

(If you used `install.sh` instead of the one-liner, this already ran for you automatically, wrapped in `retry -t 4`.)

---

## Step 5 (optional): Prefer the full CI-mirroring path?

Instead of Steps 1–4, you can run [`install.sh`](../../install.sh) directly — it performs the same chezmoi steps plus the Homebrew bootstrap, the external `zsh-dotfiles-prep` prereq installer, and optional LunarVim/tests, in the exact order CI uses:

```sh
./install.sh
```

Full breakdown of every stage: [docs/installation.md#option-3-installsh-mirrors-ci-end-to-end](../installation.md#option-3-installsh-mirrors-ci-end-to-end).

---

## Verify

Open a **new** interactive shell (don't just re-source — start a fresh terminal tab/window so sheldon's full plugin chain loads):

```sh
zsh
```

1. **Prompt loaded** — you should see the minimal, async [`pure`](https://github.com/sindresorhus/pure) prompt (your current directory, and a git branch when inside a repo), not the default `%` prompt.

2. **Sheldon is installed and sourcing plugins:**
   ```sh
   sheldon --version
   ```
   should print a version (e.g. `sheldon 0.6.6`), not "command not found".

3. **chezmoi is healthy:**
   ```sh
   chezmoi doctor
   ```
   should complete without fatal errors (warnings about optional tools you skipped, like `k8s` binaries, are expected and fine).

4. **Your version manager is active:**
   ```sh
   echo $ZSH_DOTFILES_VERSION_MANAGER   # asdf or mise, matching what you chose
   ```

If any of these fail, see the [Troubleshooting section of docs/installation.md](../installation.md#troubleshooting) — `chezmoi execute-template`, `chezmoi data`, and `chezmoi doctor` are your three go-to diagnostic commands.

---

## Next steps

- **[Tutorial 01: Daily Workflow](01-daily-workflow.md)** — pulling updates and applying them safely, day to day
- **[docs/feature-flags.md](../feature-flags.md)** — the full flag reference if you want to understand every prompt in depth
