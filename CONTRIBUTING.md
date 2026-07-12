# Contributing

> How to work in this repository day to day: environment setup, pre-commit hooks, editing chezmoi templates safely, running the test suite, adding a tool module, and where documentation lives.

**See also:** [README.md](README.md) · [docs/architecture.md](docs/architecture.md) · [docs/tutorials/README.md](docs/tutorials/README.md)

---

## Getting the code

```sh
git clone https://github.com/bossjones/zsh-dotfiles.git
cd zsh-dotfiles
```

Working on more than one branch at once? Use a [git worktree](https://git-scm.com/docs/git-worktree) instead of juggling stashes:

```sh
git worktree add ../zsh-dotfiles-feature-x -b feature-x
cd ../zsh-dotfiles-feature-x
```

Each worktree is a separate checkout sharing the same `.git` history, so you can keep `main` clean in one directory while iterating on a branch in another.

---

## One-time environment setup

This repo uses [`uv`](https://docs.astral.sh/uv/) for Python dependency management:

```sh
make sync
```

`make sync` runs [`uv sync --all-extras`](Makefile) followed by `uv run pre-commit install`, so your Python environment and the git hooks are set up in one step. If you only want the hooks (e.g. you already have a `uv` venv):

```sh
make install-hooks   # uv venv --python 3.12 && uv run pre-commit install
```

---

## Pre-commit hooks

Hooks are defined in [`.pre-commit-config.yaml`](.pre-commit-config.yaml) and installed via `make sync` / `make install-hooks`. They run automatically on `pre-commit`, `commit-msg`, and `pre-push` (see `default_install_hook_types` in the config).

| Hook | Repo | What it checks |
|------|------|-----------------|
| `alphabetize-codeowners`, `fix-smartquotes`, `fix-ligatures` | [sirosen/texthooks](https://github.com/sirosen/texthooks) | Text hygiene (CODEOWNERS ordering, smart quotes, ligatures) |
| `prettier` | [pre-commit/mirrors-prettier](https://github.com/pre-commit/mirrors-prettier) | Formats YAML/JSON (excludes hand-formatted JSONC files) |
| `check-jsonc` | local (`scripts/check-jsonc.py`) | Validates JSON-with-comments files (read-only; never rewrites) |
| `check-ast`, `check-json`, `check-case-conflict`, `check-merge-conflict`, `check-symlinks`, `end-of-file-fixer`, `mixed-line-ending`, `trailing-whitespace` | [pre-commit/pre-commit-hooks](https://github.com/pre-commit/pre-commit-hooks) | General file hygiene |
| `python-no-log-warn`, `text-unicode-replacement-char` | [pre-commit/pygrep-hooks](https://github.com/pre-commit/pygrep-hooks) | Python/text lint patterns |
| `check-github-workflows`, `check-readthedocs` | [python-jsonschema/check-jsonschema](https://github.com/python-jsonschema/check-jsonschema) | Schema-validates GitHub Actions workflows |
| `actionlint` | [rhysd/actionlint](https://github.com/rhysd/actionlint) | Lints `.github/workflows/*.yml` |

Run every hook against the whole repo (what CI/pre-commit.ci effectively does):

```sh
make pre-commit    # uv run pre-commit run -a
```

`pre-commit.ci` also autofixes and autoupdates hooks on a weekly schedule (see the `ci:` block in `.pre-commit-config.yaml`).

---

## Editing chezmoi templates, the safe way

Most of this repo's behavior lives in `.tmpl` files under `home/`. Never eyeball a rendered guess — render it:

```sh
# Render a single template file to stdout, no side effects
chezmoi execute-template < home/dot_zshrc.tmpl

# Inspect exactly what data values templates see (name, email, version_manager, feature flags, …)
chezmoi data

# Sanity-check chezmoi's own health and template syntax across the whole source
chezmoi doctor
```

Before applying anything for real, preview the diff:

```sh
chezmoi diff --source=.
# or
chezmoi apply --dry-run --verbose --source=.
```

Only once the diff looks right:

```sh
chezmoi apply -v --source=.
```

> This workstation's owner runs `chezmoi apply` for real day to day, but when you're iterating on a template, `chezmoi execute-template` and `chezmoi diff` are the fast, side-effect-free feedback loop — use them first.

---

## Running the test suite

```sh
make test          # py.test --tb=short --no-header --showlocals --reruns 6 test_dotfiles.py test_scripts_backup_dotfiles.py test_scripts_check_jsonc.py
make test-pdb       # same, with the bpdb debugger on failure
make uv-test        # same tests, run through `uv run pytest` (locked deps)
```

Tests use [`pytest`](https://docs.pytest.org/) with [`libtmux`](https://github.com/tmux-python/libtmux) to drive real tmux sessions — this is how the suite exercises interactive zsh behavior (prompt, aliases, tool availability) without a human at the keyboard. `conftest.py` provides the tmux fixtures; see [docs/testing-and-ci.md](docs/testing-and-ci.md) for the full fixture model.

### Reproducing CI locally in Docker

```sh
make smoke              # full smoke test, VERSION_MANAGER=asdf (default)
make smoke-mise         # same, VERSION_MANAGER=mise
make smoke-lint         # lint stage only (pre-commit + chezmoi diff)
make smoke-build        # build stage only
make smoke-asdf-shell   # interactive shell for debugging, asdf lane
make smoke-mise-shell   # interactive shell for debugging, mise lane
make smoke-clean        # tear down Docker resources
```

Full walkthrough, including what each stage's pass/fail actually means: **[Tutorial 05: Run smoke tests locally](docs/tutorials/05-run-smoke-tests-locally.md)** and **[docs/testing-and-ci.md](docs/testing-and-ci.md)**.

---

## How to add a new tool module

Follow the `home/shell/<tool>/` convention — sheldon auto-discovers files by glob, so there is **no registration step** in `plugins.toml.tmpl` for the common case.

1. **Create the directory**: `home/shell/<tool>/`
2. **Add `env.zsh`** for environment variables (auto-sourced immediately via sheldon's `[plugins.env]`, which globs `**/env.zsh`)
3. **Add `path.zsh`** for `PATH` additions (auto-sourced immediately via `[plugins.path]`, globbing `**/path.zsh`)
4. *(optional)* **Add `completion.zsh` / `keybinding.zsh`** for anything that should load deferred, after the first prompt (globbed by `[plugins.local]`)
5. *(optional)* **Add `aliases.zsh`** for tool-specific aliases (globbed by `[plugins.aliases]`)
6. **Match the exact basename.** The globs (`home/dot_sheldon/plugins.toml.tmpl`) match filenames literally — `env.zsh` matches, `myenv.zsh` does not.
7. **Preview, then apply**: `chezmoi diff --source=.` then `chezmoi apply -v --source=.`
8. **Verify it loaded**: `sheldon source | less` (see the exact line sourcing your file) or open a fresh shell and check the variable/PATH entry directly

[`home/shell/fzf/`](home/shell/fzf/) is the fullest worked example (`env.zsh`, `path.zsh`, `completion.zsh`, `keybinding.zsh`); [`home/shell/go/env.zsh`](home/shell/go/env.zsh) is a minimal one. Full step-by-step: **[Tutorial 02: Add a tool module](docs/tutorials/02-add-a-tool-module.md)**. Background on the glob mechanism and full plugin load order: **[docs/shell-loading.md](docs/shell-loading.md)**.

---

## Documentation conventions

| Kind of page | Lives in | Example |
|---|---|---|
| Reference docs (one topic, deep dive) | `docs/*.md` | `docs/feature-flags.md`, `docs/version-managers.md` |
| Hands-on, goal-oriented tutorials | `docs/tutorials/NN-slug.md` | `docs/tutorials/00-first-time-setup.md` |
| Repo-wide contributor guidance | Root `CONTRIBUTING.md` (this file) | — |
| Machine-consumable instructions for AI coding agents | Root `CLAUDE.md` | — |

- **Tutorials are numbered** (`00`–`06`) to suggest a learning order; see the index at [docs/tutorials/README.md](docs/tutorials/README.md).
- **Every tutorial ends with a "Verify" section** showing exactly how to confirm success — don't skip it when adding a new one.
- **Diagrams use GitHub-native [Mermaid](https://mermaid.js.org/)** fenced blocks (` ```mermaid `), not images, so they render directly on GitHub and stay diffable in PRs.
- **Cross-reference with relative links** (e.g. `[docs/feature-flags.md](feature-flags.md)` from another file in `docs/`, `../home/...` from `docs/` back into source) so links keep working in forks and local checkouts alike.
- **Cite real commands only.** Before documenting a command, flag, or path, open the source file it comes from and confirm it — this repo's docs are meant to be copy-pasteable, not aspirational.

---

## Where to go next

- **[docs/installation.md](docs/installation.md)** — full onboarding flow for a new machine
- **[docs/architecture.md](docs/architecture.md)** — system overview
- **[docs/feature-flags.md](docs/feature-flags.md)** — every prompt, flag, and environment variable
- **[docs/tutorials/README.md](docs/tutorials/README.md)** — the full hands-on tutorial track
