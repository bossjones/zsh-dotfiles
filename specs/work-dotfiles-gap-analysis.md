# Plan: Work Machine (`adobetop`) Dotfiles Gap Analysis

> **Machine:** `adobetop` (macOS, arm64, user `malcolm`)
> **Analysis date:** 2026-08-15
> **Baseline:** `origin/main` @ `41d8a98` (merge of PR #112)
> **Backup root:** `~/.backup/dotfiles/20260815-192156/`
> **Worktree:** `~/.local/share/chezmoi-gap-analysis` on `feat/work-dotfiles-gap-analysis`

---

## Task Description

It has been a long time since `chezmoi apply` was run on the work machine `adobetop`.
In the interim, three independent sources of drift accumulated:

1. **The chezmoi source repo drifted.** `~/.local/share/chezmoi` sat on a stale
   feature branch (`feature-adobetop`) that was **~30 commits behind `origin/main`**
   and carried **10 unmerged commits**.
2. **The live rendered dotfiles drifted.** Files such as `~/.gitconfig` and `~/.zshrc`
   were hand-edited, or appended to by third-party installers, *outside* chezmoi.
3. **`main` itself moved on substantially** — most significantly, it introduced a
   `version_manager` abstraction and migrated the recommended toolchain from
   **asdf** to **mise**.

Running `chezmoi apply` naively would have silently destroyed category 2.

This document is the **work-machine half** of a two-machine analysis. Its sibling,
`specs/personal-dotfiles-gap-analysis.md`, is produced on the personal machine using the
prompt in the PR description. Both then feed `specs/unified-dotfiles-gap-analysis.md`.

## Objective

Produce a complete, reversible inventory of everything that `chezmoi apply` would
**add, change, or destroy** on `adobetop` when moving from the stale local state to
`origin/main` with `version_manager=mise` — so the update can be performed with zero
unintentional loss, and so every deviation has a documented restore path.

---

## Problem Statement

`chezmoi apply` is a **destructive, one-way** operation with respect to local edits.
chezmoi's model is that the source repo is the single source of truth; any change made
directly to a target file (`~/.gitconfig`, `~/.zshrc`, …) is **overwritten without
prompting**.

Three classes of local state were at risk on this machine:

| Class | Example | Why it's fragile |
|---|---|---|
| Hand edits to managed files | `init.defaultBranch = main` in `~/.gitconfig` | Never round-tripped into the source repo |
| **Third-party installer injections** | `scout` completion + `awesome-cli` PATH blocks appended to `~/.zshrc` | Written by other tools; the user never "chose" them, so they are easy to forget |
| Unmanaged sibling files | `~/.gitconfig-adobe-corp` and friends | Referenced by managed files but not themselves managed — an orphaned reference is silent |

Compounding this, **chezmoi was completely non-functional** on this machine, so the
usual `chezmoi diff` safety check could not even be run (see Finding 1).

## Solution Approach

Measure the gap **against the correct baseline** and make every deviation reversible
before mutating anything:

1. **Back up first, measure second.** A full snapshot of every chezmoi-managed target
   is taken *before* any chezmoi subcommand runs — including read-only ones.
2. **Fix the tooling before trusting its output.** chezmoi `2.31.1` (Mar 2023) could not
   parse `main`'s templates; upgraded to `2.72.0`.
3. **Compare against `origin/main`, not the stale branch.** The initial drift reading was
   measured against `feature-adobetop` and was badly misleading (see Finding 6).
4. **Use a throwaway config** so measurement cannot mutate `~/.config/chezmoi/chezmoi.yaml`.
5. **Use git's own parser for semantic diffs.** For `~/.gitconfig`, a textual diff showed
   247 changed lines, almost all cosmetic. `git config --list` set-difference reduced this
   to **7 real losses and 10 real gains**.

---

## Relevant Files

### Analysis inputs (read)

- `home/.chezmoi.yaml.tmpl` — data schema; source of the `version_manager` / `fzf_tab`
  prompts and all pinned tool versions. The stale branch's copy is what broke chezmoi.
- `home/dot_zshrc.tmpl` — emits `ZSH_DOTFILES_VERSION_MANAGER`; the seam where asdf/mise is chosen.
- `home/dot_gitconfig` — target for the highest-risk loss (the `includeIf` blocks).
- `home/dot_gitignore_global` — one-line loss.
- `home/dot_sheldon/plugins.toml.tmpl` — conditionally emits the asdf plugin; also defines
  the glob-based module loader (`**/env.zsh` L37, `**/path.zsh` L41,
  `**/{keybinding,completion}.zsh` L57) that makes Task 6 zero-config.
- `home/shell/direnv/env.zsh`, `home/shell/krew/env.zsh`, `home/shell/mise/path.zsh` —
  reference implementations of the existence-gated module idiom reused in Task 6.
- `home/compat.sh.tmpl`, `home/compat.bash.tmpl` — non-zsh shells' version-manager shims.
- `home/.chezmoiscripts/run_onchange_after_50-mise-install-tools.sh.tmpl` — authoritative
  list of the 17 tools mise will install.
- `home/.chezmoiscripts/run_once_before_01-mise-backup-tool-versions.sh.tmpl` — the
  self-healing `~/.tool-versions` backup.
- `docs/version-managers.md`, `docs/tutorials/04-switch-version-manager.md` — the
  repo's own migration guidance; **followed rather than reinvented**.

### New Files

- `specs/work-dotfiles-gap-analysis.md` — this document.
- `home/shell/scout/completion.zsh` — **proposed**; existence-gated `scout` completion (Task 6).
- `home/shell/awesome-cli/path.zsh` — **proposed**; existence-gated `awesome-cli` PATH entry (Task 6).

### Backup artifacts (restore sources)

All under `~/.backup/dotfiles/20260815-192156/`:

| Artifact | Contents |
|---|---|
| `dotfiles-20260815-192156.tar.gz` | 367 files; sha256 in the `.sha256` sidecar |
| `files/` | Uncompressed per-file copies for direct `diff` |
| `chezmoi-2.31.1.bin` | The previous chezmoi binary |
| `chezmoi-status-vs-main-mise.txt` | 31-line status against the correct baseline |
| `chezmoi-diff-vs-main-mise.diff` | Full 5158-line diff |
| `gitconfig-LOST.txt` / `gitconfig-GAINED.txt` | Semantic set-difference |
| `feature-adobetop-superseded/` | 45 files from the stale branch, incl. `hack-doctor-divergence.diff` |
| `managed-paths.txt`, `backed-up.txt` | Manifests |

---

## Findings

### Finding 1 — chezmoi was completely broken (RESOLVED)

Every chezmoi subcommand failed:

```
chezmoi: warning: config file template has changed, run chezmoi init to regenerate config file
chezmoi: template: .chezmoiscripts/run_onchange_after_50-macos-install-asdf-plugins.sh.tmpl:62:9:
  executing ... at <.myAsdfRyeVersion>: map has no entry for key "myAsdfRyeVersion"
```

**Root cause:** the generated `~/.config/chezmoi/chezmoi.yaml` predated a source-template
change, so a key the templates required was absent. **rye was removed on `main`**, so this
specific key is now moot — but the *class* of failure recurs for `version_manager` and
`fzf_tab`, which `main` added and the stale config also lacks:

```
chezmoi: template: .chezmoiignore.tmpl:5:9: executing ... at <.version_manager>:
  map has no entry for key "version_manager"
```

> **This is why `chezmoi init` (not just `apply`) is mandatory** — see Task 5.

### Finding 2 — chezmoi binary was 3+ years stale (RESOLVED)

`~/.bin/chezmoi` was `v2.31.1` (2023-03-02). Upgraded to `v2.72.0` (2026-08-02).
`~/.bin/chezmoi` is **not** itself chezmoi-managed, so replacing it is safe.
Old binary preserved at `~/.backup/dotfiles/20260815-192156/chezmoi-2.31.1.bin`.

### Finding 3 — 🔴 `~/.gitconfig` would lose 7 settings

Computed with `git config --file … --list` on both live and rendered-target:

```
core.editor=nano                                                        # -> becomes vim
includeif.gitdir:~/dev/malcolm/.path=~/.gitconfig-adobe-corp            # WORK IDENTITY
includeif.gitdir:~/dev/adobe-platform/.path=~/.gitconfig-adobe-corp     # WORK IDENTITY
includeif.gitdir:~/dev/adobe-aifoundations/.path=~/.gitconfig-adobe-ghec# WORK IDENTITY
includeif.gitdir:~/dev/malcolm_adobe/.path=~/.gitconfig-adobe-ghec      # WORK IDENTITY
includeif.gitdir:~/dev/bossjones.path=~/.gitconfig-personal             # PERSONAL IDENTITY
init.defaultbranch=main
```

**Impact if lost:** commits in `~/dev/malcolm/`, `~/dev/adobe-platform/`,
`~/dev/adobe-aifoundations/` and `~/dev/malcolm_adobe/` would silently fall back to the
personal identity `bossjones@theblacktonystark.com` — **the wrong author on work commits**.
This is the single highest-consequence item in this analysis.

The 3 referenced files are **unmanaged** and exist only on this machine:

```
-rw-r--r--  139  /Users/malcolm/.gitconfig-adobe-corp
-rw-r--r--  135  /Users/malcolm/.gitconfig-adobe-ghec
-rw-r--r--  139  /Users/malcolm/.gitconfig-personal
```

Conversely `main` **gains** 10 genuinely good settings, which is a strong argument for
adopting `main`'s file and re-adding the includes on top:

```
branch.sort=-committerdate   column.ui=auto        core.editor=vim
fetch.prunetags=true         ghq.root=~/code       push.followtags=true
rebase.autosquash=true       rebase.autostash=true rebase.updaterefs=true
tag.sort=version:refname
```

### Finding 4 — 🔴 `~/.zshrc` would lose two third-party installer blocks

These were appended by other tools' installers and exist **nowhere** in the chezmoi source:

```zsh
# >>> scout completion >>>
command -v scout >/dev/null 2>&1 && eval "$(scout generate-shell-completion zsh)"
# <<< scout completion <<<

# >>> awesome-cli >>>
case ":$PATH:" in
  *":/Users/malcolm/.awesome/bin:"*) ;;
  *) export PATH="/Users/malcolm/.awesome/bin:$PATH" ;;
esac
# <<< awesome-cli <<<
```

`~/.zshrc` **gains** the version-manager seam, which is expected and desired:

```zsh
+export ZSH_DOTFILES_VERSION_MANAGER="mise"
+export ZSH_DOTFILES_FZF_TAB=false
```

### Finding 5 — 🟡 `~/.gitignore_global` would lose one line

```
-**/.claude/settings.local.json
```

Low impact but easy to preserve; `.claude/settings.local.json` is per-machine and
should not be committed. Note `main`'s **repo-level** `.gitignore` already covers
`.claude/settings.local.json`, so this only matters for *other* repos.

### Finding 6 — ⚠️ The first drift reading was measured against the wrong baseline

Measured against the stale `feature-adobetop`, drift appeared to be **23 files**, including
alarming-looking reversions of `~/.zshrc` from a dynamic `eval "$(sheldon source)"` back to a
statically baked plugin list pinning `/opt/homebrew/opt/asdf@0.11.2`.

**That was an artifact of the stale branch.** `origin/main` already emits the dynamic form.
Re-measured against `origin/main`, real drift is **10 modified + 3 added files**.

> **Methodology note for the personal machine and the unified plan:** always
> `git fetch` and measure against `origin/main`, never against whatever branch happens
> to be checked out.

### Finding 7 — 🟡 The GitHub Copilot CLI error is fixed by `main`

Reported error:

```
Repository settings file '/Users/malcolm/.local/share/chezmoi/.claude/settings.json'
could not be loaded: Settings config error: hooks.preToolUse[0].matcher: matcher cannot be empty
hooks.postToolUse[0].matcher: matcher cannot be empty
hooks.preCompact[0].matcher: matcher cannot be empty
```

**Root cause:** the stale branch's `.claude/settings.json` declared hooks with
`"matcher": ""`. Claude Code tolerates empty matchers; **Copilot CLI rejects them**, so the
*entire* settings file was discarded — silently dropping `permissions` and `enabledPlugins` too.

**`main` already removed that hooks block** in `358f0b1` *"chore: remove legacy Claude Code
configuration files and hooks"*, replacing the vendored tooling with marketplace plugins:

```json
"enabledPlugins": {
  "agent-harness@boss-skills": true,
  "superpowers@claude-plugins-official": true,
  ...
}
```

No new fix is required — but see Task 3, because a naive merge **resurrects** the problem.

### Finding 8 — ⚠️ Merging `main` silently resurrected 34 deleted files

`feature-adobetop` added the legacy `.claude/` tooling; `main` later deleted it. Because the
**merge base predates both**, git classified those paths as *"added by us"* and **kept them**,
undoing `main`'s intentional cleanup — and reinstating the Copilot-breaking hooks.

> **Generalised lesson for the unified plan:** after merging `main` into any long-lived
> branch, always run
> `git diff --diff-filter=A --name-only origin/main HEAD`
> to list files your branch reintroduces that `main` deliberately removed.

Resolved in commit `bf252b7`; `.claude/` is now byte-identical to `main`.
`status_line_v10.py` was **retained** because `settings.json` still references it.

### Finding 9 — 🔴 asdf → mise is the largest behavioural change

Current state on `adobetop`: **asdf `v0.11.2`**, 25 tools pinned in `~/.tool-versions`.
**mise is not installed.**

`main`'s mise lane installs **17** tools. Version deltas:

| Tool | Now (asdf) | After (mise) |
|---|---|---|
| ruby | 3.2.1 | **4.0.1** |
| golang | 1.23.9 | 1.25.1 |
| shellcheck | 0.10.0 | 0.11.0 |
| shfmt | 3.7.0 | 3.13.1 |
| yq | 4.34.1 | 4.53.2 |
| github-cli | `system` | 2.93.0 |
| neovim | 0.11.6 | `latest` |

**11 tools are intentionally dropped** (decision recorded 2026-08-15 — all are years stale):

```
fd 8.2.1        jsonnet 0.17.0   packer 1.7.4     terraform 1.0.6
vault 1.11.3+ent poetry 1.1.8    ag 2.2.0         dive 0.10.0
kompose 1.24.0  velero v1.10.2   argocd 2.3.16
```

Mitigations already in `main`:
- `run_once_before_01-mise-backup-tool-versions.sh.tmpl` renames `~/.tool-versions` →
  `~/.tool-versions.asdf.bak` (never deletes, never clobbers an existing `.bak`).
- `mise settings set ruby.compile false` uses precompiled Ruby binaries — important,
  because compiling Ruby 4.0.1 from source on arm64 macOS is slow and failure-prone.
- `~/.asdf` is **left in place**; the switch is reversible by flipping the flag back.

Also removed by the switch (both expected):

```toml
# ~/.config/sheldon/plugins.toml
-[plugins.asdf]
-local = "/opt/homebrew/opt/asdf@0.11.2/libexec"
```

```sh
# ~/compat.sh — asdf block replaced by
+command -v mise >/dev/null 2>&1 && eval "$(mise activate sh)"
```

### Finding 10 — 🟡 `git remote` used HTTPS and could not authenticate

`origin` was `https://github.com/bossjones/zsh-dotfiles.git`; pushes failed with
*"Password authentication is not supported"*. `gh` is configured for **ssh**, and the
active account is `malcolm_adobe` while the repo belongs to `bossjones`.

Changed to `git@github.com:bossjones/zsh-dotfiles.git`, which authenticates as `bossjones`.
**Verify this on the personal machine too.**

### Finding 11 — 🟡 `dot_zshrc.local.tmpl` is managed but never sourced

`home/dot_zshrc.local.tmpl` renders `~/.zshrc.local` (3398 bytes on this machine, containing
real history/`setopt` configuration), but **no source directive references it** anywhere in
`home/`. It is effectively dead configuration.

Do **not** use `~/.zshrc.local` as the remediation target for Finding 4. Use per-tool
modules under `home/shell/<tool>/`, which sheldon globs in explicitly
(`home/dot_sheldon/plugins.toml.tmpl` L36–L57).

### Finding 12 — 🟡 `hack/doctor/` diverged; the stale branch's version is larger

| File | `feature-adobetop` | `origin/main` |
|---|---|---|
| `check_dev_environment.py` | 796 lines | 698 lines |
| `install_missing.sh` | 202 lines | 246 lines |
| extra files | `check_dev_environment2.py`, `example_env_check_output.txt` | — |

Resolved **in favour of `main`** (CI-verified). The superseded versions and a 1748-line
divergence diff are preserved in
`~/.backup/dotfiles/20260815-192156/feature-adobetop-superseded/`.
Deciding whether the extra env-checking work should be ported forward is deferred to the
unified plan.

### Finding 13 — 🟡 Flags worth revisiting

`cuda: true` on an **arm64 Mac** is meaningless; `docs/feature-flags.md` describes the flag as
inert. `opencv: true` pulls heavy dependencies. Both are preserved as-is here to keep this
change set focused; revisit in the unified plan.

---

## Work Already Completed

| Commit | Description |
|---|---|
| `f5255c0` | `fix(shell): source cargo env on all platforms when present` |
| `e6678ee` | `Merge remote-tracking branch 'origin/main' into feature-adobetop` (23 conflicts) |
| `bf252b7` | `chore(claude): drop vendored agents, commands, hooks and stale status lines` |

Note `f5255c0` turned out to be **byte-identical to `main`'s** version of
`home/shell/rust/path.zsh` — independent convergence on the same fix, which is good
corroboration that the change was correct.

Conflict resolution policy: **take `origin/main`** for all 23 conflicts (it is CI-verified
and validated on the `dotfiles-utm` test VM), preserving superseded content to the backup
rather than discarding it.

---

## Step by Step Tasks

IMPORTANT: Execute every step in order, top to bottom.

### 1. Verify the backup before touching anything

```sh
BK=~/.backup/dotfiles/20260815-192156
cd "$BK" && shasum -a 256 -c dotfiles-20260815-192156.tar.gz.sha256
tar -tzf "$BK"/dotfiles-*.tar.gz | wc -l          # expect 385
test -f "$BK/files/.gitconfig" && echo "gitconfig backed up"
```

- **Do not proceed if the checksum fails.** Re-run the backup instead.

### 2. Capture the current identity behaviour as a regression baseline (TDD)

Record the *behaviour* to preserve, not just the file bytes — this is the test that Task 7
must make pass again:

```sh
BK=~/.backup/dotfiles/20260815-192156
for d in ~/dev/malcolm ~/dev/adobe-platform ~/dev/adobe-aifoundations ~/dev/malcolm_adobe ~/dev/bossjones; do
  [ -d "$d" ] && printf '%s\t%s\n' "$d" "$(git -C "$d" config user.email 2>/dev/null || echo NONE)"
done | tee "$BK/identity-baseline.txt"
```

- This file is the **expected output** for the Task 7 verification.

### 3. Confirm the resurrected-files guard is clean

```sh
cd ~/.local/share/chezmoi
git diff --diff-filter=A --name-only origin/main HEAD
```

- Expect only `.mcp.sample.json`, `hack/doctor/check_dev_environment2.py`,
  `hack/doctor/example_env_check_output.txt`.
- **Any `.claude/hooks/*` here means Finding 8 has regressed** — re-remove before continuing.

### 4. Preview the apply (read-only, no mutation)

```sh
cd ~/.local/share/chezmoi
chezmoi diff  --source=./home | tee /tmp/preapply.diff
chezmoi status --source=./home
```

- If this still errors with `map has no entry for key "version_manager"`, that is expected
  **until** Task 5 regenerates the config.

### 5. Regenerate the chezmoi config and apply

This is the command to run. It uses `--source=.` against the **existing working tree** —
it does **not** re-clone, so local commits are preserved:

```sh
cd ~/.local/share/chezmoi
chezmoi init --source=. --debug -v \
  --promptString "Name=Malcolm Jones" \
  --promptString "Email=bossjones@theblacktonystark.com" \
  --promptString "Computer name=adobetop" \
  --promptString "Host name=adobetop" \
  --promptString "version_manager=mise" \
  --promptBool   "ruby=true" \
  --promptBool   "pyenv=true" \
  --promptBool   "nodejs=true" \
  --promptBool   "k8s=true" \
  --promptBool   "cuda=true" \
  --promptBool   "fnm=true" \
  --promptBool   "opencv=true" \
  --promptBool   "fzf_tab=false"

chezmoi diff --source=.        # review — nothing has been written yet
chezmoi apply -v --source=.    # only after the diff looks right
```

- **Do not add `--apply` to the `init` line.** Keeping `init` and `apply` separate preserves
  the review gate; the repo's own Tutorial 04 recommends this ordering.
- Non-interactive runs ignore the `if $interactive` prompts, so **run this in a real TTY**
  or the boolean flags silently fall back to `false` (verified during analysis).
- `--debug -v` is retained from the reference command for a full activity log.

### 6. Re-home the third-party `~/.zshrc` blocks (fixes Finding 4)

`scout` and `awesome-cli` are **Adobe tools installed outside this repo**, so the modules
must be inert on machines where they are absent — the personal machine included. Follow the
existing per-tool module convention in `home/shell/<tool>/` rather than inventing a new file.

`home/dot_sheldon/plugins.toml.tmpl` already globs these in, so **no `plugins.toml` change
is needed**:

```toml
local = "~/.local/share/chezmoi/home/shell"   # L36
use = ["**/env.zsh"]                          # L37
...
use = ["**/path.zsh"]                         # L41
...
use = ["**/{keybinding,completion}.zsh"]      # L57  (deferred)
```

Create `home/shell/awesome-cli/path.zsh` — PATH work belongs in `path.zsh`, matching
`home/shell/krew/env.zsh`'s `test -d` idiom:

```zsh
# awesome-cli (Adobe) — installed outside this repo; no-op when absent.
test -d "${HOME}/.awesome/bin" && {
    case ":$PATH:" in
        *":${HOME}/.awesome/bin:"*) ;;
        *) export PATH="${HOME}/.awesome/bin:$PATH" ;;
    esac
}
```

Create `home/shell/scout/completion.zsh`. **Do not `eval` the completion**:
`scout generate-shell-completion zsh` emits a `#compdef scout` *autoload function file*,
and `[plugins.local]` (L56) is deferred **before** `[plugins.compinit]` (L193), so `compdef`
does not exist yet at that point. Eval'ing it raises
`(eval):…: command not found: compdef` on every shell start — verified during analysis.

Every existing `completion.zsh` in this repo only manipulates `fpath` for exactly this
reason (`home/shell/chezmoi/completion.zsh`, `home/shell/brew/completion.zsh`). Follow suit
by caching the generated file into `~/.zsh/completions`, which is **already on `fpath`**:

```zsh
#!/usr/bin/env zsh
# scout (Adobe) — installed outside this repo; no-op when absent.
# `scout generate-shell-completion zsh` emits a `#compdef` autoload file, so cache it
# into fpath rather than eval'ing it: completion.zsh is sourced before compinit runs,
# so `compdef` does not exist yet at this point.
if (( ${+commands[scout]} )); then
    _scout_comp="${HOME}/.zsh/completions/_scout"
    if [[ ! -f "$_scout_comp" ]] || [[ "${commands[scout]}" -nt "$_scout_comp" ]]; then
        mkdir -p "${_scout_comp:h}"
        scout generate-shell-completion zsh > "$_scout_comp" 2>/dev/null
    fi
    fpath+="${HOME}/.zsh/completions"
    unset _scout_comp
fi
```

- Regenerates only when the `scout` binary is newer than the cache, so shell startup cost is
  a single `stat` in the common case.
- `.zshrc` sets `typeset -U fpath`, so the `fpath+=` is safely de-duplicated.
- Use `${HOME}` rather than the hardcoded `/Users/malcolm` from the original block, so the
  files are portable.
- The `case` guard keeps the `awesome-cli` PATH entry idempotent across re-sourced shells.

**Verification (all six passed during analysis):**

```sh
zsh -n home/shell/awesome-cli/path.zsh home/shell/scout/completion.zsh   # syntax
# awesome-cli: sourced twice -> exactly 1 PATH entry            (idempotent)
# awesome-cli: ~/.awesome/bin absent -> $PATH unchanged         (no-op)
# scout: absent -> nothing created, exit 0                      (no-op)
# scout: present -> ~/.zsh/completions/_scout written, fpath updated, no compdef error
# scout: second source -> mtime unchanged                       (cache reused)
```

### 7. Restore the git identity routing (fixes Finding 3)

`main`'s `home/dot_gitconfig` is a plain file, not a template, and the `includeIf` paths are
**work-machine-specific** — so appending them to the shared file would wrongly apply them on
the personal machine. Two options; decide in the unified plan:

- **Option A (recommended, portable):** convert `home/dot_gitconfig` → `home/dot_gitconfig.tmpl`
  and guard the work block on hostname:

  ```gotemplate
  [init]
      defaultBranch = main

  {{- if eq .chezmoi.hostname "adobetop" }}

  # Adobe on-premise repos
  [includeIf "gitdir:~/dev/malcolm/"]
      path = ~/.gitconfig-adobe-corp
  [includeIf "gitdir:~/dev/adobe-platform/"]
      path = ~/.gitconfig-adobe-corp

  # Adobe GHEC repos
  [includeIf "gitdir:~/dev/adobe-aifoundations/"]
      path = ~/.gitconfig-adobe-ghec
  [includeIf "gitdir:~/dev/malcolm_adobe/"]
      path = ~/.gitconfig-adobe-ghec

  # Personal repos
  [includeIf "gitdir:~/dev/bossjones"]
      path = ~/.gitconfig-personal
  {{- end }}
  ```

- **Option B (simplest):** leave `dot_gitconfig` alone and add a machine-local
  `[include] path = ~/.gitconfig-local` that chezmoi never manages.

- Either way, bring the 3 referenced files under management (they contain no secrets —
  name/email only, 135–139 bytes each), or document that they must be recreated by hand.
- Restore `init.defaultBranch = main`.
- Decide explicitly on `core.editor`: `main` sets `vim`, this machine had `nano`.

### 8. Restore the `~/.gitignore_global` line (fixes Finding 5)

- Append `**/.claude/settings.local.json` to `home/dot_gitignore_global`.
- This belongs on **both** machines, so it is an unconditional edit.

### 9. Verify the migration

Run every command in **Validation Commands** below.

### 10. Record deviations for the unified plan

- Note anything that differed from this document's predictions.
- Confirm the same analysis has been produced for the personal machine before writing
  `specs/unified-dotfiles-gap-analysis.md`.

---

## Testing Strategy

This is a configuration change, so "tests" are **behavioural assertions** run before and
after, comparing against artifacts captured in Task 2.

**Pre-flight (before apply):**
- Backup checksum verifies (Task 1).
- Git identity baseline captured (Task 2).
- `git diff --diff-filter=A` guard is clean (Task 3).

**Post-apply assertions:**
1. **Git identity routing** — the highest-consequence item. `git -C ~/dev/malcolm config
   user.email` must match `identity-baseline.txt`.
2. **Shell starts cleanly** — `zsh -i -c exit` exits 0 with no errors.
3. **Third-party integrations survive** — `scout` completion and the `awesome-cli` PATH entry
   are still present in a fresh interactive shell.
4. **Version manager switched** — `mise --version` works and
   `ZSH_DOTFILES_VERSION_MANAGER` is `mise`.
5. **No unintended deletions** — diff the post-apply tree against the backup and confirm
   every difference is expected.

**Edge cases to watch:**
- Ruby 4.0.1 install is the most likely failure. If `mise install ruby` fails, confirm
  `mise settings get ruby.compile` is `false`.
- `~/.tool-versions.asdf.bak` must exist afterwards; if `~/.tool-versions` is *gone* with no
  `.bak`, restore it from the backup.
- A **non-TTY** run of Task 5 silently produces all-`false` booleans — verify
  `chezmoi data` afterwards rather than trusting the exit code.

---

## Acceptance Criteria

- [ ] Backup verified by checksum and restorable.
- [ ] `chezmoi status` and `chezmoi diff` run without template errors.
- [ ] `chezmoi data` reports `version_manager: mise`, `fzf_tab: false`, and
      `ruby/pyenv/nodejs/k8s/cuda/opencv/fnm` all `true`.
- [ ] All 5 `includeIf` blocks present in `~/.gitconfig`; work repos still resolve to the
      work identity (matches `identity-baseline.txt`).
- [ ] `init.defaultBranch = main` present.
- [ ] `**/.claude/settings.local.json` present in `~/.gitignore_global`.
- [ ] `scout` completion and `awesome-cli` PATH survive a fresh shell.
- [ ] `mise` installed; `~/.tool-versions.asdf.bak` created; `~/.asdf` untouched.
- [ ] A new `zsh -i` session starts with no errors.
- [ ] `copilot` loads repository settings with no `matcher cannot be empty` error.
- [ ] Every deviation has a documented restore path in this file.

---

## Validation Commands

```sh
# --- 0. Backup integrity -----------------------------------------------------
BK=~/.backup/dotfiles/20260815-192156
( cd "$BK" && shasum -a 256 -c dotfiles-20260815-192156.tar.gz.sha256 )

# --- 1. chezmoi is healthy ---------------------------------------------------
chezmoi --version
chezmoi doctor
cd ~/.local/share/chezmoi && chezmoi status --source=. && chezmoi diff --source=.

# --- 2. Config data is correct (catches the non-TTY all-false trap) ----------
chezmoi data | grep -E '"(version_manager|fzf_tab|ruby|pyenv|nodejs|k8s|cuda|opencv|fnm)"'

# --- 3. Git identity routing — THE critical assertion ------------------------
for d in ~/dev/malcolm ~/dev/adobe-platform ~/dev/adobe-aifoundations ~/dev/malcolm_adobe ~/dev/bossjones; do
  [ -d "$d" ] && printf '%s\t%s\n' "$d" "$(git -C "$d" config user.email)"
done > /tmp/identity-after.txt
diff "$BK/identity-baseline.txt" /tmp/identity-after.txt && echo "PASS: identity routing preserved"

git config --file ~/.gitconfig --list | grep -c includeif   # expect 5
git config --file ~/.gitconfig --get init.defaultbranch      # expect: main

# --- 4. gitignore_global -----------------------------------------------------
grep -q '\*\*/.claude/settings.local.json' ~/.gitignore_global && echo "PASS: gitignore line"

# --- 5. Shell health and third-party integrations ---------------------------
zsh -n ~/.zshrc && echo "PASS: zshrc syntax"
zsh -i -c 'exit' && echo "PASS: interactive shell starts clean"
zsh -i -c 'echo $ZSH_DOTFILES_VERSION_MANAGER'          # expect: mise
zsh -i -c 'case ":$PATH:" in *".awesome/bin"*) echo "PASS: awesome-cli PATH";; *) echo "FAIL";; esac'

# scout completion is cached into fpath, never eval'd (see Task 6)
test -f ~/.zsh/completions/_scout && head -1 ~/.zsh/completions/_scout   # expect: #compdef scout
zsh -i -c 'exit' 2>&1 | grep -q "compdef" && echo "FAIL: compdef error" || echo "PASS: no compdef error"

# --- 6. Version manager migration -------------------------------------------
mise --version
mise ls --current
test -f ~/.tool-versions.asdf.bak && echo "PASS: asdf tool-versions backed up"
test -d ~/.asdf && echo "PASS: ~/.asdf left intact (rollback still possible)"

# --- 7. Copilot CLI settings load -------------------------------------------
python3 -c "import json;d=json.load(open('$HOME/.local/share/chezmoi/.claude/settings.json'));\
print('hooks present:', 'hooks' in d)"    # expect: False
cd ~/.local/share/chezmoi && copilot --help >/dev/null 2>&1 && echo "PASS: copilot loads settings"

# --- 8. No unintended deletions ---------------------------------------------
diff -rq "$BK/files" ~ 2>/dev/null | grep -v "^Only in" | head -40
```

### Rollback

```sh
BK=~/.backup/dotfiles/20260815-192156

# Restore a single file
cp "$BK/files/.gitconfig" ~/.gitconfig

# Restore everything
tar -xzf "$BK"/dotfiles-*.tar.gz -C /tmp/restore && cp -a /tmp/restore/files/. ~/

# Roll back the version manager (asdf data was never deleted)
cd ~/.local/share/chezmoi && chezmoi init --source=. --promptString "version_manager=asdf"
mv ~/.tool-versions.asdf.bak ~/.tool-versions

# Roll back the chezmoi binary
cp "$BK/chezmoi-2.31.1.bin" ~/.bin/chezmoi
```

---

## Notes

- **Two-machine workflow.** This is the work-machine analysis. The personal machine
  produces `specs/personal-dotfiles-gap-analysis.md` via the prompt in the PR description;
  both then merge into `specs/unified-dotfiles-gap-analysis.md`.
- **Worktree hygiene.** Analysis ran in `~/.local/share/chezmoi-gap-analysis`
  (branch `feat/work-dotfiles-gap-analysis`, off `origin/main`). All chezmoi commands used
  `--source`/`--config` overrides so the real config was never mutated. Remove with
  `git worktree remove ~/.local/share/chezmoi-gap-analysis` when done.
- **The sheldon module loader hardcodes `~/.local/share/chezmoi`**
  (`plugins.toml.tmpl` L36–L57, L225), so the *live shell* always sources from the main
  checkout, never from a worktree. Worth parameterising — a candidate for the unified plan.
- **No new libraries required.** Only `chezmoi`, `git`, `gh` and `mise` (installed by the
  chezmoi scripts themselves).
- **Open questions deferred to the unified plan:** `cuda`/`opencv` flags on macOS
  (Finding 13); porting the `hack/doctor` divergence (Finding 12); whether
  `dot_zshrc.local.tmpl` should be sourced or deleted (Finding 11).
