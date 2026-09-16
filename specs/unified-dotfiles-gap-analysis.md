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
| `fzf_tab` | *(absent)* | *(absent)* | **`false` on all three** — settled 2026-08-31 |

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

> **Settled 2026-08-31 — `fzf_tab` stays `false`, and `cuda`/`opencv` have a reason.**
>
> `fzf_tab: false` is the fleet default on all three machines. It was briefly revised to `true`
> earlier the same day and then **reverted** — the original row stands.
>
> The consequence is that **C3 stays latent and stays in Phase 6.** `false` never dereferences
> `myFzfTabRev` (`plugins.toml.tmpl:3` guards on
> `and (hasKey . "fzf_tab") .fzf_tab`), so the tripwire is not armed by the fleet default. It
> remains a real trap for anyone who later opts in — see C3 — but it does not gate the migration.
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

> **Update 2026-08-31 — still latent, and the missing-key problem is far larger than recorded.**
>
> The fleet default stays `fzf_tab: false` (C1), so the `myFzfTabRev` dereference is **not**
> armed and this stays in Phase 6. It is a live trap only for someone who later opts in.
>
> But the *missing-key* half of C3 is not latent at all, and it is much worse than "one key".
> The doctor's first run on `adobetop` found **22 keys absent** from the live config: the
> template renamed `myAsdf*Version` → `my*Version` (19 keys) and added `myPyenvPythonVersion`,
> `myWtpVersion` and `myFzfTabRev`. With `missingkey=error` that is why **`chezmoi status`
> exits 1 on the work machine today** — the complete mechanism behind "totally non-functional".
> Tracked as drift; see [`specs/migration-doctor.md`](./migration-doctor.md).
>
> Live `chezmoi data` from the work machine confirms the diagnosis directly: `adobetop` has **no
> `version_manager`, no `fzf_tab` and no `profile` key at all**. That absence — not a wrong value
> — is why v2.72 was non-functional there while personal only warned.
>
> **The good news is that absence is recoverable.** `hasKey` is false, so the prompt fires and a
> plain re-run of `chezmoi init` sets all three. Stickiness only bites where a key already exists
> with the wrong value (personal's `hostname: bossworkstation`).
>
> ⚠️ **Two traps for whoever opts in later** (not on the migration path today):
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
> versions". Q5 closes.
>
> **`vault` resolved (Q15, 2026-08-31): re-pin to OSS `2.0.4`,** dropping the `+ent` suffix.
> Verified against the release history — Vault **2.0.0 shipped 2026-04-14** and the 1.x line
> ended at `1.21.4` (2026-03-05), so `2.0.4` (2026-08-04) is current.
>
> ⚠️ **That is two changes at once.** `+ent` → OSS loses Enterprise-only features (namespaces,
> replication, HSM seals), and 1.11 → 2.0 is a **major** version bump across roughly four years.
> Neither is a like-for-like upgrade; if any workflow depended on Enterprise behaviour it will
> stop working.

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
| `supertop` | **personal** | `bossjones` | **Surveyed 2026-08-31** — macOS 26.5.2 (25F84), Mac16,5 / M4 Max, arm64, chezmoi 2.72.0. **Is the machine this document called "the personal machine"** — formerly named `Mac` / `Mac.scarlettlab.home`, renamed before 2026-08-31 (correction 10) |
| `minitop` | **personal** | `bossjones` | **Surveyed 2026-08-31** — macOS 26.6.2 (25G83), Mac16,11 / M4 Pro, arm64, chezmoi 2.31.1. `ComputerName`/`LocalHostName` are the **factory defaults** (`Malcolm’s Mac mini` / `Malcolms-Mac-mini`); only `HostName` was ever set, to `mactop`. Canonical name stays `minitop`; the mini gets renamed during migration (Q12). See §`minitop` survey below |

`~/.ssh/config` on `adobetop` contains hosts `adobetop`, `supertop` and **`mac-mini`** — there is
no host named `minitop`. A Mac mini at the factory-default `ComputerName` of `Mac` produces
exactly the `.chezmoi.hostname` → `"Mac"` this document already recorded. Hence Q10; hence the
surveys.

> **Q10 resolved 2026-08-31 — the hypothesis above was wrong** (correction 10). The `"Mac"` /
> `Mac.scarlettlab.home` identity belonged to **`supertop` before its rename**, not to the mini;
> the ssh host `mac-mini` is a distinct machine live-named `mactop`. Evidence chain in
> [`personal-dotfiles-gap-analysis.md` §Machine identity resolved](./personal-dotfiles-gap-analysis.md#machine-identity-resolved--q10-answered).

### `minitop` survey (2026-08-31) — returned

The #137 survey, run on-machine, read-only. This is measured fact, not proposal. `hosts.minitop`
in `hack/doctor/profiles.yaml` graduated from `hypothesis: true` to real identity values plus
**14 tracked drift entries**.

#### Identity (P0)

| Source | Value |
|---|---|
| `scutil --get ComputerName` | `Malcolm’s Mac mini` — **factory default, never renamed** |
| `scutil --get LocalHostName` | `Malcolms-Mac-mini` — factory default |
| `scutil --get HostName` | **`mactop`** — explicitly set; *not* the healthy unset default |
| `hostname` / `hostname -f` / `uname -n` / `kern.hostname` | `mactop` (all derive from `HostName`) |
| `.chezmoi.hostname` / `fqdnHostname` | `mactop` / `mactop` |
| Hardware | `Mac16,11`, Apple M4 Pro, arm64, user `bossjones` |
| OS | macOS 26.6.2 (25G83) |
| chezmoi | v2.31.1 at `~/.bin/chezmoi` (2023-03-02 build) |

Three settable names, three different values — `doctor.py --identity` flags the disagreement.
Two things this overturns:

1. **The `mactop` name comes from `HostName` alone.** `ComputerName` and `LocalHostName` were
   never touched. "The hostname prerequisite" above generalised from `adobetop` that `HostName`
   is unset on a healthy machine; `minitop` is the fleet's counter-example, and it is the only
   reason `.chezmoi.hostname` reads `mactop` rather than `Malcolms-Mac-mini`.
2. **The old "bare `Mac`" hypothesis could never have matched this machine.** Apple's default on
   this generation embeds the owner's first name. Correction 13.

The doctor auto-resolves this host today via the `mactop` alias (`HostName`) — no exit-3
ambiguity with `supertop`. `Malcolms-Mac-mini` is a second alias so resolution survives Q12
unsetting `HostName` before the rename lands.

#### chezmoi state

- **The source checkout is stale and on a deleted branch.** `~/.local/share/chezmoi` is at
  `3571b56` on `feature-asdf-to-mise` (upstream gone — it merged as PR #83), **83 commits
  behind `origin/main`**; HEAD is an ancestor of `origin/main`, so a fast-forward loses
  nothing. This masks two things: `chezmoi status` exits **0** here because the old template
  still declares the old keys, and the common `no-resurrected-files` check FAILS for the wrong
  reason — the C2 diff lists `.claude/` files that `main` has since *deleted*, not files this
  machine resurrected. Against this branch's template, `chezmoi --source … status` fails with
  `map has no entry for key "myRubyVersion"` — adobetop's C3 class exactly.
- **Config:** 19 pre-rename `myAsdf*Version` keys; `fzf_tab` / `myFzfTabRev` /
  `myPyenvPythonVersion` absent; `computer_name: "boss workstation"` and
  `hostname: "bossworkstation"` present-but-wrong (sticky); `version_manager: "mise"` already
  correct. All seven feature flags `false`.
- **asdf → mise has already run here** (S6 landed 2026-06-01 via the merged `feature-asdf-to-mise`
  branch): `~/.tool-versions.asdf.bak` exists (30 tools), `~/.tool-versions` is gone,
  `~/.config/mise/config.toml` pins 17 tools, `mise ls` shows every one installed,
  `ruby.compile=false`. asdf 0.11.2 (brew) and `~/.asdf` (18 plugins) remain as the rollback
  path. Orphans relative to the C4 list: only `golang` → `go` (a rename, not a drop) and `rye`.
- **Pending apply surface against the live (stale) checkout:** 2 ` R` scripts only — every
  managed file is byte-identical to its rendered template.

#### Dotfile spot-checks

| Item | Observed 2026-08-31 | Bearing |
|---|---|---|
| `~/.vimrc` | chezmoi-managed regular file (`dot_vimrc`, 93 lines); `~/.vim` absent | Pre-M4 shape. Not drift — `main` still ships `dot_vimrc` |
| `~/.tmux.conf` | unmanaged symlink → `/Users/bossjones/dev/bossjones/oh-my-tmux/.tmux.conf`; `~/.tmux.conf.local` 416 lines, unmanaged | Same shape as supertop and adobetop (#125); the username is correct, so it works today |
| `~/.zshrc`, `~/.zprofile` | **diff clean** against the rendered templates | Zero injections in the files M3 was written for |
| `~/.zshenv` | unmanaged, one line: `. "$HOME/.cargo/env"` (rustup) | The only injection on this machine → M3 (#123) |
| `~/.zshrc.local` | present, 3.4K, `RBENV_VERSION=2.7.2` | S7; still chezmoi-managed here because the checkout predates the deletion |
| `hub` / `hub.host` | `/opt/homebrew/bin/hub` installed; `hub.host = git.corp.adobe.com` | M2's breakage, live (#119) |
| `~/.gitconfig-*` / `includeIf` | none / 0 | M1 stays work-only |
| `core.editor` / `init.defaultBranch` | `vim` / unset | S5 already satisfied; S2 still needed |
| `~/.gitignore_global` | lacks `**/.claude/settings.local.json` | S1 (#121) |
| Live tools vs flags | `pyenv` 3.12.8 owns `python3`; `fnm` owns `node` 20.19.5; ruby 3.4.9 and the k8s tools via mise — **all with their flag `false`** | P2 interview input (trap 2) |
| Shell health | `zsh -i -c exit` → 0; stderr = 4× `(eval):1: can't change option: zle`; ~0.45s startup | Baseline, identical to supertop's F16 |
| Toolchain | `/usr/bin/make`, `/usr/bin/clang`, `xcrun` all fail to load — Xcode 26.6 loader `Symbol not found: _XPCTypeBool`; standalone CLT 26.6.0 healthy | **New finding → #138, since diagnosed and repaired** (see the note below the doctor verdict). Every `make` target was dead on this machine |

#### Doctor verdict

```text
./hack/doctor/doctor.py --state today                → 3 pass · 14 known   (exit 0)
./hack/doctor/doctor.py --state target --phase all   → 13 pass · 23 fail  (exit 1)
```

The target-state reds are the fleet's pending shared work (S1, S2, S7, M4, `fzf_tab`, M2) plus the
14 drift entries and the two new `personal` flag checks; none is unexplained. `hack/doctor/tests`: 50 passed, 2 skipped, and the
smoke-doctor steps pass — both run as their underlying commands, because `make` could not start
at survey time (#138).

> **Toolchain: diagnosed and repaired, later on 2026-08-31 (#138 → PR #139).** Not a broken
> Xcode. `Xcode.app` had been upgraded 16.2 → 26.6 **in place**, but the system-components step
> that installs its private frameworks never ran, so an Xcode-16.2 `CoreDevice` was still
> resolving against the `Mercury` shipped with macOS 26.6.2 — hence `Symbol not found:
> _XPCTypeBool`. The tell is the **receipt, not the app**: `xcodebuild -version` said `Xcode 26.6`
> throughout while `pkgutil --pkg-info com.apple.pkg.XcodeSystemResources` said
> `16.2.0.0.1733547573`, which is what made it hard to see. Repaired with the pkg Xcode already
> ships, which keeps Xcode selected rather than falling back to the CLT:
> `sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/XcodeSystemResources.pkg -target /`.
> The receipt now reads `26.6.0.0.1781586605`, and `/usr/bin/make`, `/usr/bin/clang` and
> `xcrun --find cc` all work — Makefile targets are usable on the mini again.
>
> PR #139 adds two **common** checks so the fleet catches this next time:
> `xcode-toolchain-shims-usable` (the symptom) and `xcode-system-resources-match-xcode` (the
> cause — it compares receipt major to app major, so it fires while the toolchain still works).
> No drift entry survives: the machine is repaired, and a drift that no longer holds is a FAIL by
> design, so `minitop-xcode-shims-broken` was deleted from `profiles.yaml`.

#### ssh config (Q16 input)

16 `Host` entries, **no `Host *`**. Fleet Macs present: `supertop` and `mac-mini` (this machine,
self-referential); no `minitop`, `mactop` or `adobetop` entry. The setting-frequency table is in
the #137 comment (names only — this repo is public). The candidate shared block is the same
eight lines as adobetop's, *minus* `StrictHostKeyChecking no` / `UserKnownHostsFile /dev/null`
per the standing warning in `migration-doctor.md`. One new finding: **9 of 16 entries name an
`IdentityFile` under another user's home directory** — copied from adobetop's user, so they
cannot resolve on a `bossjones` machine. A consolidation item, not a `Host *` item.

#### P2 interview — every data key, owner-answered (2026-08-31)

Asked one key at a time in the *"this machine has X / the profile has Y / the spec recommends Z
because W"* form, after P1 had established X. Recorded verbatim on #137.

| Key | Live on minitop | supertop | Answer | Sticky? |
|---|---|---|---|---|
| `computer_name` | `boss workstation` | `boss workstation` | **`minitop`** | yes — present-but-wrong |
| `hostname` | `bossworkstation` | `bossworkstation` | **`minitop`** | yes |
| `name` / `email` | Malcolm Jones / bossjones@… | same | **keep** | — |
| `profile` | absent (no template key yet, #118) | absent | **`personal`** | no |
| `pyenv` | `false` (pyenv owns `python3`) | `false` | **`true`** | yes |
| `fnm` | `false` (fnm owns `node`) | `false` | **`true`** | yes |
| `ruby` | `false` (3.4.9 via mise) | `false` | **`true`** | yes |
| `nodejs` | `false` (20.19.5 via fnm) | `false` | **`true`** | yes |
| `k8s` | `false` (toolset via mise) | `false` | **`true`** | yes |
| `cuda` / `opencv` | `false` / `false` | same | **both `false`** (Q8) | — |
| `fzf_tab` | absent | absent | **`false`, present** (Q17) | no — absent ⇒ prompt fires |
| `version_manager` | `mise` (migration already ran) | `asdf` | **`mise`** | — already right |

Consequences folded into `profiles.yaml`: the five booleans are now `profiles.personal` checks
(`personal-pyenv-true`, `personal-inert-flags-honest`), so supertop's target state carries the
same answer; minitop's present-but-wrong values are drift `minitop-feature-flags-false`. Because
`computer_name`, `hostname` and the five flags are all present-but-wrong, minitop's corrective
init needs **`--data=false`** exactly like supertop's (correction 12) — `version_manager` is the
one key it does *not* need to fix.

#### What the survey did *not* do

No `chezmoi init`, no `chezmoi apply`, no `scutil --set`, no fast-forward of the stale checkout,
no `xcode-select`. Applying is a separate, reviewed step under epic #116.

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
2. **Two survey prompts**, filed as GitHub issues labelled `prompt` — [#136 (supertop)](https://github.com/bossjones/zsh-dotfiles/issues/136) and [#137 (minitop)](https://github.com/bossjones/zsh-dotfiles/issues/137).
   Each is a six-phase runnable prompt: confirm identity → observe → **interview** → classify →
   validate → stop. Read-only; no `chezmoi init`, no `chezmoi apply`.

**Nothing in Phases 1–5 below should execute on `supertop` or `minitop` until their surveys
return.** `adobetop` is not blocked.

> **2026-08-31: the `supertop` survey has returned** (recorded in
> [`personal-dotfiles-gap-analysis.md` §Supertop re-survey](./personal-dotfiles-gap-analysis.md#supertop-re-survey-2026-08-31),
> folded into `hack/doctor/profiles.yaml`) — **`supertop` is unblocked**.
>
> **2026-08-31: the `minitop` survey has returned too** (§`minitop` survey above, folded into
> `profiles.yaml` as 13 drift entries) — **`minitop` is unblocked** for Phases 1–5, subject to the
> P2 interview answers on #137. The #138 toolchain repair is **done** (PR #139), so it is no
> longer a prerequisite.

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
| 6 | **this doc**, C1 | `fzf_tab` should be `false` on both | **Stands.** Briefly revised to `true` on 2026-08-31 and reverted the same day; C3 therefore stays in Phase 6 |
| 7 | **this doc**, C4 | Accept the orphan drops | **Reversed 2026-08-31** — keep 10 of 12 at latest versions; only `jsonnet`/`poetry` drop |
| 8 | **this doc**, header | A two-machine fleet | It is **three**; `supertop` and `minitop` are unsurveyed (Part 4) |
| 9 | **this doc**, C1 | `cuda`/`opencv` values are "cosmetic honesty" | They are **Linux-only concerns**; `false` on macOS is correct on the merits (Q8) |
| 10 | **this doc**, Part 4 / Q10 | `minitop` = `mac-mini` = `Mac.scarlettlab.home` | **Resolved NO (2026-08-31).** `Mac.scarlettlab.home` was **`supertop` before its rename**; the ssh host `mac-mini` is a distinct machine live-named **`mactop`**. The "personal machine" evidence base therefore belongs to `supertop` — **now a surveyed machine**, killing Q10's worst-case branch. Evidence: this spec's backup root, worktree, upgraded chezmoi v2.72.0 and renamed `my*Version` keys are all on `supertop`, while `mactop` still runs v2.31.1 with pre-rename `myAsdf*` keys |
| 11 | **this doc**, Part 4 | `hosts.minitop` aliases `[Mac, mac-mini, Mac.scarlettlab.home]` | `Mac`/`Mac.scarlettlab.home` were **supertop's former names** — removed from `minitop`'s aliases (now `[mactop, mac-mini]`). **Owner decision 2026-08-31: canonical fleet name stays `minitop`**; the mini's observed `mactop` name is identity drift, fixed by renaming the machine during its migration |
| 12 | **this doc**, per-machine init commands | `supertop`'s `--promptString` values take effect | On `supertop`, `computer_name`/`hostname`/`version_manager` are **present-but-wrong** in the live config, so `hasKey` short-circuits those prompts and their `--promptString` values are **silently ignored**. The command needs `--data=false` (re-prompts everything) or a prior hand-edit of `~/.config/chezmoi/chezmoi.yaml` |
| 13 | **this doc**, Part 4 "The hostname prerequisite"; `profiles.yaml` @ 6b01ec9 | `HostName` is unset on every healthy Mac; `minitop`'s `LocalHostName` is `mactop` | **Both wrong (2026-08-31, #137 P0).** On `minitop`, `HostName` is *explicitly set* to `mactop` and is the sole source of that name; `ComputerName`/`LocalHostName` are the factory defaults `Malcolm’s Mac mini` / `Malcolms-Mac-mini`. The `minitop-named-mactop` drift entry written from the ssh session asserted `LocalHostName=mactop` and failed on-machine — replaced by one entry per settable name |

---

## Ordered task list

Maps 1:1 onto epic #116. Dependencies are real.

### Phase 0 — this document
- [ ] Review and agree this spec (#117)

### Phase 1 — shared infrastructure (strictly ordered)
- [ ] **C3 (missing-key half) — regenerate each config via `chezmoi init`.** `adobetop` is 22
      keys short and `chezmoi status` exits 1 there, so nothing else in this phase can be
      verified until it is regenerated (#129). The `myFzfTabRev` half stays in Phase 6.
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
- [ ] C3 — `myFzfTabRev` tripwire (**stays here**: the fleet default is `fzf_tab: false`, so the
      dereference is never evaluated. Arms only if someone opts in) rather than latent
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
  --promptBool "opencv=false" --promptBool "fzf_tab=false"
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

**Personal — `supertop`** (Apple Silicon laptop). ~~Provisional — do not run before
[#136](https://github.com/bossjones/zsh-dotfiles/issues/136) returns.~~ **Survey returned 2026-08-31**: `Computer name`/`Host name` = `supertop` are
confirmed correct (they match live scutil values). ⚠️ But the survey also found
`computer_name`/`hostname`/`version_manager` **present-but-wrong** in the live config
(`boss workstation`/`bossworkstation`/`asdf`), so `hasKey` short-circuits those prompts and the
`--promptString` values below would be **silently ignored** (correction 12). `--data=false` added
so every prompt fires fresh:
```sh
cd ~/.local/share/chezmoi
chezmoi init --source=. --data=false --debug -v \
  --promptString "Name=Malcolm Jones" \
  --promptString "Email=bossjones@theblacktonystark.com" \
  --promptString "Computer name=supertop" \
  --promptString "Host name=supertop" \
  --promptString "version_manager=mise" \
  --promptString "profile=personal" \
  --promptBool "ruby=true"   --promptBool "pyenv=true" --promptBool "nodejs=true" \
  --promptBool "k8s=true"    --promptBool "cuda=false" --promptBool "fnm=true" \
  --promptBool "opencv=false" --promptBool "fzf_tab=false"
```

**Personal — `minitop`** (Mac mini). **Survey returned 2026-08-31** (#137); every value below
is an owner answer from the P2 interview, not a default. Same `--data=false` reason as supertop:
`computer_name`/`hostname` and all five booleans are present-but-wrong in the live config, so
without it the prompts are silently skipped. `version_manager` is already `mise` here.
**Prerequisites**, in order: fast-forward the stale source checkout (`git checkout main && git
pull --ff-only` — it is on the merged `feature-asdf-to-mise` branch, 83 behind), upgrade chezmoi
v2.31.1 → v2.72.0 (personal spec F2 recipe). The toolchain repair once listed here (#138) is
**already done** — `XcodeSystemResources.pkg` was reinstalled on 2026-08-31, so compiling works.
```sh
cd ~/.local/share/chezmoi
chezmoi init --source=. --data=false --debug -v \
  --promptString "Name=Malcolm Jones" \
  --promptString "Email=bossjones@theblacktonystark.com" \
  --promptString "Computer name=minitop" \
  --promptString "Host name=minitop" \
  --promptString "version_manager=mise" \
  --promptString "profile=personal" \
  --promptBool "ruby=true"   --promptBool "pyenv=true" --promptBool "nodejs=true" \
  --promptBool "k8s=true"    --promptBool "cuda=false" --promptBool "fnm=true" \
  --promptBool "opencv=false" --promptBool "fzf_tab=false"
```

> ⚠️ **Every `--promptBool` above needs a real TTY.** They are consumed inside the `$interactive`
> branch (`.chezmoi.yaml.tmpl:111–121`), so a non-TTY run silently yields all-`false` — exactly
> how the personal machine's config broke. Verify with `chezmoi data`, never by exit code.
> `fzf_tab` additionally accepts `CM_fzf_tab=true` in the environment for non-TTY opt-in.

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
      **`fzf_tab: false`**, `cuda: false`, `opencv: false`, and **no missing keys**
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

- **Q16 — What belongs in a shared ssh `Host *` block?** Cannot be authored from one machine.
  Supertop's `~/.ssh/config` captured on #136 and minitop's on #137 (both 2026-08-31) — **no
  longer blocked on a survey; authoring is pending.** All three configs share the same eight-line
  per-host block; the shared file is that block minus `StrictHostKeyChecking no` /
  `UserKnownHostsFile /dev/null`. minitop adds a consolidation item: 9 of its 16 entries carry an
  `IdentityFile` under another user's home. See
  [`specs/migration-doctor.md`](./migration-doctor.md#ssh-config-consolidation).

### Resolved 2026-08-31 (second round)

| # | Question | Resolution |
|---|---|---|
| **Q15** | Is `vault 1.11.3+ent` deliberate? | **No — re-pin to the latest OSS build, `2.0.4`.** Two changes in one: `+ent` → OSS (loses Enterprise-only namespaces, replication, HSM seals) and a **major** 1.11 → 2.0 bump. Verified against the release history: Vault 2.0.0 shipped 2026-04-14; the 1.x line ended at 1.21.4 on 2026-03-05. |
| **Q17** | Does `fzf_tab: true` hold up? | **Moot — the default reverts to `false`.** Nothing exercises `myFzfTabRev`, so C3's tripwire stays latent and stays in Phase 6. |
| **Q10** | Is `minitop` = `mac-mini` = `Mac.scarlettlab.home`? | **No** (correction 10). `Mac.scarlettlab.home` was `supertop` pre-rename; `mac-mini` is a distinct machine live-named `mactop`. The "personal machine" evidence base belongs to **`supertop` — now surveyed**. Canonical name for the mini stays `minitop` (correction 11). See [`personal-dotfiles-gap-analysis.md` §Machine identity resolved](./personal-dotfiles-gap-analysis.md#machine-identity-resolved--q10-answered). |

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
