# Plan: Repository cleanup — dead code, inert flags, and mis-named scripts

## Task Description

During the documentation overhaul of this repo, a source-grounded audit surfaced six
concrete, verified issues: dead code, configuration that silently does nothing, and files
named in a way that defeats the behavior their names imply. Each is documented in
[`docs/gotchas.md`](../docs/gotchas.md). This plan turns those findings into an ordered,
low-risk cleanup that a developer can execute directly.

- **Task type:** chore / refactor
- **Complexity:** medium (touches templates, provisioning scripts, and the Makefile; some
  changes alter chezmoi behavior and must be smoke-tested)

## Objective

Remove or correct every verified wart so the repository's structure matches its behavior:
no orphaned modules, no inert prompts, no rendered-but-unsourced files, no ordering scripts
that don't order. When complete, `docs/gotchas.md` items 1–7 are resolved (or consciously
deferred), and `make test` + a `make smoke` lane still pass.

## Problem Statement

The repo currently ships several things that mislead a reader:

1. `home/shell/zsh_dot_d/{before,after}/` — 20 `.zsh` files that **nothing loads** (they
   don't match any sheldon glob and nothing sources the directory).
2. `~/.zshrc.local` is **rendered but never sourced** — Zsh doesn't auto-source it and no
   repo file does, so its darwin/arm64 config (history opts, `direnv hook`, `globalias`,
   completion styles) may be silently inert.
3. `pytest-rerunfailures` is pinned **twice** in `requirements-test.txt` (lines 26–27).
4. `run_onchange_before_99-macos-osx-settings.sh.tmpl` is a **comment-only stub** implying
   macOS defaults auto-apply; they do not (`~/.osx` is run by hand).
5. Four feature-flag prompts — `ruby`, `nodejs`, `k8s`, `fnm` — are **inert**: collected at
   init and stored in chezmoi data but read by **no template**, so toggling them does
   nothing.
6. Seven provisioning scripts use `run_before-00-…` / `run_after-00-…` (**hyphen**) instead
   of the `run_before_…` / `run_after_…` (**underscore**) chezmoi requires, so they run in
   the default "during" bucket, not strictly before/after file application.

## Solution Approach

Fix in ascending order of risk: pure deletions and de-duplication first (no behavior
change), then the flag removal (removes misleading prompts), then the script rename (the
only change that alters chezmoi ordering — validated with a dry-run + smoke test). Every
step is independently revertible. All chezmoi validation uses `--dry-run` / `chezmoi diff`
per this workstation's dry-run-only policy — **do not run a real `chezmoi apply`/`init --apply`**.

## Relevant Files

Use these files to complete the task:

- [`home/shell/zsh_dot_d/`](../home/shell/zsh_dot_d) — the entire orphaned tree (20 files under `before/` and `after/`) to delete (item 1).
- [`home/dot_zshrc.local.tmpl`](../home/dot_zshrc.local.tmpl) — rendered to `~/.zshrc.local`; decide source-or-remove (item 2).
- [`home/shell/config.zsh`](../home/shell/config.zsh) — deferred, loaded module; candidate place to `source ~/.zshrc.local` if keeping it (item 2).
- [`requirements-test.txt`](../requirements-test.txt) — remove the duplicate `pytest-rerunfailures` (line 27) (item 3).
- [`home/.chezmoiscripts/run_onchange_before_99-macos-osx-settings.sh.tmpl`](../home/.chezmoiscripts/run_onchange_before_99-macos-osx-settings.sh.tmpl) — stub; wire up `~/.osx --no-restart` or delete (item 4).
- [`home/executable_dot_osx`](../home/executable_dot_osx) — the real `~/.osx`; referenced if item 4 is wired.
- [`home/.chezmoi.yaml.tmpl`](../home/.chezmoi.yaml.tmpl) — remove the 4 inert prompt blocks and their `data:` emissions (item 5).
- [`Makefile`](../Makefile) — `CHEZMOI_GOOD_DEFAULTS` (lines 117–129) passes `--promptBool ruby/nodejs/fnm/k8s`; remove those lines if the prompts are removed (item 5).
- The 7 hyphenated scripts in [`home/.chezmoiscripts/`](../home/.chezmoiscripts) (item 6):
  `run_before-00-prereq-centos.sh.tmpl`, `run_before-00-prereq-centos-pyenv.sh.tmpl`,
  `run_before-00-prereq-ubuntu.sh.tmpl`, `run_before-00-prereq-ubuntu-pyenv.sh.tmpl`,
  `run_after-00-adhoc-centos.sh.tmpl`, `run_after-00-adhoc-macos.sh.tmpl`,
  `run_after-00-adhoc-ubuntu.sh.tmpl`.
- [`docs/gotchas.md`](../docs/gotchas.md) — update once each item is resolved.

## Implementation Phases

### Phase 1: Foundation (zero behavior change)
Delete the orphaned `zsh_dot_d/` tree, remove the duplicate test pin. These cannot affect a
running shell or provisioning because nothing references them.

### Phase 2: Core Implementation (config truth)
Resolve `~/.zshrc.local` (source it or remove it), resolve the inert flags (remove the
prompts + Makefile args, or wire them), and resolve the osx-settings stub.

### Phase 3: Integration & Polish (behavioral change + validation)
Rename the hyphenated `run_before-`/`run_after-` scripts to the underscore form, then
validate the whole set with a chezmoi dry-run, `make test`, and a `make smoke` lane before
updating `docs/gotchas.md`.

## Step by Step Tasks

IMPORTANT: Execute every step in order, top to bottom.

### 1. Delete the orphaned `zsh_dot_d/` tree
- Confirm nothing references it: `grep -rn "zsh_dot_d" home/` returns nothing.
- `git rm -r home/shell/zsh_dot_d`.
- If any snippet there is still wanted, first migrate it into the correct
  `home/shell/<tool>/{env,path,aliases}.zsh` (which the sheldon globs load) — see
  [`docs/shell-loading.md`](../docs/shell-loading.md).

### 2. Remove the duplicate test dependency
- In `requirements-test.txt`, delete line 27 (the second `pytest-rerunfailures`).

### 3. Resolve `~/.zshrc.local`
- Decide: **keep** or **remove**.
- If keeping: add `[ -f ~/.zshrc.local ] && source ~/.zshrc.local` to
  `home/shell/config.zsh` (deferred, already loaded) so the file actually runs. Add a
  marker `echo` temporarily and confirm it appears in a fresh shell.
- If removing: `git rm home/dot_zshrc.local.tmpl` and fold any still-wanted lines into
  `home/shell/config.zsh`.

### 4. Resolve the macOS osx-settings stub
- Decide: **wire** or **remove**.
- If wiring: in `run_onchange_before_99-macos-osx-settings.sh.tmpl`, invoke
  `~/.osx --no-restart` (accepting that system-defaults changes then run on every apply);
  add an onchange hash of `executable_dot_osx` so it re-runs when the defaults change.
- If removing: `git rm home/.chezmoiscripts/run_onchange_before_99-macos-osx-settings.sh.tmpl`
  and keep `~/.osx` as an explicit manual step (documented in
  [`docs/iterm2-and-macos.md`](../docs/iterm2-and-macos.md)).

### 5. Resolve the inert feature flags (`ruby`, `nodejs`, `k8s`, `fnm`)
- Confirm still inert: `for f in ruby nodejs k8s fnm; do grep -rl "\.$f\b" home/ --include='*.tmpl' | grep -v chezmoi.yaml.tmpl; done` returns nothing.
- **Recommended (remove the lie):** in `home/.chezmoi.yaml.tmpl`, delete the `$ruby`,
  `$nodejs`, `$k8s`, `$fnm` variable defaults, their `if $interactive` prompt blocks, and
  their `data:` emission lines. Then remove the matching `--promptBool ruby/nodejs/k8s/fnm`
  lines from `CHEZMOI_GOOD_DEFAULTS` in the `Makefile` (lines 123, 125, 126, 128).
- **Alternative (wire them up):** if these are meant to gate installs, add the conditionals
  where they belong (e.g. gate Ruby/Node in the `50-*-install-*` scripts on `.ruby`/`.nodejs`,
  gate a k8s toolchain install on `.k8s`, gate an fnm module on `.fnm`) and keep the prompts.
- Keep `pyenv`, `opencv`, `cuda` untouched — they are live.

### 6. Rename the hyphenated provisioning scripts
- Rename each `run_before-00-…` → `run_before_00-…` and `run_after-00-…` → `run_after_00-…`
  with `git mv` (preserves history), e.g.:
  - `git mv home/.chezmoiscripts/run_before-00-prereq-centos.sh.tmpl home/.chezmoiscripts/run_before_00-prereq-centos.sh.tmpl` (repeat for all 7).
- These are plain (not `once`/`onchange`) scripts, so they still run every apply — only the
  phase changes from "during" to true before/after.

### 7. Validate (dry-run only — no real apply)
- `chezmoi doctor` — environment sane.
- `chezmoi diff` and/or `chezmoi apply --dry-run -v` — preview; confirm no unexpected file
  churn and that the renamed scripts are now recognized as before/after.
- `make test` — pytest suite (incl. libtmux + script unit tests) passes.
- `make smoke` (asdf lane) and `make smoke-mise` — provisioning still succeeds end-to-end in
  Docker with the renamed scripts and removed flags.
- `make pre-commit` — all hooks pass.

### 8. Update documentation
- In `docs/gotchas.md`, mark items 1–7 resolved (or note any consciously deferred), and drop
  the corresponding rows from the "At a glance" table.
- If flags were removed, prune the inert-flag rows from
  [`docs/feature-flags.md`](../docs/feature-flags.md) and the note in `README.md`.

## Testing Strategy

- **No behavior regression (items 1–3):** deletions/de-dup are inert; `make test` is the
  guard.
- **Config-truth changes (items 3–5):** verify with `chezmoi diff` that only the intended
  files change; for a kept `~/.zshrc.local`, prove it sources via a marker in a fresh
  `zsh -i` shell.
- **Ordering change (item 6):** the real risk. Run **both** `make smoke` (asdf) and
  `make smoke-mise` — these reproduce a full `chezmoi init --apply` in Docker across both
  version-manager lanes, exercising the renamed before/after scripts in a throwaway
  environment (safe; not the host). Confirm prereq scripts still run before file
  application and adhoc scripts after.
- Edge case: the `*-pyenv` before-scripts are gated on `.pyenv`; run at least one smoke lane
  with `--promptBool pyenv=true` semantics (the smoke defaults) to exercise them.

## Acceptance Criteria

- `grep -rn "zsh_dot_d" home/` → no matches, and `home/shell/zsh_dot_d/` no longer exists.
- `grep -c "^pytest-rerunfailures$" requirements-test.txt` → `1`.
- `~/.zshrc.local` is either sourced by a loaded module (proven in a fresh shell) or removed.
- The osx-settings stub is either functional or removed.
- `for f in ruby nodejs k8s fnm; do grep -rn "\.$f\b" home/ --include='*.tmpl'; done` shows no
  reads **and** no prompts/data for those flags remain (if removal path chosen); `Makefile`
  no longer passes them.
- `ls home/.chezmoiscripts/ | grep -E 'run_(before|after)-00'` → no matches (all underscored).
- `make test`, `make smoke`, `make smoke-mise`, and `make pre-commit` all pass.
- `docs/gotchas.md` reflects the resolved state.

## Validation Commands

Execute these to validate the task is complete:

- `grep -rn "zsh_dot_d" home/ || echo OK-no-refs` — confirms the tree is gone/unreferenced.
- `grep -c "^pytest-rerunfailures$" requirements-test.txt` — expect `1`.
- `ls home/.chezmoiscripts/ | grep -E 'run_(before|after)-00' || echo OK-all-underscored` — expect the OK message.
- `for f in ruby nodejs k8s fnm; do echo "$f:"; grep -rl "\.$f\b" home/ --include='*.tmpl' | grep -v chezmoi.yaml.tmpl || echo "  inert/removed"; done`
- `chezmoi doctor` — environment check.
- `chezmoi apply --dry-run -v` — preview only (NO real apply on this workstation).
- `make test` — pytest suite.
- `make smoke && make smoke-mise` — full provisioning in Docker, both lanes.
- `make pre-commit` — lint/format/hooks.

## Notes

- **Workstation policy:** never run a real `chezmoi apply` or `chezmoi init --apply` here —
  use `--dry-run` / `chezmoi diff` for host validation and `make smoke*` (Docker) for the
  end-to-end path.
- Items 3, 4, and 5 each carry a **decision** (keep-vs-remove / remove-vs-wire). This plan
  recommends the lowest-risk, most-honest option (remove the thing that misleads) but
  documents the wiring alternative so the maintainer can choose.
- No new libraries are required.
- Source-of-truth for every finding: [`docs/gotchas.md`](../docs/gotchas.md).
