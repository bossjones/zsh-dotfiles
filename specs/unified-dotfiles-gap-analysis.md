# Plan: Unified Two-Machine Dotfiles Reconciliation

> **Machines:** `adobetop` (work — macOS 15.7.9, arm64, user `malcolm`),
> `supertop` and `minitop` (personal, user `bossjones`) — **see [Part 4](#part-4--fleet-expansion-this-is-a-three-machine-problem);
> Parts 1–3 were written against a two-machine model**
> **Analysis date:** 2026-08-15, revised 2026-08-31
> **Companion:** [`specs/migration-doctor.md`](./migration-doctor.md)
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
| `fzf_tab` | *(absent)* | *(absent)* | **`true` on all three** — revised 2026-08-31 |

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

> **Revision 2026-08-31 — `fzf_tab` is now `true`, and `cuda`/`opencv` have a reason.**
>
> The fleet default is **`fzf_tab: true`**, not `false`. This reverses the row above, both `init`
> commands, and the acceptance criteria — and it promotes C3 from latent hygiene to an active
> Phase 1 concern, because `true` is the first value that ever dereferences `myFzfTabRev`.
>
> `cuda` and `opencv` are **Linux concerns, not macOS ones** (owner, 2026-08-31). `false` on every
> macOS host is therefore the correct value on the merits, not merely the honest one; they are
> revisited when the Linux machine (`boss-deeplearning`, Ubuntu) enters scope in a later phase.
> This closes Q8: work's `cuda: true` was noise, not intent.
>
> Note the work machine's flags read `cuda: true`, `opencv: true` in live `chezmoi data` — so
> under the new target state **both are drift**, tracked by the doctor. See
> [`specs/migration-doctor.md`](./migration-doctor.md).

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

> **Update 2026-08-31 — no longer latent; promoted to Phase 1.**
>
> The fleet default is now `fzf_tab: true` (C1), which makes this the **first configuration that
> actually exercises the dereference**. #129 moves out of Phase 6 hygiene.
>
> Live `chezmoi data` from the work machine confirms the diagnosis directly: `adobetop` has **no
> `version_manager`, no `fzf_tab` and no `profile` key at all**. That absence — not a wrong value
> — is why v2.72 was non-functional there while personal only warned.
>
> **The good news is that absence is recoverable.** `hasKey` is false, so the prompt fires and a
> plain re-run of `chezmoi init` sets all three. Stickiness only bites where a key already exists
> with the wrong value (personal's `hostname: bossworkstation`).
>
> ⚠️ **Two traps when enabling it:**
> 1. **Never hand-edit `~/.config/chezmoi/chezmoi.yaml` to add `fzf_tab: true`.**
>    `plugins.toml.tmpl:135` reads `.myFzfTabRev`, which only `.chezmoi.yaml.tmpl:147` emits, and
>    `missingkey=error` turns the omission into a failed `apply`. Re-running `init` regenerates
>    both keys together and is the only safe path.
> 2. `--promptBool fzf_tab=true` is consumed **inside** the `$interactive` branch
>    (`.chezmoi.yaml.tmpl:111–121`). A non-TTY run needs `CM_fzf_tab=true` in the environment
>    instead.
>
> **The hand-edit is asymmetric — off is safe, on is not.** `specs/fzf-tab.md:445–455` correctly
> tells you to edit `data.fzf_tab: false` directly to disable it, because `$fzfTab` false means
> `plugins.toml.tmpl:135` is never evaluated. **Do not generalise that to enabling it.**

### C4 — Orphaned tools under mise

| Machine | Pinned | Orphaned |
|---|---|---|
| work | 25 | 11 |
| personal | 30 | **13** |

The personal list adds **`rclone`** and **`rye`**. **Resolution: union the lists, do not reuse
either.** Both specs independently decided to accept the drops (all are years stale, and all
remain reachable via `~/.tool-versions.asdf.bak` and an untouched `~/.asdf`). #126.

`rye` needs no decision — it is already dead on the personal machine and `main` removed it.

> **Revision 2026-08-31 — the drops are reversed. Keep 10 of 12, at latest versions.**
>
> Measured on `adobetop`: `~/.tool-versions` has **30 entries**, `~/.asdf/plugins` has **18
> installed** ⇒ **12 orphans**. Owner's decision (2026-08-31):
>
> | Verdict | Tools |
> |---|---|
> | **Keep** (10) | `rclone`, `fd`, `terraform`, `ag`, `packer`, `vault`, `argocd`, `velero`, `kompose`, `dive` |
> | **Drop** (2) | `jsonnet` (0.17.0, 2020), `poetry` (1.1.8 — repo standardised on `uv`) |
>
> **Re-pin at latest, do not port the stale pins.** This dissolves the original "all are years
> stale" objection entirely — they are fresh installs under mise, not migrations of 2021-era
> versions.
>
> k8s tooling (`argocd`, `velero`, `kompose`, `dive`) is retained deliberately: k8s remains
> supported for **work requirements and homelab use**. The `k8s` feature flag being inert (C1) is
> not evidence either way.
>
> **This changes the shape of #126** — from "ratify the drops" to "re-pin 10 tools at current
> versions". Q5 closes; **Q15 opens**: is `vault 1.11.3+ent` deliberate? A `+ent` build may have
> no latest-version equivalent available.

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

## Part 4 — Fleet expansion: this is a three-machine problem

> Added 2026-08-31. Everything above was written against a two-machine model. It is not wrong, but
> it is **incomplete**.

### The fleet

| Name | Profile | User | Identity status |
|---|---|---|---|
| `adobetop` | work | `malcolm` | **Confirmed** — macOS 15.7.9 (24G830), arm64 |
| `supertop` | **personal** | `bossjones` | Apple Silicon laptop. In `~/.ssh/config`; **never surveyed** |
| `minitop` | **personal** | `bossjones` | Hypothesised = `mac-mini` = `Mac.scarlettlab.home`. **Never surveyed** |

`~/.ssh/config` on `adobetop` contains hosts `adobetop`, `supertop` and **`mac-mini`** — there is
no host named `minitop`. A Mac mini at the factory-default `ComputerName` of `Mac` produces
exactly the `.chezmoi.hostname` → `"Mac"` this document already recorded. Hence Q10; hence the
surveys.

### The target shape

**Every work machine should look like every other work machine; every personal machine like every
other personal machine.** Divergence within a profile is drift to eliminate, not configuration to
preserve. Where a machine genuinely needs something its profile does not, the mechanism is a
**chezmoi template with a conditional** — not a third `profile` value.

That settles the question this expansion raises: **`profile` stays two-valued.** `supertop` and
`minitop` both resolving to `personal` is the intended outcome.

### The hostname prerequisite

Host-conditional templating needs a trustworthy host key — and this document already established
that `.chezmoi.hostname` is the collision-prone bare `"Mac"` on the personal machine. Measured on
`adobetop`, macOS exposes **three settable hostnames** and everything else derives from them:

```
scutil --get ComputerName    adobetop        ← settable; spaces/unicode legal
scutil --get LocalHostName   adobetop        ← settable; DNS-safe charset only
scutil --get HostName        not set         ← settable; unset is the macOS DEFAULT
sysctl -n kern.hostname      adobetop.local  ← derived (LocalHostName + .local)
hostname / uname -n          adobetop.local  ← derived
```

`HostName` being unset on a healthy machine means `Mac.scarlettlab.home` was never `scutil
HostName` either — it came from DNS. So:

> **Setting `ComputerName`/`LocalHostName` correctly is a prerequisite for the host-specialization
> mechanism, not cosmetic hygiene.** This upgrades Q6 from "misleading but harmless" to
> load-bearing, and gives the `computer_name`/`hostname` data keys their first real consumer.

### What happens next

Two things, both specified in [`specs/migration-doctor.md`](./migration-doctor.md):

1. **`hack/doctor/doctor.py`** — a uv-scripted, YAML-driven convergence doctor. Makes this
   document's Testing Strategy executable, per-machine, and traceable back to the finding that
   motivated each assertion. `--state target` becomes the definition of done for #116.
2. **Two survey prompts**, filed as GitHub issues labelled `prompt`, one per unsurveyed machine.
   Each is a six-phase runnable prompt: confirm identity → observe → **interview** → classify →
   validate → stop. Read-only; no `chezmoi init`, no `chezmoi apply`.

**Nothing in Phases 1–5 below should execute on `supertop` or `minitop` until their surveys
return.** `adobetop` is not blocked.

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
| 6 | **this doc**, C1 | `fzf_tab` should be `false` on both | **Reversed 2026-08-31** — the fleet default is `true`; promotes C3 to Phase 1 |
| 7 | **this doc**, C4 | Accept the orphan drops | **Reversed 2026-08-31** — keep 10 of 12 at latest versions; only `jsonnet`/`poetry` drop |
| 8 | **this doc**, header | A two-machine fleet | It is **three**; `supertop` and `minitop` are unsurveyed (Part 4) |
| 9 | **this doc**, C1 | `cuda`/`opencv` values are "cosmetic honesty" | They are **Linux-only concerns**; `false` on macOS is correct on the merits (Q8) |

---

## Ordered task list

Maps 1:1 onto epic #116. Dependencies are real.

### Phase 0 — this document
- [ ] Review and agree this spec (#117)

### Phase 1 — shared infrastructure (strictly ordered)
- [ ] **C3 — regenerate each config via `chezmoi init` so `fzf_tab`/`myFzfTabRev` land together**
      (#129, promoted from Phase 6 on 2026-08-31 — `fzf_tab: true` exercises the dereference)
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
- [x] ~~C3 — `myFzfTabRev` tripwire~~ → **moved to Phase 1** (2026-08-31): `fzf_tab: true` is now
      the fleet default, so this is exercised on first apply rather than latent
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
  --promptBool "k8s=true"   --promptBool "cuda=false" --promptBool "fnm=true" \
  --promptBool "opencv=false" --promptBool "fzf_tab=true"
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
  --promptBool "opencv=false" --promptBool "fzf_tab=true"
```

**Personal — `supertop`** (Apple Silicon laptop). ⚠️ **Provisional — do not run before the
`supertop` survey returns.** `Computer name`/`Host name` are proposals, and the flags are the
profile defaults rather than observed values:
```sh
cd ~/.local/share/chezmoi
chezmoi init --source=. --debug -v \
  --promptString "Name=Malcolm Jones" \
  --promptString "Email=bossjones@theblacktonystark.com" \
  --promptString "Computer name=supertop" \
  --promptString "Host name=supertop" \
  --promptString "version_manager=mise" \
  --promptString "profile=personal" \
  --promptBool "ruby=true"   --promptBool "pyenv=true" --promptBool "nodejs=true" \
  --promptBool "k8s=true"    --promptBool "cuda=false" --promptBool "fnm=true" \
  --promptBool "opencv=false" --promptBool "fzf_tab=true"
```

> ⚠️ **`--promptBool "fzf_tab=true"` only works in a real TTY.** It is consumed inside the
> `$interactive` branch (`.chezmoi.yaml.tmpl:111–121`); a non-TTY run needs `CM_fzf_tab=true` in
> the environment instead. See C3.

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
- [ ] All three: `chezmoi data` reports `version_manager: mise`, correct `profile`,
      **`fzf_tab: true`**, `cuda: false`, `opencv: false`, and **no missing keys**
- [ ] All three: `hack/doctor/doctor.py --state target` exits `0` (see `specs/migration-doctor.md`)
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

### Resolved 2026-08-31 — measured on `adobetop`

| # | Question | Answer |
|---|---|---|
| **Q1** | Work machine's `~/.vimrc`? | **Symlink → `.vim/.vimrc`**, `~/.vim` a git repo — the *same shape as personal*. M4 fixes both; **the side-effect risk is retired.** Caveat: `~/.vimrc.local` is **absent** here but present on personal, so M4's `dot_vimrc.local` would *create* a file the work machine never had. A decision, not a no-op. |
| **Q2** | Work machine's `~/.tmux.conf`? | **Also an unmanaged symlink** — but to `/Users/malcolm/dev/bossjones/oh-my-tmux/.tmux.conf`: **absolute, and containing the username**, so it cannot work on a `bossjones` machine. `~/.tmux.conf.local` is 533 lines. **#125 is wider than "personal only"** and is a genuine within-profile divergence. |
| **Q3** | Is the `git pr` alias vestigial? | **No.** On work: `hub` at `/opt/homebrew/bin/hub`, `alias.pr` wired to it, `hub.host = git.corp.adobe.com`. M2's *gate it*, not *remove it*, is correct. |
| **Q4** | Are the `~/.gitconfig-*` files secret-free? | **Yes — read and confirmed.** 139/135/139 bytes exactly as claimed; each is a GitHub username, an email, and a URL rewrite. No tokens, no key paths. **Safe to commit to the public repo**; exposes nothing not already in this document. **#120 unblocked.** |
| **Q5** | Port any orphaned tools to mise? | **Keep 10 of 12, at latest versions.** See the C4 revision. |
| **Q6** | Correct the personal `computer_name`/`hostname`? | **Yes — they stop being decorative.** They become the input to the hostname setter script (`computer_name` → `ComputerName`; `hostname` → `LocalHostName`+`HostName`). `hostname` must be DNS-safe. |
| **Q7** | Is there a Linux machine in the fleet? | **Yes** — `boss-deeplearning` (Ubuntu), among 11 non-Mac ssh hosts. **Explicitly out of scope for now:** get macOS aligned first; Linux is a later phase. C1's "inert on macOS" stands for this phase. |
| **Q8** | Was work's `cuda: true` deliberate? | **No.** `cuda`/`opencv` are Linux concerns. `false` on every macOS host; revisit in the Linux phase. |

### Still open

- **Q15 — Is `vault 1.11.3+ent` deliberate?** Kept in the C4 list, but a `+ent` build may have no
  latest-version equivalent to re-pin to.
- **Q16 — What belongs in a shared ssh `Host *` block?** Cannot be authored from one machine.
  Blocked on both surveys capturing `~/.ssh/config`. See
  [`specs/migration-doctor.md`](./migration-doctor.md#ssh-config-consolidation).
- **Q17 — Does `fzf_tab: true` hold up in practice?** It is the new default (C1) and the first
  configuration to exercise the `myFzfTabRev` dereference (C3). Nothing has run with it enabled on
  any machine yet.
- **Q10 — Is `minitop` = `mac-mini` = `Mac.scarlettlab.home`?** Two chained, unverified
  assumptions. If false, this document's entire "personal machine" evidence base belongs to a
  machine not yet identified. See Part 4.

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
