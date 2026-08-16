# Plan: Unified Two-Machine Dotfiles Reconciliation

> **Machines:** `adobetop` (work — macOS, arm64, user `malcolm`) and
> `Mac.scarlettlab.home` (personal — macOS 26.5.2, arm64, user `bossjones`)
> **Analysis date:** 2026-08-15
> **Baseline:** `origin/main` @ `41d8a98`
> **Inputs:** `specs/work-dotfiles-gap-analysis.md` (PR #114),
> `specs/personal-dotfiles-gap-analysis.md` (PR #115)
> **Tracking:** epic #116 (sub-issues #117–#129)

---

## Task Description

The work and personal analyses are complete and they **disagree in important ways**. This
document reconciles them into one plan: what is shared, what is machine-specific, and — where
the two machines conflict — which way to go and why.

This is the **decision gate** for epic #116. Nothing in Phases 1–5 of that epic starts until
this document is agreed. `/agent-harness:build` runs against *this* spec, not the two inputs.

**Scope:** planning only. No `chezmoi apply` has been run on either machine.

## Objective

Produce a single ordered plan that both machines can execute, in which:

1. Every change is classified **shared**, **machine-specific**, or **conflict + resolution**.
2. Every machine-specific change has a mechanism that is *reproducible* — not a hand edit.
3. Every claim is traceable to verified evidence, not to one machine's assumption.

---

## Method

The two input specs were not merely merged. Every cross-machine claim was **re-verified
against `origin/main` and against this machine** before being carried forward, because the
inputs were written independently and one of them was wrong in places (see
[Corrections](#corrections-to-the-input-specs)).

Where a finding appears in only one spec, this document states explicitly whether it
generalises. Where the two specs disagree, the disagreement is named rather than smoothed over.

---

## Part 1 — SHARED changes (unconditional, in `home/`)

These belong to every machine. No gating, no templating.

| # | Change | Evidence | Epic issue |
|---|---|---|---|
| S1 | Append `**/.claude/settings.local.json` to `home/dot_gitignore_global` | Lost on **both** machines, discovered independently | #121 |
| S2 | Restore `init.defaultBranch = main` in the git config | Lost on **both** machines | #119 |
| S3 | Introduce the `profile` data key (`"personal"` \| `"work"`, default `personal`) | Shared infrastructure both machines receive | #118 |
| S4 | Convert `home/dot_gitconfig` → `home/dot_gitconfig.tmpl` (via `git mv`) | Prerequisite for S3's gating | #119 |
| S5 | Settle `core.editor` | `main` says `vim`; **both** machines currently run `nano` | #119 |
| S6 | `version_manager = mise` | Both specs chose mise independently | #126–#128 |
| S7 | Delete `home/dot_zshrc.local.tmpl` | Dead config on **both** machines | #129 |

### S3 is the load-bearing one

`profile` is **shared infrastructure, not a work-machine patch.** Both machines receive the
identical template changes; the personal machine simply resolves to `"personal"` and renders
the work-only blocks away.

Confirmed against both inputs: the work spec (Task 7) designs it, and the personal spec
(Finding 13) independently concludes the personal machine *needs the same template changes,
not none of them*. **The two specs agree.** Carried forward as decided, with the work spec's
tested snippets.

Three files change:

- `home/.chezmoi.yaml.tmpl` — declare the default, prompt **outside** `if $interactive`
  (same reason `version_manager` is, L104), emit into `data:`
- `home/dot_gitconfig.tmpl` — gate the work-only blocks
- `home/.chezmoiignore.tmpl` — gate the identity files

Plus documentation: `docs/feature-flags.md` (string flag, so it belongs in the
*Version Manager Selection*-style table), `docs/architecture.md`, and `Makefile`'s
`CHEZMOI_GOOD_DEFAULTS` (pass `--promptString "profile=personal"` so smoke tests never render
the work block).

> ⚠️ **`profile` is sticky.** Once written to `~/.config/chezmoi/chezmoi.yaml`, `hasKey`
> short-circuits the prompt and re-passing `--promptString profile=…` is a **no-op**. It must
> be correct on the **first** `init` on each machine.

### S5 — `core.editor`

Not a profile split; a single preference. **Both** machines currently have `nano` and `main`
says `vim`. Recommendation: **adopt `vim`** (match `main`, one less deviation to carry). If
`nano` is genuinely preferred, change it in `home/dot_gitconfig.tmpl` **once, unconditionally**
— do not gate it on `profile`.

### S7 — delete `dot_zshrc.local.tmpl` (decided)

`home/dot_zshrc.local.tmpl` renders `~/.zshrc.local` on both machines (3398 B work, 3.3 K
personal) and **no source directive references it anywhere in `home/`** — verified fresh on
`origin/main`.

> ⚠️ **Sourcing it would not be a safe no-op.** The rendered file sets real values that have
> been inert for years, including `RBENV_VERSION=2.7.2` and `export SHELL=/opt/homebrew/bin/zsh`.
> "Just source it" would silently *activate* stale configuration.

**Decision (2026-08-15): delete the template.** The content has been inert without ill effect,
and both machines' live copies are captured in their backups if anything is worth reviving.
Overlaps #101, which already lists this as dead config — coordinate there.

---

## Part 2 — MACHINE-SPECIFIC changes

### The mechanism: `profile`, not `.chezmoi.hostname`

The brief asked whether machine-specific changes should template on `.chezmoi.hostname` or use
a machine-local include chezmoi never manages. **Recommendation: neither as the primary
mechanism — use `profile`.** Hostname gating was verified unsuitable:

- `.chezmoi.hostname` resolves to **`"Mac"`** on the personal machine — the short name, not
  `Mac.scarlettlab.home` (that is `.chezmoi.fqdnHostname`). `"Mac"` is generic enough to
  collide and silently mis-gate.
- The `.hostname` **data key** is a *different thing* — a user-entered value, currently the
  stale `"bossworkstation"` on the personal machine, which matches no real hostname.
- A hostname gate breaks on machine rename; `profile` states *why* a block exists and survives
  renames.
- `.chezmoi.hostname` is used for gating **nowhere** in `home/` today, so nothing would be
  following an existing pattern.

Machine-local *unmanaged* includes remain the right tool for **secrets and per-machine
one-offs** (the existing `[include] path = .gitconfig.token` / `.gitconfig.hub` idiom), but not
for structural work-vs-personal divergence.

### M1 — Git identity routing (work only) — #119, #120

Five `includeIf` blocks and three identity files, gated on `profile=work`:

```gotemplate
{{ if eq .profile "work" }}
[includeIf "gitdir:~/dev/malcolm/"]
  path = ~/.gitconfig-adobe-corp
[includeIf "gitdir:~/dev/adobe-platform/"]
  path = ~/.gitconfig-adobe-corp
[includeIf "gitdir:~/dev/adobe-aifoundations/"]
  path = ~/.gitconfig-adobe-ghec
[includeIf "gitdir:~/dev/malcolm_adobe/"]
  path = ~/.gitconfig-adobe-ghec
[includeIf "gitdir:~/dev/bossjones/"]
  path = ~/.gitconfig-personal
{{ end -}}
```

- **Personal machine confirms it needs none of this:** zero `includeIf` entries and no
  `~/.gitconfig-*` files exist there. The work spec explicitly deferred that question to the
  personal analysis; it is now answered.
- `home/dot_gitconfig-{adobe-corp,adobe-ghec,personal}` become managed but are
  `.chezmoiignore`d unless `profile=work`.

> ⚠️ **Placement is load-bearing.** `includeIf` applies in file order, last-wins. The block
> must stay **last** in the file, and tests must assert **resolved identity**, not file contents.

> ⚠️ **Never make the identity files global.** `.gitconfig-adobe-ghec` and `.gitconfig-personal`
> **both** rewrite `https://github.com/`, and the `github.com-adobe` SSH alias does not exist on
> the personal machine.

### M2 — `hub.host` (work only) — #119

**Resolved: yes, move it under `profile=work`.** The work spec recommended this; the brief asked
to confirm nothing personal depends on it. Verified — and the finding is **stronger than the
work spec claimed**:

- `hub` **is installed on the personal machine** (`/opt/homebrew/bin/hub`)
- `home/dot_gitconfig:104` defines `pr = "!git push origin HEAD && hub pull-request -b"`

So `hub.host = git.corp.adobe.com` does not merely leak an Adobe hostname onto a personal
machine — it points the personal `git pr` alias at Adobe's internal GitHub Enterprise, where
personal repos do not exist. This is an **active breakage**, not cosmetic pollution.

Under `profile=personal` the key is absent and `hub` correctly defaults to `github.com`.

The neighbouring `[include] path = .gitconfig.hub` (L18) stays unconditional — it is the
machine-local unmanaged-include idiom, and git silently ignores a missing include
(`~/.gitconfig.hub` is absent on the personal machine today).

### M3 — Third-party installer injections — #122, #123

Per-machine shell modules under `home/shell/<tool>/`, existence-gated so each is a **no-op**
where the tool is absent. `home/dot_sheldon/plugins.toml.tmpl` already globs `**/env.zsh`
(L37), `**/path.zsh` (L41) and `**/{keybinding,completion}.zsh` (L57), so **no `plugins.toml`
change is needed** for any of them.

| Machine | Module | Notes |
|---|---|---|
| work | `home/shell/awesome-cli/path.zsh` | PATH entry, `test -d` gated |
| work | `home/shell/scout/completion.zsh` | ⚠️ cache into `fpath`, never `eval` — see below |
| personal | `home/shell/libpcap/path.zsh` | the only genuinely uncovered personal injection |

Because the modules are existence-gated, **all three can live in `home/` unconditionally** —
they are inert on the machine that lacks the tool. No `profile` gating required.

> ⚠️ **`scout`: do not `eval` the completion.** It emits a `#compdef` autoload file, and
> `[plugins.local]` (L56) is deferred **before** `[plugins.compinit]` (L193), so `compdef` does
> not exist yet. Cache it into `~/.zsh/completions` (already on `fpath`) instead.

**Personal-machine methodology note that generalises:** none of the personal machine's four
injections used `# >>> … <<<` sentinel markers. **Sentinel-grep is not a sufficient audit** —
diff rendered-vs-live.

Three of the four personal injections needed no module at all: `deno` is already covered by
`home/shell/deno/env.zsh`, `~/.local/bin` is already on PATH in three places, and `rye` is dead
(`~/.rye` absent; `main` removed rye deliberately).

### M4 — `~/.vimrc` / `gpakosz/.vim` (personal-discovered) — #124, #125

**Decided: adopt upstream.** Retire `home/dot_vimrc`; `~/.vim` becomes a `git-repo` external and
`~/.vimrc` a chezmoi-managed symlink; personal settings move to `home/dot_vimrc.local`.

```yaml
# home/.chezmoiexternal.yaml
.vim:
  type: git-repo
  url: https://github.com/gpakosz/.vim.git
```
```
# home/symlink_dot_vimrc
.vim/.vimrc
```

- `git rm home/dot_vimrc` is **mandatory** — both present ⇒ `.vimrc: inconsistent state`, exit 1.
- Verified end-to-end: vim sources `~/.vimrc` as script **1** and `~/.vimrc.local` as script
  **12** (last ⇒ overrides win); upstream `ignorecase=1`/`hlsearch=1` apply while
  `colorcolumn=81`/`backup=0` from the override win; second apply is a no-op.
- No branch pin needed — `vanilla` *is* upstream's default branch.

**Is this shared or personal?** The *mechanism* is shared (it lands in `home/` for everyone),
but it was only observed on the personal machine. **The work machine's `~/.vimrc` state is not
recorded in `specs/work-dotfiles-gap-analysis.md`** — this must be checked before S/M4 is
applied there, or the work machine could be the one that loses a vimrc. Tracked as an open
question below.

`~/.tmux.conf` has the **identical** unmanaged-symlink shape on the personal machine
(pointing into the existing `oh-my-tmux` external, with a 19.1 K `~/.tmux.conf.local`). It is
*not* currently chezmoi-managed, so nothing breaks today — a reproducibility gap, not a live
risk. #125.

---

## Part 3 — CONFLICTS and resolutions

Where the two machines genuinely disagree.

### C1 — Feature flag values

| Flag | Work | Personal | Resolution |
|---|---|---|---|
| `ruby`, `nodejs`, `k8s`, `fnm` | `true` | `false` | **Moot — see below** |
| `cuda` | `true` | `false` | **Moot**; `false` is the honest value |
| `opencv` | `true` | `false` | Per-machine; inert on macOS, live on Linux |
| `pyenv` | `true` | `false` | **Genuine conflict — personal should be `true`** |
| `fzf_tab` | `false` | *(absent)* | Set `false` on both |

**The conflict mostly dissolves under verification.** `docs/feature-flags.md` states that
`ruby`, `nodejs`, `k8s`, `fnm` and `cuda` are **inert**, and this was re-verified fresh:

```sh
grep -rl '\.<flag>' home/ --include='*.tmpl'    # empty for ruby/nodejs/k8s/fnm/cuda
```

`[plugins.cuda]` in `plugins.toml.tmpl` is a plugin **name**, not a `.cuda` reference.

**Only `pyenv` is live on macOS** (`compat.sh.tmpl`, `compat.bash.tmpl`,
`run_onchange_before_02-macos-install-pyenv.sh.tmpl`). `opencv` is live on Linux only.
`fzf_tab` and `version_manager` are live everywhere.

This was confirmed empirically: flipping all five booleans on the personal machine changed
**exactly one** thing in `chezmoi status` — it added `02-macos-install-pyenv.sh`.

> **Correction to `specs/personal-dotfiles-gap-analysis.md`.** That spec's Finding 3 recommends
> flipping `ruby`/`nodejs`/`k8s`/`fnm` to `true` "to match reality". That is **cosmetic only** —
> those flags drive nothing. The substantive part of the recommendation is `pyenv=true`, which
> is real and correct (pyenv *is* installed there). The all-`false` config is still evidence
> that the non-TTY trap fired, which remains a valid finding.

**Resolution (decided 2026-08-15):** record the flags as inert, set honest values
(`pyenv=true` on personal because it is installed; `cuda=false`/`opencv=false` on macOS), and
**change nothing structurally** — removing the dead prompts belongs to #101, which already owns
repo cleanup. Do not duplicate that scope here.

### C2 — Source-repo state

| | Work | Personal |
|---|---|---|
| Branch | stale `feature-adobetop`, ~30 behind, 10 unmerged | clean, `== origin/main` |
| Merge resurrection | 34 files (broke Copilot CLI) | none |

**Not a conflict to resolve — a difference in starting position.** The work machine needed a
merge and a resurrection guard; the personal machine did not. Both must run the guard before
applying:

```sh
git diff --diff-filter=A --name-only origin/main HEAD
```

### C3 — `chezmoi` binary behaviour

Both machines ran **`v2.31.1`** (Mar 2023) and both are now on **`v2.72.0`**. But it was
*totally non-functional* on work and *merely warned* on personal.

**Explanation (reconciled):** the personal config already carried `version_manager`, and the one
key it lacked — `fzf_tab` — is dereferenced only behind `and (hasKey . "fzf_tab") .fzf_tab`
guards. `myFzfTabRev` is referenced unconditionally at `plugins.toml.tmpl:135` but sits *inside*
the `{{ if $fzfTab }}` block, so it is never evaluated while the flag is false.

**This is a latent tripwire, not a resolved issue:** enabling `fzf_tab` without regenerating the
config fails with `map has no entry for key "myFzfTabRev"`. #129.

### C4 — Orphaned tools under mise

| Machine | Pinned | Orphaned |
|---|---|---|
| work | 25 | 11 |
| personal | 30 | **13** |

The personal list adds **`rclone`** and **`rye`**. **Resolution: union the lists, do not reuse
either.** Both specs independently decided to accept the drops (all are years stale, and all
remain reachable via `~/.tool-versions.asdf.bak` and an untouched `~/.asdf`). #126.

`rye` needs no decision — it is already dead on the personal machine and `main` removed it.

### C5 — `git remote` / `gh`

Work: `origin` was HTTPS while `gh` was ssh, and the active account was the Enterprise Managed
User `malcolm_adobe` — pushes failed outright. Personal: consistent, `bossjones`, ssh.

**Not a repo change.** A per-machine environment precondition. Add to the pre-flight checklist
rather than to `home/`.

### C6 — `hack/doctor` divergence — RESOLVED, port nothing

The work spec recorded `check_dev_environment.py` as 796 lines on `feature-adobetop` vs 698 on
`main`. **Re-verified fresh against the remote:** `origin/feature-adobetop` is at `bf252b7`, and
`hack/doctor/check_dev_environment.py` is now **698 lines on both** — the divergence was already
resolved in favour of `main`, and the branch is pushed, so nothing depends on a local backup.

Only two files remain exclusive to `feature-adobetop`:

| File | Lines | Assessment |
|---|---|---|
| `hack/doctor/check_dev_environment2.py` | 484 | **Every line is commented out.** Dead scratch code. |
| `hack/doctor/example_env_check_output.txt` | 69 | Redundant — `main` already ships `hack/doctor/example_output.txt` |

**Resolution: port nothing; close the question.** Should anything be wanted later, it is
recoverable from `origin/feature-adobetop` at any time.

### C7 — sheldon module loader hardcodes `~/.local/share/chezmoi`

`home/dot_sheldon/plugins.toml.tmpl` hardcodes the path in **10 places** (L36, 40, 51, 56, 125,
130, 193, 215, 221, 225). `.chezmoi.sourceDir` is used **nowhere** in `home/` today.

**Consequence, verified:** the live shell always sources modules from the main checkout, never
from a worktree. That made both analyses safe — a worktree could not affect the running shell —
but it also means **module changes cannot be tested from a worktree**, which directly affects
how #122/#123 get validated.

**Recommendation: parameterise on `{{ .chezmoi.sourceDir }}`, but treat it as its own change
with its own testing** — not a drive-by edit inside the migration.

> ⚠️ **This cuts both ways.** Parameterising makes the live shell follow whatever source
> directory chezmoi was last run from. Applying from a worktree would then point the *real*
> shell at that worktree — a footgun that the current hardcoding accidentally prevents. If
> adopted, it should probably resolve to the *canonical* source dir, not simply to
> `.chezmoi.sourceDir`.

Deferred to #129 / #101. **Not** a blocker for the migration.

---

## Corrections to the input specs

Recorded so the three documents can be reconciled during review.

| # | Spec | Claim | Correction |
|---|---|---|---|
| 1 | personal, Finding 3 | Flip `ruby`/`nodejs`/`k8s`/`fnm` to `true` "to match reality" | Those flags are **inert**; only `pyenv` is substantive (C1) |
| 2 | personal, Finding 4 (first draft) | The `.vim` external must pin branch `vanilla` via `clone.args` | `vanilla` **is** the default branch; no pin needed. *(Already fixed in #115.)* |
| 3 | personal, Finding 4 (first draft) | `.vimrc.local` is tracked upstream ⇒ pull conflicts | The loaded override is **`~/.vimrc.local`**, outside the clone. *(Already fixed in #115.)* |
| 4 | work, Finding 12 | `hack/doctor` diverged 796 vs 698 lines | Already reconciled to 698/698 on the pushed branch; only 2 dead files remain (C6) |
| 5 | work, Finding 3 | `hub.host` is an Adobe *leak* on personal | Understated — it **breaks** the personal `git pr` alias (M2) |

---

## Ordered task list

Maps 1:1 onto epic #116. Dependencies are real.

### Phase 0 — this document
- [ ] Review and agree this spec (#117)

### Phase 1 — shared infrastructure (strictly ordered)
- [ ] S3 — `profile` key + docs + `Makefile` defaults (#118)
- [ ] S4/S5/S2/M2 — `dot_gitconfig.tmpl`: gate `hub.host`, restore `init.defaultBranch`,
      settle `core.editor`, append the routing block **last** (#119)
- [ ] M1 — identity files + `.chezmoiignore` gating (#120)

### Phase 2 — cross-machine fix (independent)
- [ ] S1 — `**/.claude/settings.local.json` (#121)

### Phase 3 — shell modules (parallel)
- [ ] M3 work — `scout` + `awesome-cli` (#122)
- [ ] M3 personal — `libpcap` (#123)

### Phase 4 — symlinks and externals
- [ ] M4 — `.vim` external + `symlink_dot_vimrc` + `dot_vimrc.local`, delete `dot_vimrc` (#124)
- [ ] `~/.tmux.conf` decision (#125)

### Phase 5 — version manager (last)
- [ ] C4 — union the orphan lists (#126)
- [ ] Migrate work, `profile=work` (#127)
- [ ] Migrate personal, `profile=personal` (#128)

### Phase 6 — hygiene (no ordering constraint, coordinate with #101)
- [ ] S7 — delete `dot_zshrc.local.tmpl`
- [ ] C3 — `myFzfTabRev` tripwire
- [ ] C7 — sheldon hardcoded path
- [ ] C1 — inert-flag cleanup (**owned by #101**)
- [ ] C6 — closed, port nothing

---

## The `chezmoi init` commands

Both must run in a **real TTY** — every `promptBool` sits inside `if $interactive`
(`home/.chezmoi.yaml.tmpl` L35–L102), so a non-TTY run silently yields **all-`false`**. That is
exactly how the personal machine's config broke. Verify with `chezmoi data`, never by exit code.

`--source=.` uses the existing working tree; it does **not** re-clone. Keep `init` and `apply`
separate to preserve the review gate.

**Work:**
```sh
cd ~/.local/share/chezmoi
chezmoi init --source=. --debug -v \
  --promptString "Name=Malcolm Jones" \
  --promptString "Email=bossjones@theblacktonystark.com" \
  --promptString "Computer name=adobetop" \
  --promptString "Host name=adobetop" \
  --promptString "version_manager=mise" \
  --promptString "profile=work" \
  --promptBool "ruby=true"  --promptBool "pyenv=true" --promptBool "nodejs=true" \
  --promptBool "k8s=true"   --promptBool "cuda=true"  --promptBool "fnm=true" \
  --promptBool "opencv=true" --promptBool "fzf_tab=false"
```

**Personal:**
```sh
cd ~/.local/share/chezmoi
chezmoi init --source=. --debug -v \
  --promptString "Name=Malcolm Jones" \
  --promptString "Email=bossjones@theblacktonystark.com" \
  --promptString "Computer name=boss workstation" \
  --promptString "Host name=bossworkstation" \
  --promptString "version_manager=mise" \
  --promptString "profile=personal" \
  --promptBool "ruby=true"   --promptBool "pyenv=true" --promptBool "nodejs=true" \
  --promptBool "k8s=true"    --promptBool "cuda=false" --promptBool "fnm=true" \
  --promptBool "opencv=false" --promptBool "fzf_tab=false"
```

Then, on each machine, only after every source change has landed:

```sh
chezmoi diff  --source=.        # review
chezmoi apply -v --source=.     # only after the diff looks right
```

> The `ruby`/`nodejs`/`k8s`/`fnm` values above are **cosmetic** (C1) — they are recorded for
> honesty and future-proofing, not because they change behaviour. `pyenv`, `opencv`,
> `fzf_tab`, `version_manager` and `profile` are the live ones.

> `Computer name` / `Host name` on the personal machine are its **existing** values, which do
> not match its real hostname (`Mac.scarlettlab.home`). Preserved to avoid an unrelated change —
> see open question Q6.

---

## Testing Strategy

Configuration change ⇒ **behavioural assertions**, run before and after on each machine.

**Pre-flight (per machine):**
- Backup checksum verifies
- Behavioural baseline captured
- `git diff --diff-filter=A --name-only origin/main HEAD` is clean (C2)
- `git remote -v` protocol matches `gh auth status`, and the active `gh` account can push (C5)

**Post-apply:**

1. **Git identity routing** (work) — assert **resolved** identity in all six probe dirs, not
   file contents. `~/dev/{malcolm,adobe-platform,adobe-aifoundations,malcolm_adobe}` →
   `malcolm@adobe.com`; `~/dev/bossjones` + an unrelated dir → `bossjones@theblacktonystark.com`.
   `user.email` alone does **not** prove the `bossjones` include matched — assert on
   `url.git@github.com:.insteadOf` too.
2. **`profile` resolved** — `chezmoi data | grep profile`; `chezmoi managed | grep -c gitconfig-`
   → 3 (work) / 0 (personal).
3. **`hub.host` absent on personal** — `chezmoi cat ~/.gitconfig | grep -ci adobe` → 0.
4. **Shell health** — `zsh -i -c exit` exits 0 and its stderr matches the *recorded baseline*,
   not an empty set. The personal machine has a **pre-existing**
   `(eval):1: can't change option: zle` warning that must not be misattributed.
5. **Third-party integrations survive** — `scout`/`awesome-cli` (work), `libpcap` (personal).
6. **vim** — `~/.vimrc` → `.vim/.vimrc`, 764 lines; `~/.vimrc.local` sourced last.
7. **Version manager** — `mise --version`; `~/.tool-versions.asdf.bak` exists; `~/.asdf` intact.
8. **No unintended deletions** — diff the post-apply tree against the backup.

**Already proven during analysis** (read-only, both machines): 14 assertions on the personal
machine and 15 on the work machine — see the respective specs. Plus, fresh for this document:

| # | Assertion | Result |
|---|---|---|
| U1 | `ruby`/`nodejs`/`k8s`/`fnm`/`cuda` read by **no** `.tmpl` | pass |
| U2 | `pyenv` **is** read by 5 templates | pass |
| U3 | Flipping all five flags changes exactly one status entry (`02-macos-install-pyenv.sh`) | pass |
| U4 | `hub` installed on personal; `pr` alias uses it (`dot_gitconfig:104`) | pass |
| U5 | `hack/doctor` is 698/246 on **both** `main` and `origin/feature-adobetop` | pass |
| U6 | `check_dev_environment2.py` is 484 fully-commented-out lines | pass |
| U7 | `~/.zshrc.local` referenced by nothing in `home/`; exists on both machines | pass |
| U8 | `.chezmoi.hostname` = `"Mac"` on personal; used for gating nowhere in `home/` | pass |
| U9 | sheldon loader hardcodes the source path in 10 places | pass |

---

## Acceptance Criteria

- [ ] Both machines: `chezmoi status`/`diff` run without template errors
- [ ] Both: `chezmoi data` reports `version_manager: mise`, correct `profile`, `fzf_tab: false`
- [ ] Work: 5 `includeIf` blocks present; all six probe dirs resolve correctly; 3 identity files managed
- [ ] Personal: **0** `includeIf`, **0** managed identity files, **0** `adobe` references
- [ ] Both: `init.defaultBranch = main`; `**/.claude/settings.local.json` in `~/.gitignore_global`
- [ ] Both: `mise` active, `~/.tool-versions.asdf.bak` created, `~/.asdf` untouched
- [ ] Both: `zsh -i` starts with no *new* warnings versus the recorded baseline
- [ ] Personal: `~/.vimrc` → 764-line upstream vimrc; `dot_vimrc` deleted from source
- [ ] `home/dot_zshrc.local.tmpl` deleted
- [ ] Work: `copilot` loads repository settings with no `matcher cannot be empty` error
- [ ] Every deviation has a documented restore path

---

## Rollback

Both machines have verified, checksummed backups; per-finding restore paths live in the two
input specs.

| Machine | Backup root | Verified |
|---|---|---|
| work | `~/.backup/dotfiles/20260815-192156/` | 367 files |
| personal | `~/.backup/dotfiles/20260815-213326/` | 144 entries, sha256 `OK` |

```sh
# Restore everything (per machine)
RESTORE_DIR=$(mktemp -d)
tar -xzf "$BK"/dotfiles-*.tar.gz -C "$RESTORE_DIR" && cp -a "$RESTORE_DIR"/files/. ~/

# Roll back the version manager (asdf data was never deleted).
# version_manager is sticky -- edit the config directly, then re-render:
sed -i '' 's/^\(\s*version_manager:\).*/\1 "asdf"/' ~/.config/chezmoi/chezmoi.yaml
cd ~/.local/share/chezmoi && chezmoi init --source=. && chezmoi apply --source=.
mv ~/.tool-versions.asdf.bak ~/.tool-versions

# Roll back the chezmoi binary
cp "$BK"/chezmoi-*.bin ~/.bin/chezmoi
```

---

## Open questions

Things this document could **not** settle from evidence available on the personal machine.
Mirrored in epic #116 for discussion. **These are the places where a wrong assumption would do
the most damage.**

- **Q1 — What is `~/.vimrc` on the work machine?** Not recorded in the work spec. If it is also
  a `gpakosz/.vim` symlink, M4 fixes both machines. If it is `main`'s regular file, M4 *changes*
  the work machine's vim setup as a side effect. **Must be checked before M4 lands.**
- **Q2 — Does `~/.tmux.conf` have the same shape on the work machine?** Personal has an
  unmanaged symlink into the `oh-my-tmux` external. Unknown for work (#125).
- **Q3 — Is the `git pr` alias actually used?** M2's severity assumes it matters. If `hub` is
  vestigial on both machines, the cleaner fix may be to **remove `hub.host` and the `pr` alias
  entirely** rather than gate them.
- **Q4 — Are the three `~/.gitconfig-*` files really secret-free?** The work spec says so
  (139/135/139 bytes: a username, an email, a URL rewrite). They cannot be read from the
  personal machine. **Confirm before committing them to a public repo.**
- **Q5 — Should any of the 13 orphaned tools be ported to mise?** Both specs lean "drop all",
  but that is a preference, not evidence. `rclone`, `fd`, `poetry` and `terraform` are the
  plausible keepers.
- **Q6 — Should the personal machine's `computer_name`/`hostname` data be corrected?**
  Currently `boss workstation`/`bossworkstation` versus a real hostname of
  `Mac.scarlettlab.home`. Harmless today (nothing gates on them), but misleading.
- **Q7 — Is there a Linux machine in this fleet?** `opencv` is live only on Linux and the `cuda`
  module is gated on `.chezmoi.os`. If a Linux box exists, C1's "inert on macOS" conclusion is
  only half the story.
- **Q8 — Was the work machine's `cuda: true` deliberate?** It is inert, so it changed nothing;
  the question is whether it signals an *intent* that should be implemented rather than removed.

---

## Notes

- **This document supersedes the two input specs where they conflict.** The inputs remain the
  evidence record; corrections are tabulated above rather than edited in silently.
- **No implementation has been performed.** Both machines have had exactly two mutations:
  a `chezmoi` binary upgrade (`v2.31.1` → `v2.72.0`) and analysis worktrees. Neither
  `~/.config/chezmoi/chezmoi.yaml` was modified.
- **Cross-cutting traps** (sticky keys, TTY requirement, the `chezmoi managed` directory trap,
  sentinel-grep insufficiency, diff-line-count as a bad risk proxy) are recorded at epic level
  in #116 so they apply to every phase.
- **No new libraries required.** Only `chezmoi`, `git`, `gh` and `mise`.
