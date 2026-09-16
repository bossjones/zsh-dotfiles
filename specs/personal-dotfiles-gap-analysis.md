# Plan: Personal Machine (`supertop`, formerly `Mac.scarlettlab.home`) Dotfiles Gap Analysis

> **Machine:** `supertop` (macOS 26.5.2, Mac16,5 / M4 Max, arm64, user `bossjones`) —
> named `Mac` / `Mac.scarlettlab.home` when this analysis was written; renamed between
> 2026-08-16 and 2026-08-31. See [Machine identity resolved](#machine-identity-resolved--q10-answered).
> **Analysis date:** 2026-08-15 · **Reconciled:** 2026-08-31 against
> [`unified-dotfiles-gap-analysis.md`](unified-dotfiles-gap-analysis.md) (PR #130)
> **Baseline:** `origin/main` @ `41d8a98` (merge of PR #112)
> **Backup root:** `~/.backup/dotfiles/20260815-213326/` (re-verified present 2026-08-31)
> **Worktree:** `~/.local/share/chezmoi-gap-analysis` on `feat/personal-dotfiles-gap-analysis`
> (re-verified 2026-08-31; stale at `2c0b1aa`, pre-rebase — see re-survey §worktrees)

---

## Status (2026-08-31) — reconciled against the unified spec

This spec is the **evidence record** for the personal machine.
[`unified-dotfiles-gap-analysis.md`](unified-dotfiles-gap-analysis.md) (PR #130) is the
**decision gate** and supersedes this document wherever they disagree. Per that spec's own
convention, nothing below is edited in silently — the original sixteen findings stand as
written, and this table records what happened to each one.

| Finding | Disposition | Superseded / mapped by |
|---|---|---|
| F1 — source repo clean | **Stands** | Unified C2 ("a difference in starting position, not a conflict") |
| F2 — chezmoi 2.31.1 → 2.72.0 | **Stands, resolved** | Unified C3; the same upgrade is still pending on minitop (v2.31.1 live there) |
| F3 — all feature flags `false` | **Corrected** | Unified C1 + correction row 1: `ruby`/`nodejs`/`k8s`/`fnm` are **inert** — no template reads them, so flipping them is cosmetic. `pyenv=true` is the one substantive flip. The all-`false` config remains valid evidence the non-TTY trap fired |
| F4 — `~/.vimrc` gpakosz symlink | **Stands, adopted** | Unified M4; Q1 later showed adobetop has the *same* shape, retiring the side-effect risk. Symlink re-verified live on supertop 2026-08-31 |
| F5 — 13 orphaned tools, drop all | **Superseded** | Unified C4 as **reversed 2026-08-31**: keep 10 of 12 re-pinned at latest; only `jsonnet` and `poetry` drop. `vault` re-pins to OSS **2.0.4** (Q15 — note the double breaking change: `+ent`→OSS *and* 1.11→2.0). The union question (F5's caveat) is closed |
| F6 — gitconfig loses 2 / gains 11 | **Stands** | S2 (`init.defaultBranch`), S4 (`.tmpl` conversion), S5 (`core.editor`), M1 (identity routing, work-only), M2 (`hub.host`). M2's breakage **confirmed live on supertop 2026-08-31**: `hub` installed and global `hub.host = git.corp.adobe.com` |
| F7 — installer injections, no sentinels | **Stands** | M3 (`libpcap/path.zsh` → #122/#123); the no-sentinel methodology point generalised at unified L205–207 |
| F8 — statically-baked `.zshrc` | **Stands** | Fixed as a side effect of applying `main` |
| F9 — frozen PATH in `.zprofile` | **Stands** | No remediation needed |
| F10 — `ulimit -n` loss benign | **Stands** | No remediation proposed |
| F11 — remote/`gh` consistent | **Stands** | Unified C5 contrast (work machine's failure does not reproduce) |
| F12 — `fzf_tab`/`myFzfTabRev` missing | **Stands, confirmed** | Unified C3 (latent half stays Phase 6; `fzf_tab` stays `false` fleet-wide per Q17). Doctor FAIL captured live 2026-08-31 — see re-survey |
| F13 — `profile` key needed | **Stands, decided** | S3 — shared infrastructure, both machines; still unimplemented (#118) |
| F14 — diff line-count overstates risk | **Stands** | Carried up as a cross-cutting trap (unified L793–795) |
| F15 — `.gitignore_global` loses a line | **Stands** | S1 (#121) — promoted to cross-machine, reproduced independently |
| F16 — pre-existing `zle` warning | **Stands** | Tracked as drift, not `common`, in the doctor (#129) |

Open questions this spec handed forward (original Notes section, unchanged below):

- `~/.tmux.conf` same treatment → **answered**: unified Q2/#125 — adobetop's symlink
  hardcodes `/Users/malcolm`, so #125 is *wider* than personal-only. Supertop's symlink
  targets the correct user path and works today.
- Implement `profile` → **decided**: S3, #118. Sticky; still unimplemented.
- Union the orphan lists → **closed**: C4 reversal replaces the union question entirely.
- `core.editor` vim vs nano → **S5 recommends `vim`**; if `nano` wins, change it once,
  unconditionally — never gate on `profile`.

## Machine identity resolved — Q10 answered

The unified spec's Q10 asked whether `minitop` = `mac-mini` = `Mac.scarlettlab.home`
(two chained, unverified assumptions), warning that if false, "this document's entire
*personal machine* evidence base belongs to a machine not yet identified."

**Q10 is resolved: NO — and the evidence base is better off for it.**
`Mac.scarlettlab.home` was **this laptop**, since renamed `supertop`. The ssh host
`mac-mini` is a **third, distinct machine whose live hostname is `mactop`**.

Evidence chain (2026-08-31):

1. **This spec's artifacts are on supertop.** The backup root
   `~/.backup/dotfiles/20260815-213326/` (behaviour-baseline.txt, chezmoi-preupgrade.bin,
   tarball + sha256, both diff/status captures) and the analysis worktree
   `~/.local/share/chezmoi-gap-analysis` on this very branch both exist here.
2. **F2's chezmoi upgrade landed here.** Supertop runs v2.72.0; its live config carries
   the *renamed* `my*Version` keys. The machine this spec analysed is this machine.
3. **The mac-mini is somebody else.** An owner ssh session (`ssh mac-mini`, prompt
   `bossjones@mactop`) shows chezmoi **v2.31.1** (the 2023 build F2 replaced *here*) and
   pre-rename `myAsdf*Version` config keys — a state this spec never described.
4. `.chezmoi.hostname` on this machine now resolves to `supertop` (fqdn
   `supertop.local`), not the `"Mac"` recorded in the unified spec on 2026-08-16 — the
   rename happened between the two dates.

Consequences:

- The unified spec's "personal machine" evidence (inherited from this document) belongs
  to **supertop, which is now a surveyed machine** — the Q10 doomsday branch is dead.
- `hosts.minitop`'s aliases `[Mac, mac-mini, Mac.scarlettlab.home]` in
  [`../hack/doctor/profiles.yaml`](../hack/doctor/profiles.yaml) mixed two machines:
  `Mac`/`Mac.scarlettlab.home` were supertop's former names. Corrected to
  `[mactop, mac-mini]`.
- **Owner decision (2026-08-31): the canonical fleet name stays `minitop`.** The mini's
  observed name `mactop` is identity drift; the machine will be renamed during its
  migration (`scutil --set` via the Q12 setter script, operator-reviewed).
- Issue #136 (supertop survey) is satisfied by the re-survey below; #137 (minitop) has
  its done-criterion #1 ("answer Q10 definitively, either way") met but the on-machine
  P0–P5 survey still pending.

## Supertop re-survey (2026-08-31)

The #136 survey, run on-machine, read-only. This section is measured fact, not proposal.

### Identity (P0)

| Source | Value |
|---|---|
| `scutil --get ComputerName` | `supertop` |
| `scutil --get LocalHostName` | `supertop` |
| `scutil --get HostName` | **not set** (the healthy macOS default — deliberately not drift, same doctrine as adobetop) |
| `hostname` | `supertop.local` |
| `.chezmoi.hostname` / `fqdnHostname` | `supertop` / `supertop.local` |
| Hardware | `Mac16,5`, Apple M4 Max, arm64 |
| OS | macOS 26.5.2 (25F84) |
| chezmoi | v2.72.0 (2026-08-02 build) |

The doctor resolves this machine **by auto, no exit-3 ambiguity** — LocalHostName is set
correctly, so the supertop/minitop fingerprint collision
([`migration-doctor.md`](migration-doctor.md) §resolution) never arises here.

### Live chezmoi data vs the template

`~/.config/chezmoi/chezmoi.yaml` against `home/.chezmoi.yaml.tmpl`'s `data:` block:

- **Missing (absent → `hasKey` false → a plain `chezmoi init` re-run recovers):**
  `fzf_tab`, `myFzfTabRev`. This is C3's missing-key class — supertop is 2 keys short
  where adobetop was 22.
- **Present but wrong (sticky — `hasKey` short-circuits every prompt and
  `--promptString`; requires `chezmoi init --data=false` or a hand-edit):**
  - `version_manager: "asdf"` — target is `mise` (S6)
  - `computer_name: "boss workstation"`, `hostname: "bossworkstation"` — target
    `supertop`/`supertop`. Load-bearing since Q6/Q12: these keys feed the hostname
    setter script.
- Everything else matches the current template (renamed `my*Version` keys present,
  `myPyenvPythonVersion`/`myWtpVersion` present, flags all `false`, `pyenv: false`).

Doctor verdict (`./hack/doctor/doctor.py --state today`):

```text
Host:    supertop    (resolved by: auto)
Profile: personal    state=today  phase=always

  ✗ FAIL   chezmoi-config-has-every-key     missing from chezmoi data: fzf_tab, myFzfTabRev
           traces: C3, #129
  ✓ PASS   shell-starts-clean
  ✓ PASS   chezmoi-templates-render

2 pass · 1 fail
```

### Pending apply surface

`chezmoi status`: **34 entries** — 14 ` M`, 10 ` R` (scripts), 8 `MM`, 2 ` A` — plus the
`config file template has changed` warning. The live source `~/.local/share/chezmoi` sits
at `41d8a98`, **10 commits behind `origin/main`** (pre-#130).

### Dotfile spot-checks (findings re-verified live)

| Item | Observed 2026-08-31 | Bearing |
|---|---|---|
| `~/.vimrc` | symlink → `.vim/.vimrc` (gpakosz clone) | F4/M4 shape intact |
| `~/.tmux.conf` | symlink → `/Users/bossjones/dev/bossjones/oh-my-tmux/.tmux.conf` | Same unmanaged-absolute shape as adobetop (#125), but the username is *correct* here — works today, reproducibility gap only |
| `~/.zshrc.local` | present, 3.3K, `RBENV_VERSION=2.7.2` et al. | Supports S7 (delete the template; sourcing would activate stale config) |
| `hub` / `hub.host` | `/opt/homebrew/bin/hub` installed; global `hub.host = git.corp.adobe.com` | **M2's active breakage, live on this machine** — personal `git pr` points at Adobe GHE |
| `~/.gitconfig-*` | none (glob matches nothing) | M1 stays work-only |
| `core.editor` | `nano` | S5 input |
| `init.defaultBranch` | `main` (currently set live) | S2 still needed — applying `main`'s `dot_gitconfig` would lose it |
| version managers | asdf **and** mise both installed | S6 migration is a switch, not an install |
| Orphan sample | `jsonnet`, `poetry`, `vault` binaries absent; `opa`/`k9s`/`helm`/`helmfile`/`kubectl`/`mkcert` via asdf shims | Consistent with C4-as-reversed (the 2 drops are already gone here) |

### Worktrees

`git -C ~/.local/share/chezmoi worktree list` (2026-08-31):

```text
~/.local/share/chezmoi              41d8a98  [main]                                (10 behind origin/main)
~/.local/share/chezmoi-gap-analysis 2c0b1aa  [feat/personal-dotfiles-gap-analysis] (stale: branch rebased+pushed as 6cd8873)
~/.local/share/chezmoi-unified      fab3804  [feat/unified-dotfiles-gap-analysis]  (branch merged as PR #130)
```

Refresh commands (documented, **not executed** — same read-only discipline as the rest of
this spec):

```sh
git -C ~/.local/share/chezmoi fetch origin
git -C ~/.local/share/chezmoi-gap-analysis reset --hard origin/feat/personal-dotfiles-gap-analysis
git -C ~/.local/share/chezmoi worktree remove ~/.local/share/chezmoi-unified   # merged; no longer needed
```

## Running this branch on minitop (ssh `mac-mini`, live name `mactop`)

The owner plans to run this same branch on the Mac mini. Facts from the owner's ssh
session (2026-08-31, `chezmoi data` pasted from `bossjones@mactop`):

- Live hostname/fqdn: `mactop` (fleet target name: **`minitop`** — rename decided, see
  identity section above)
- chezmoi **v2.31.1** at `~/.bin/chezmoi` (2023-03-02 build — the same vintage F2
  replaced on supertop)
- Config keys are **pre-rename** `myAsdf*Version` (e.g. `myAsdfRubyVersion: 3.4.9`) —
  the full 19-key rename gap, the same class as adobetop's 22-missing-keys (C3)
- `version_manager: "mise"` **already present and correct** — minitop skips the sticky
  hand-edit supertop needs for S6
- All feature flags `false`; `fzf_tab`/`myFzfTabRev`/`myPyenvPythonVersion`/`profile`
  absent; `computer_name`/`hostname` carry the same stale
  `boss workstation`/`bossworkstation` values (present-but-wrong → sticky)
- arm64, user `bossjones` — confirming the doctor's fingerprint-ambiguity premise

**Prerequisites before anything runs there** (in order):

1. **#137 on-machine survey (P0–P5).** Includes the artifact check this spec's header
   documents for supertop — run interactively (BatchMode ssh fails host-key verification
   from supertop):

   ```sh
   ssh mac-mini 'ls -ld ~/.backup/dotfiles/20260815-213326 ~/.local/share/chezmoi-gap-analysis 2>&1'
   ```

   > **Checked 2026-08-31 (owner-run):** neither path exists on the mini — `No such file
   > or directory` for both. This spec's artifacts were created on supertop only, closing
   > the last loose end in the Q10 evidence chain. The minitop migration therefore starts
   > from zero: its own backup must be created there before anything else (Task 1 pattern).
2. **Capture `~/.ssh/config` into #137** for Q16 (scrub private IPs; machine names only —
   public repo).

   > **Both done 2026-08-31 (on-machine, #137).** P0–P1 evidence, the scrubbed ssh capture and
   > the doctor profile are in the unified spec §`minitop` survey and `profiles.yaml`. Two
   > surprises: the `mactop` name is `scutil HostName` alone (ComputerName/LocalHostName are
   > factory defaults), and the asdf → mise migration **already ran** there on 2026-06-01, so
   > step 4's `version_manager` correction is not needed on the mini. `make` was broken on the
   > mini at survey time (Xcode 26.6 loader, #138) — since **diagnosed and repaired** the same day
   > (stale `XcodeSystemResources` receipt from the in-place 16.2 → 26.6 upgrade; PR #139), so
   > nothing here is blocked.
3. **Upgrade chezmoi v2.31.1 → v2.72.0** using F2's verified recipe (hash the old binary
   into a backup first).
4. Only then regenerate the config (Task 4 pattern below, with `Computer name=minitop` /
   `Host name=minitop` and `--data=false` because the identity keys are present-but-wrong
   there too).

---

## Task Description

This is the **personal-machine half** of a two-machine analysis. Its sibling,
`specs/work-dotfiles-gap-analysis.md` (PR #114), was produced on the work machine
`adobetop`. Both then feed `specs/unified-dotfiles-gap-analysis.md`, which is the
document that decides what actually gets built.

**Nothing is implemented here.** This analysis deliberately ships a spec and nothing
else — no template edits, no new shell modules, no `chezmoi apply`. Every remediation
below is a *proposal* for the unified plan to accept, reject or merge with the work
machine's equivalent.

Every value in this document was **rediscovered on this machine**. Where a work-machine
finding did *not* reproduce here, that is stated explicitly rather than silently omitted —
the divergences are the most valuable output of a two-machine study.

## Objective

Produce a complete, reversible inventory of everything `chezmoi apply` would **add,
change, or destroy** on `Mac.scarlettlab.home` when moving from the current state to
`origin/main` with `version_manager=mise` — so the update can later be performed with
zero unintentional loss, and so every deviation has a documented restore path.

---

## Problem Statement

`chezmoi apply` is a **destructive, one-way** operation with respect to local edits.
chezmoi's model is that the source repo is the single source of truth; any change made
directly to a target file (`~/.zshrc`, `~/.vimrc`, …) is **overwritten without prompting**.

Three classes of local state are at risk on this machine:

| Class | Example | Why it's fragile |
|---|---|---|
| Third-party installer injections | `deno`, `Antigravity CLI`, `libpcap` blocks in `~/.zshrc`, `~/.zprofile`, `~/.bashrc`, `~/.profile` | Written by other tools; the user never "chose" them, so they are easy to forget |
| Symlinks into externally-managed repos | `~/.vimrc` → `.vim/.vimrc` (a `gpakosz/.vim` clone) | chezmoi replaces the *symlink* with a regular file; the real config survives on disk but stops being loaded |
| Config-key drift | `~/.config/chezmoi/chezmoi.yaml` predates `main`'s `fzf_tab` key | A missing key is silent until a template dereferences it unguarded |

Unlike the work machine, **the chezmoi source repo itself is not a risk here** — see
Finding 1.

## Solution Approach

Measure the gap **against the correct baseline** and make every deviation reversible
before mutating anything:

1. **Back up first, measure second.** A snapshot of every chezmoi-managed target was
   taken *before* any chezmoi subcommand ran — including read-only ones.
2. **Fix the tooling before trusting its output.** chezmoi `2.31.1` (Mar 2023) was
   upgraded to `2.72.0` (Finding 2).
3. **Compare against `origin/main`.** `git fetch` first; the working tree was verified to
   be exactly `origin/main` before measuring.
4. **Use a throwaway config** so measurement could not mutate `~/.config/chezmoi/chezmoi.yaml`.
   Verified by hash before and after (unchanged: `02f2fbca888bc79f…`).
5. **Use git's own parser for semantic diffs.** For `~/.gitconfig` a textual diff showed
   360 changed lines, almost all cosmetic. `git config --list` set-difference reduced this
   to **2 real losses and 11 real gains**.
6. **Measure both scenarios.** Status/diff were captured under the *current* config
   (asdf, all-false) **and** under the *target* config (mise, corrected flags), so the
   spec reports the gap that will actually be crossed.

---

## Relevant Files

### Analysis inputs (read)

- `home/.chezmoi.yaml.tmpl` — data schema. **L35–L102 wrap every `promptBool` in
  `if $interactive`**; this is the precise mechanism behind Finding 3.
  `version_manager` (L104) and `fzf_tab` (L116) sit deliberately *outside* it.
- `home/dot_zshrc.tmpl` — emits `ZSH_DOTFILES_VERSION_MANAGER` (L10/L34) and the dynamic
  `eval "$(sheldon source)"` block; also puts `$HOME/.local/bin` on PATH (L15/L39).
- `home/dot_gitconfig` — a plain (non-template) file on `main`. Sets
  `hub.host = git.corp.adobe.com` **unconditionally** at L8.
- `home/dot_vimrc` — 93-line regular file that would replace this machine's symlink.
- `home/.chezmoiexternal.yaml` — already clones `gpakosz`'s *other* project
  (`.tmux` → `dev/bossjones/oh-my-tmux`) as `type: git-repo`. The precedent for Finding 4's fix.
- `home/dot_sheldon/plugins.toml.tmpl` — conditionally emits `[plugins.asdf]`; defines the
  glob module loader (`**/env.zsh` L37, `**/path.zsh` L41, `**/{keybinding,completion}.zsh` L57).
  `myFzfTabRev` is referenced at L135 **inside** the `if $fzfTab` guard.
- `home/shell/deno/env.zsh` — already existence-gated; makes part of Finding 7 a no-op.
- `home/shell/customs/aliases.zsh` — `ulimit -n 65536` at L2052 is inside a heredoc at
  brace-depth 1, i.e. **not** applied at shell startup (Finding 10).
- `home/.chezmoiscripts/run_onchange_after_50-mise-install-tools.sh.tmpl` — authoritative
  list of the **17** tools mise installs.
- `home/.chezmoiscripts/run_once_before_01-mise-backup-tool-versions.sh.tmpl` — the
  self-healing `~/.tool-versions` backup.

### Proposed files (NOT created — for the unified plan to decide)

- `home/shell/libpcap/path.zsh` — **proposed**; the only genuinely-uncovered injection (Finding 7).
- `home/symlink_dot_vimrc` + a `.vim` entry in `home/.chezmoiexternal.yaml` +
  `home/dot_vimrc.local` — **decided** (Finding 4); together these replace `home/dot_vimrc`,
  which is deleted.

### Backup artifacts (restore sources)

All under `~/.backup/dotfiles/20260815-213326/`:

| Artifact | Contents |
|---|---|
| `dotfiles-20260815-213326.tar.gz` | 144 entries; sha256 in the `.sha256` sidecar — **verified `OK`** |
| `phaseA-20260815-213326.tar.gz` | 91 entries; the pre-chezmoi snapshot (see Task 1 note) |
| `files/` | Uncompressed per-file copies for direct `diff` |
| `chezmoi-preupgrade.bin` | The previous chezmoi binary (`v2.31.1`, sha `a226bf6e…`) |
| `chezmoi-status-vs-main-asis.txt` | 37-line status under the *current* config |
| `chezmoi-status-vs-main-mise.txt` | 40-line status under the *target* config |
| `chezmoi-diff-vs-main-asis.diff` / `…-mise.diff` | 6254- / 6283-line full diffs |
| `gitconfig-LOST.txt` / `gitconfig-GAINED.txt` | Semantic set-difference (Task 6 method) |
| `mise-orphaned-tools.txt` / `mise-version-deltas.txt` | Finding 11 evidence |
| `unmanaged-but-referenced/` | `vim-dot-vimrc` (24 K), `vim-dot-vimrc.local`, `deno-env`, `tool-versions`, `tmux.conf.local` |
| `behaviour-baseline.txt` | Pre-change behavioural assertions (Task 2) |
| `managed-paths.txt`, `managed-files.txt`, `managed-dirs.txt`, `managed-absent.txt` | Manifests |

---

## Findings

### Finding 1 — 🟢 The source repo was clean; the work machine's worst risks do not reproduce

`~/.local/share/chezmoi` was on `main`, **exactly equal to `origin/main`** (`git rev-list
--left-right --count HEAD...origin/main` → `0  0`), with only an untracked `.boss-skills/`
directory. Consequently:

- **No stale-branch artifact.** Work Finding 6 (23 drifted files that were really 13) has
  no analogue; the first measurement here was already against the correct baseline.
- **No merge resurrection.** `git diff --diff-filter=A --name-only origin/main HEAD`
  returned **empty**, so work Finding 8 (34 resurrected files breaking the Copilot CLI)
  cannot occur.
- **No `hack/doctor` divergence** (work Finding 12) and no superseded commits to preserve.

> This is the single biggest structural difference between the two machines, and it means
> the personal machine's risk is concentrated entirely in **live rendered dotfiles**, not
> in the source repo.

### Finding 2 — 🔴 chezmoi binary was 3+ years stale (RESOLVED)

`~/.bin/chezmoi` was `v2.31.1` (built 2023-03-02) — **byte-identical staleness to the work
machine**. Upgraded to `v2.72.0` (2026-08-02).

`~/.bin/chezmoi` is **not** itself chezmoi-managed (verified against `managed-paths.txt`),
so replacing it is safe. The old binary was hash-verified into the backup *before*
overwrite, and the new tarball's checksum was verified against the upstream
`chezmoi_2.72.0_checksums.txt`.

**Divergence from the work machine:** there, `2.31.1` was *completely non-functional*
(work Finding 1). Here it still ran — it only warned `config file template has changed`.
The reason is Finding 12: this machine's config already carries `version_manager`, and the
one key it *is* missing (`fzf_tab`) happens to be dereferenced only behind guards.

- **Restore:** `cp ~/.backup/dotfiles/20260815-213326/chezmoi-preupgrade.bin ~/.bin/chezmoi`

### Finding 3 — 🔴 Every feature flag is `false`, contradicting what is installed

`~/.config/chezmoi/chezmoi.yaml` currently declares:

```yaml
ruby: false      pyenv: false     nodejs: false    k8s: false
cuda: false      opencv: false    fnm: false
```

Yet all of these are demonstrably present:

| Flag | Evidence on disk |
|---|---|
| `pyenv` | `~/.pyenv` exists; `python3` → `~/.pyenv/shims/python3` |
| `nodejs` / `fnm` | `fnm` at `/opt/homebrew/bin/fnm`; `node` via `~/.local/state/fnm_multishells/…` |
| `k8s` | `kubectl`, `helm`, `k9s` all present (asdf shims); `~/.kube` exists |
| `ruby` | `ruby` present (asdf shim) |

**Root cause:** `home/.chezmoi.yaml.tmpl` wraps every `promptBool` inside
`{{- if $interactive -}}` (L35–L102). In a **non-TTY** run that whole block is skipped and
each boolean silently keeps its `false` default (L6–L18). This is exactly the trap the
work-machine spec warned about — and on this machine it **already fired**, at some past
non-interactive `chezmoi init`.

`cuda: false` and `opencv: false` are **correct** and should stay: this is an arm64 Mac,
`cv2` is not importable and there is no Homebrew `opencv`. (Work Finding 13 flagged
`cuda: true` there as meaningless; here the value is already right.)

**Agreed target for this machine** (decided 2026-08-15):

```yaml
ruby: true   pyenv: true   nodejs: true   k8s: true   fnm: true
cuda: false  opencv: false
```

> **Consequence:** the corrective `chezmoi init` **must be run in a real TTY**, or it will
> reproduce the identical all-false result. Verify with `chezmoi data`, never by exit code.

- **Restore:** `cp ~/.backup/dotfiles/20260815-213326/files/.config/chezmoi/chezmoi.yaml ~/.config/chezmoi/chezmoi.yaml`

### Finding 4 — 🔴 `~/.vimrc` is a symlink into a `gpakosz/.vim` clone; apply orphans 764 lines

```
~/.vimrc -> .vim/.vimrc        (symlink, mode 120755)
~/.vim/.vimrc                  764 lines, 24,461 bytes
~/.vim/                        a git clone of https://github.com/gpakosz/.vim.git
                               branch `vanilla`, HEAD d801d51, working tree CLEAN
```

`main` ships `home/dot_vimrc` as a **93-line regular file**. `chezmoi apply` therefore
deletes the symlink (`deleted file mode 120755`) and writes a regular file in its place.

**Impact:** `~/.vim/.vimrc` is *not deleted* — it stays on disk — but nothing loads it any
more, so 764 lines of working vim configuration silently stop applying. The file is also
**not chezmoi-managed**, so chezmoi will never restore it.

This is a *third-party-managed* setup, not a hand-rolled one: upstream's documented install
is `git clone … ~/.vim && ln -s ~/.vim/.vimrc ~/.vimrc`. `~/.vim/.vimrc.local` (179 B) is
upstream's user-override hook, and it is **tracked upstream** and currently unmodified.

**The repo already has the idiom to express this properly.** `home/.chezmoiexternal.yaml`
clones gpakosz's *other* project the same way:

```yaml
dev/bossjones/oh-my-tmux:
  type: git-repo
  url: https://github.com/bossjones/.tmux.git
```

…and `~/.tmux.conf` is a symlink into that clone — but a **manually created, unmanaged**
one. So the repo already has this exact gap for tmux; vim just makes it visible.

**Proposed fix (NOT implemented — for the unified plan).** Upstream's README documents the
install as:

```sh
cd && rm -rf .vim && git clone https://github.com/gpakosz/.vim.git && ln -s .vim/.vimrc
```

Each step has an exact chezmoi equivalent:

| README step | chezmoi equivalent |
|---|---|
| `git clone …/.vim.git` | a `type: git-repo` entry for `.vim` in `home/.chezmoiexternal.yaml` |
| `ln -s .vim/.vimrc` | `home/symlink_dot_vimrc` containing the single line `.vim/.vimrc` |
| `rm -rf .vim` | **not needed** — chezmoi runs `git clone` when the target is absent and `git pull` when it exists |
| *(implicit)* | `git rm home/dot_vimrc` — **mandatory**, see below |

```yaml
# home/.chezmoiexternal.yaml
.vim:
  type: git-repo
  url: https://github.com/gpakosz/.vim.git
```

```
# home/symlink_dot_vimrc   (no trailing newline needed; chezmoi strips one)
.vim/.vimrc
```

chezmoi's `symlink_` attribute creates a symlink whose *target* is the file's contents. The
relative path `.vim/.vimrc` reproduces upstream's relative `ln -s` exactly.

**Verified end-to-end** during analysis against an isolated `--destination`, so `$HOME` was
never touched:

- `.vimrc -> .vim/.vimrc`, resolving to the full **764 lines**
- the created symlink's git blob hash is `e4eb84d4…` — **identical** to the live
  `~/.vimrc`, i.e. byte-for-byte reproduction of the current state
- the external cloned to branch `vanilla` at `d801d51`, matching the live clone
- a second `apply` produced no diff (**idempotent**)

> ⚠️ **`home/dot_vimrc` must be removed in the same change.** With both `dot_vimrc` and
> `symlink_dot_vimrc` present, chezmoi refuses to run at all:
> `chezmoi: .vimrc: inconsistent state (…/dot_vimrc, …/symlink_dot_vimrc)`, exit 1.
> Verified.

#### Decision (2026-08-15): adopt `gpakosz/.vim`, keep personal settings in `~/.vimrc.local`

`home/dot_vimrc` is **retired** in favour of upstream. Customisation goes in
`~/.vimrc.local`, which upstream's README documents as the supported override hook —
managed here as `home/dot_vimrc.local`.

`~/.vim/.vimrc` sources it **last**:

```vim
762: if filereadable(expand("~/.vimrc.local"))
763:   source ~/.vimrc.local
```

> ✅ **Correction to an earlier draft.** That draft warned that `.vimrc.local` is tracked
> upstream and would become a `git pull` conflict on every apply. **That was wrong, and the
> distinction matters:** the override vim actually loads is **`~/.vimrc.local`** — in
> `$HOME`, *outside* the external clone. The 179-byte `~/.vim/.vimrc.local` is merely
> upstream's shipped **example**; nothing ever sources it, and `~/.vimrc.local` does not
> currently exist on this machine. So the external stays pristine, `git pull` never
> conflicts, and there is no reason to avoid the `git-repo` type.

**What to carry over.** `main`'s `home/dot_vimrc` is 93 lines / 42 settings, and gpakosz's
764-line config already covers nearly all of them (`encoding`, `ruler`, `laststatus`,
`incsearch`, `ignorecase`, `smartcase`, `hlsearch`, `wildmenu`, `hidden`, `autoread`,
`number`, `cursorline`, `showcmd`, `title`, `showmatch`, `syntax`, `filetype`…). Only the
genuine deltas need migrating into `home/dot_vimrc.local` — the `Pmenu` highlight group, the
custom `statusline`, and preferences such as `nobackup` / `noswapfile` / `noundofile`,
`listchars=tab:>-` and `ambiwidth=double`.

**Full design verified end-to-end** against an isolated `--destination`:

| Assertion | Result |
|---|---|
| `~/.vimrc` → `.vim/.vimrc`, 764 lines | pass |
| vim sources `~/.vimrc` as script **1** and `~/.vimrc.local` as script **12** (last → wins) | pass |
| upstream settings apply: `ignorecase=1`, `hlsearch=1`, `encoding=utf-8` | pass |
| overrides win: `colorcolumn=81`, `backup=0`, `swapfile=0`, `listchars=tab:>-` | pass |
| second `apply` is a no-op | pass |

> ⚠️ **Remaining caveat.** `git-repo` externals do not support `refreshPeriod`, so chezmoi
> runs `git pull` on **every apply**. That is now harmless (nothing local lives in the
> clone), but it does mean an apply needs network access, and upstream changes arrive
> unpinned. Pin with `clone.args: ["--branch", "<tag>"]` if that is not wanted.

> **Note on `.pathogen_disabled`.** The README's plugin-disabling hook applies to the
> **`heavenly`** branch only. This machine is on **`vanilla`** (the default branch), which
> ships no plugins, so it is not applicable unless the branch changes.

> ✅ **No branch pin is required.** An earlier draft of this finding claimed the external
> had to pin `vanilla` via `clone.args`. That was wrong: `vanilla` **is** gpakosz/.vim's
> default branch (`gh api repos/gpakosz/.vim --jq .default_branch`), so a plain clone lands
> on it — as the end-to-end test confirmed.

- **Restore:** `~/.backup/dotfiles/20260815-213326/unmanaged-but-referenced/vim-dot-vimrc`
  (and `vim-dot-vimrc.local`); re-create with `ln -sfn .vim/.vimrc ~/.vimrc`

### Finding 5 — 🔴 asdf → mise: 13 tools orphaned, 7 version bumps

Current state: **asdf `v0.11.2`**, **30** tools pinned in `~/.tool-versions`.

**mise is already installed** (`2026.5.1`, Homebrew) — but it is **inert**: there is no
`~/.config/mise/config.toml`, no `~/.local/share/mise/installs`, and `mise ls --current`
reports every entry as `(missing)` while *shadow-reading asdf's* `~/.tool-versions`.

> **Divergence from the work machine,** where mise was not installed at all. The switch is
> cheaper here, but the orphan list is larger (13 vs 11).

`main`'s mise lane installs **17** tools. **7 bumps, 10 unchanged, 0 new:**

| Tool | Now (asdf) | After (mise) |
|---|---|---|
| ruby | 3.2.1 | **4.0.1** |
| golang | 1.20.5 | 1.25.1 |
| neovim | 0.11.3 | `latest` |
| github-cli | `system` | 2.93.0 |
| shellcheck | 0.10.0 | 0.11.0 |
| shfmt | 3.7.0 | 3.13.1 |
| yq | 4.34.1 | 4.53.2 |

Unchanged: `tmux 3.5a`, `mkcert 1.4.4`, `helm 3.14.2`, `helmfile 0.162.0`,
`helm-docs 1.13.1`, `k9s 0.32.4`, `kubectx 0.9.5`, `opa 0.62.1`, `kubectl 1.26.12`,
`kubetail 1.6.20`.

**13 tools would be ORPHANED** (decision recorded 2026-08-15: accept as dropped — all are
years stale, and all stay reachable via `~/.tool-versions.asdf.bak` + `~/.asdf`):

```
ag 2.2.0        argocd 2.3.16   dive 0.10.0     fd 8.2.1
jsonnet 0.17.0  kompose 1.24.0  packer 1.7.4    poetry 1.1.8
rclone 1.65.0   rye 0.33.0      terraform 1.0.6 vault 1.11.3+ent
velero v1.10.2
```

> Two of these are *not* on the work machine's orphan list — **`rclone`** and **`rye`** —
> so the unified plan must union the two lists, not reuse either.

Mitigations already in `main`, verified present:
- `run_once_before_01-mise-backup-tool-versions.sh.tmpl` renames `~/.tool-versions` →
  `~/.tool-versions.asdf.bak` (never deletes, never clobbers an existing `.bak`). This is
  also what stops mise shadow-reading asdf's file.
- `mise settings set ruby.compile false` (L47) + `MISE_RUBY_COMPILE=0` — important, because
  compiling Ruby 4.0.1 from source on arm64 macOS is slow and failure-prone.
- `~/.asdf` is **left in place**; the switch is reversible by flipping the flag back.

Confirmed side-effect of the switch (rendered under both configs):

```toml
# ~/.sheldon/plugins.toml — present under asdf, absent under mise
-[plugins.asdf]
-local = "/opt/homebrew/opt/asdf/libexec"
```

(Note this machine pins `/opt/homebrew/opt/asdf/libexec`, *not* the work machine's
`asdf@0.11.2` path.)

### Finding 6 — 🟡 `~/.gitconfig` loses 2 settings and gains 11 — no identity risk

The textual diff is **360 lines** and is dominated by comment churn. Parsed with git itself:

**LOST**

```
core.editor=nano                # -> becomes vim
init.defaultbranch=main
```

**GAINED**

```
branch.sort=-committerdate   column.ui=auto            core.editor=vim
fetch.prunetags=true         ghq.root=~/code           push.autosetupremote=true
push.followtags=true         rebase.autosquash=true    rebase.autostash=true
rebase.updaterefs=true       tag.sort=version:refname
```

> **The work machine's single highest-consequence finding does not reproduce here.**
> This machine has **zero `includeIf` blocks** and **no `~/.gitconfig-*` sibling files**
> (`ls ~/.gitconfig*` returns only `~/.gitconfig`). There is no work identity to lose and
> nothing to route. Answering the question the work spec explicitly deferred to this
> analysis: **no, the personal machine has no `includeIf` blocks of its own.**

`init.defaultBranch = main` is wanted on **both** machines, so restoring it is an
unconditional change — identical to the work machine's conclusion, reached independently.

`core.editor`: `nano` here vs `main`'s `vim`. A personal preference, not a profile split.

**Note on `hub.host`.** `main`'s `home/dot_gitconfig` L8 sets
`hub.host = git.corp.adobe.com` **unconditionally**, so applying `main` would hand *this
personal machine* Adobe's internal GitHub Enterprise host. That is the pre-existing bug
the work spec identified — and this analysis **confirms it lands here**, which is the
strongest independent argument for the `profile` gate (Finding 13).

- **Restore:** `cp ~/.backup/dotfiles/20260815-213326/files/.gitconfig ~/.gitconfig`

### Finding 7 — 🟡 Installer injections span four files, but `main` already covers most of them

Injections were found in `~/.zshrc`, `~/.zprofile`, `~/.bashrc` and `~/.profile`.

> **Methodology note:** **none of them use `# >>> … <<<` sentinel pairs.** A grep for
> sentinel markers alone (the work machine's signature) returns *nothing* on this machine
> and would have missed every one of these. They had to be found by diffing the rendered
> target against the live file.

| Injection | Files | Verdict |
|---|---|---|
| `. "$HOME/.deno/env"` | `.zshrc`, `.bashrc`, `.profile` | **Already covered** — `home/shell/deno/env.zsh` exists on `main`, is `-d`-gated, and is globbed by sheldon. The live `.zshrc` predates that module. |
| `# Added by Antigravity CLI installer` → `PATH=$HOME/.local/bin` | `.zprofile`, `.bashrc`, `.profile` (active); `.zshrc` (commented out) | **Already covered** — `dot_zshrc.tmpl` L15/L39, `compat.sh.tmpl` L5/L36, `dot_bashrc.tmpl` L136 all add `~/.local/bin`. |
| `[ -f "$HOME/.rye/env" ] && . …` | `.zshrc`, `compat.sh`, `compat.bash` | **Dead** — `~/.rye` does not exist; the guard makes it a no-op. `main` removed rye deliberately. Drop. |
| `export PATH="/opt/homebrew/opt/libpcap/bin:$PATH"` | `.zshrc` | 🟡 **Genuinely uncovered** — appears nowhere in `home/`. The only real remediation needed. |

**Proposed fix (NOT implemented):** a single existence-gated module,
`home/shell/libpcap/path.zsh`, following the `home/shell/krew/env.zsh` idiom. sheldon
already globs `**/path.zsh` (`plugins.toml.tmpl` L41), so **no `plugins.toml` change is
needed**.

> The work machine's `completion.zsh`/`compdef` hazard **does not arise here** — the one
> uncovered injection is a PATH entry, which belongs in `path.zsh`. No completion file is
> proposed, so the "never `eval` a `#compdef` file before compinit" trap is not in play on
> this machine.

- **Restore:** `~/.backup/dotfiles/20260815-213326/files/{.zshrc,.zprofile,.bashrc,.profile}`

### Finding 8 — 🟡 `~/.zshrc` is a statically-baked plugin list; apply replaces it with the dynamic form

The live `~/.zshrc` (75 lines) contains a **baked-out** sheldon plugin list — 46 literal
`source`/`zsh-defer source` lines with absolute paths — including visible duplicates
(`config.zsh` twice, `customs/aliases.zsh` twice, `~/.fzf.zsh` twice).

`main` replaces all of it with:

```zsh
export ZSH_DOTFILES_VERSION_MANAGER="mise"
export ZSH_DOTFILES_FZF_TAB=false

if [[ -f "$HOME/.sheldon/plugins.toml" ]]; then
    export PATH="$HOME/.local/bin:$PATH"
    eval "$(sheldon source)"
fi
```

This is **desired**, and it is what fixes Finding 7's deno case for free. Note the
inversion from the work machine: there, a bake→dynamic reversion was a *stale-branch
artifact* (work Finding 6); **here the static bake is the genuine live state**, and moving
to the dynamic form is real progress.

### Finding 9 — 🟡 `~/.zprofile` replaces a frozen PATH with `path_helper`

The live `~/.zprofile` hardcodes one enormous `PATH=…; export PATH;` line that pins
**`/opt/homebrew/opt/asdf@0.11.2/libexec/bin`** and two stale
`fnm_multishells/<pid>_<timestamp>` directories. `main` replaces it with:

```sh
eval "$(/usr/bin/env PATH_HELPER_ROOT="/opt/homebrew" /usr/libexec/path_helper -s)"
```

Strictly an improvement — the baked PATH references a pinned asdf version being retired by
Finding 5 and per-process fnm dirs that no longer exist.

### Finding 10 — 🟡 `compat.sh` / `compat.bash` lose `ulimit -n 65536` (benign)

Both live files set `ulimit -n 65536`; `main` does not. The identical string exists at
`home/shell/customs/aliases.zsh:2052`, but verification showed it sits **inside a heredoc
at brace-depth 1**, so it is *not* applied at shell startup — the loss is real, not
covered.

It is nonetheless **benign**: measured `sh -c 'ulimit -n'` on this machine is **1048576**,
so the removed line would only ever have *lowered* the limit. Recorded for completeness;
no remediation proposed.

### Finding 11 — 🟢 `git remote` and `gh` are already consistent

```
origin  git@github.com:bossjones/zsh-dotfiles.git   (ssh)
gh      Logged in to github.com account bossjones — Git operations protocol: ssh — Active: true
```

**Work Finding 10 does not reproduce.** There, `origin` was HTTPS while `gh` was ssh, and
the active account was the Enterprise Managed User `malcolm_adobe`, so pushes failed
outright. Here the protocol matches and the active account **owns** the repo, so pushing
this branch and opening a PR works without changes.

### Finding 12 — 🟡 `fzf_tab` / `myFzfTabRev` are missing from the live config (latent)

`main`'s templates require two keys the live `~/.config/chezmoi/chezmoi.yaml` lacks:
`fzf_tab` and `myFzfTabRev`.

Both are currently harmless, and the reason is worth recording precisely:

- `dot_zshrc.tmpl` L10/L34 and `plugins.toml.tmpl` L3 all guard with
  `and (hasKey . "fzf_tab") .fzf_tab` — safe when absent.
- `myFzfTabRev` at `plugins.toml.tmpl` L135 is referenced **unconditionally**, but it sits
  *inside* the `{{ if $fzfTab }}` block, so it is never evaluated while `fzf_tab` is false.
  Confirmed by rendering: `chezmoi cat ~/.sheldon/plugins.toml` → **RENDER OK**.

**This is why chezmoi still ran here but died on the work machine.** It is also a live
tripwire: enabling `fzf_tab` *without* first regenerating the config would fail with
`map has no entry for key "myFzfTabRev"`. The corrective `chezmoi init` resolves it.

### Finding 13 — 🟡 The `profile` key does not exist on `main`; this machine still needs it

Verified: `profile` appears **nowhere** in `home/` on `origin/main`, and PR #114 changes
**exactly one file** (`specs/work-dotfiles-gap-analysis.md`, +60/−12). The work machine's
Task 7 is therefore **designed but unimplemented**.

Per the two-machine workflow, this machine needs the **same** template changes, not none of
them — it simply resolves to `personal` and renders the work block away:

| File | Change | Effect here |
|---|---|---|
| `home/.chezmoi.yaml.tmpl` | add `profile` key + prompt, outside `if $interactive` | emits `profile: "personal"` |
| `home/dot_gitconfig` → `.tmpl` | gate `hub.host` and the `includeIf` block on `profile=work` | **fixes Finding 6's `hub.host` leak** |
| `home/.chezmoiignore.tmpl` | ignore `.gitconfig-*` unless `profile=work` | 0 identity files managed |

Expected values on this machine once implemented:

```sh
chezmoi data | grep profile               # "personal"
chezmoi managed | grep -c gitconfig-      # 0
chezmoi cat ~/.gitconfig | grep -ci adobe # 0
```

> ⚠️ **`profile` is sticky.** Once written to `~/.config/chezmoi/chezmoi.yaml`, `hasKey`
> short-circuits the prompt and re-passing `--promptString profile=…` is a **no-op**. It
> must be correct on the first init — the same trap already documented for `fzf_tab` in
> `specs/fzf-tab.md` and for `version_manager`.

**Not implemented here by explicit decision:** the unified spec is the gate for any
building. This finding records the requirement and its verification, nothing more.

### Finding 14 — 🟢 The raw diff line-count massively overstates the risk

The full diff is **6,283 lines**, which reads alarmingly. Decomposed:

| Path | Lines | Nature |
|---|---|---|
| `.config/iterm2/com.googlecode.iterm2.plist` | 4,260 | **new file**, added not destroyed |
| `.gitconfig` | 270 | → 2 real losses (Finding 6) |
| `.bin/smartcrop` | 210 | **pure trailing-whitespace churn** |
| `.vimrc` | 95 | Finding 4 |
| `.zshrc` | 64 | Finding 8 |

Every `~/.bin/*` file is dated **`Aug 10 2025`** — the timestamp of the last `chezmoi
apply` — so they are *stale renders of managed files*, not hand-authored content. Of the
22 modified targets, only **11** carry real behavioural risk: `.zshrc`, `.zprofile`,
`.bashrc`, `.profile`, `.vimrc`, `compat.sh`, `compat.bash`, `.gitconfig`,
`.gitignore_global`, `.sheldon/plugins.toml`, `.config/sheldon/plugins.toml`.

> **Generalised lesson, matching the work machine's `~/.gitconfig` result:** never size
> this kind of migration by diff line-count. Classify per file, and use a semantic parser
> wherever one exists.

### Finding 15 — 🟡 `~/.gitignore_global` loses one line

```
-**/.claude/settings.local.json
```

**Identical to work Finding 5**, rediscovered independently — which makes it a
cross-machine issue and a clean candidate for an unconditional fix in the unified plan.
Low impact; `main`'s repo-level `.gitignore` already covers this path, so it only matters
for *other* repos.

### Finding 16 — 🟢 Pre-existing shell warning (baseline, not caused by the migration)

`zsh -i` already emits `(eval):1: can't change option: zle` **today**, before any change.
Captured in `behaviour-baseline.txt` so it is not misattributed to the migration during
post-apply verification.

---

## Work Already Completed

| Action | Detail | Reversible via |
|---|---|---|
| Backup created | `~/.backup/dotfiles/20260815-213326/`, 144 entries, sha256 **verified `OK`** | n/a |
| chezmoi upgraded | `v2.31.1` → `v2.72.0` | `cp $BK/chezmoi-preupgrade.bin ~/.bin/chezmoi` |
| Worktree created | `~/.local/share/chezmoi-gap-analysis` on `feat/personal-dotfiles-gap-analysis` | `git worktree remove ~/.local/share/chezmoi-gap-analysis` |

**Deliberately NOT done:** no `chezmoi apply`, no `chezmoi init`, **no modification to
`~/.config/chezmoi/chezmoi.yaml`** (hash verified unchanged before and after all
measurement: `02f2fbca888bc79f…`), and no source-tree edits. All measurement used
`--config=<throwaway> --source=<worktree>`.

---

## Step by Step Tasks

> **These are proposals for the unified plan.** Nothing below has been executed. The
> ordering is preserved so the unified spec can merge it against the work machine's list.

### 1. Verify the backup before touching anything

```sh
BK=~/.backup/dotfiles/20260815-213326
( cd "$BK" && shasum -a 256 -c dotfiles-20260815-213326.tar.gz.sha256 )
tar -tzf "$BK"/dotfiles-*.tar.gz | wc -l          # expect 144
test -f "$BK/files/.zshrc" && echo "zshrc backed up"
test -f "$BK/unmanaged-but-referenced/vim-dot-vimrc" && echo "vimrc backed up"
```

- **Do not proceed if the checksum fails.** Re-run the backup instead.

### 2. Re-confirm the behavioural baseline

`$BK/behaviour-baseline.txt` is the expected "before" state. Re-capture and diff it
immediately before any apply, so a stale baseline never silently passes.

### 3. Land Finding 4 (`~/.vimrc`) — **DECIDED 2026-08-15**

Adopt `gpakosz/.vim` as the source of truth and retire `home/dot_vimrc`. Four changes, all
verified end-to-end (Finding 4):

- [ ] Add the `.vim` `git-repo` external to `home/.chezmoiexternal.yaml`
- [ ] Add `home/symlink_dot_vimrc` containing `.vim/.vimrc`
- [ ] `git rm home/dot_vimrc` — **mandatory**; leaving both makes chezmoi refuse to run with
      `.vimrc: inconsistent state` (exit 1)
- [ ] Add `home/dot_vimrc.local` carrying only the genuine deltas from the retired
      `dot_vimrc` (Pmenu highlights, custom statusline, `nobackup`/`noswapfile`/`noundofile`,
      `listchars`, `ambiwidth`)

Options (b) `.chezmoiignore` and (c) accept main's vimrc were considered and **rejected** —
(b) keeps the setup unreproducible, (c) discards 764 lines of working configuration.

### 4. Regenerate the chezmoi config — **in a real TTY**

> **Corrected 2026-08-31.** The first draft of this command carried
> `Computer name=boss workstation` / `Host name=bossworkstation` — the stale values from
> the live config, contradicting this spec's own header. The targets are
> `supertop`/`supertop` (Q6 made these keys load-bearing: they feed the hostname setter
> script). **And `--promptString` alone cannot fix them**: both keys are *present* in the
> live config, so `hasKey` is true and every prompt — including `--promptString` — is
> short-circuited. The `--data=false` flag below (the template's own documented tip)
> ignores existing data so every prompt fires fresh; the alternative is hand-editing
> `~/.config/chezmoi/chezmoi.yaml` before a plain init. The same applies to
> `version_manager` (present as `asdf`, target `mise`).

Uses `--source=.` against the **existing working tree**, so it does not re-clone and local
commits are preserved:

```sh
cd ~/.local/share/chezmoi
chezmoi init --source=. --data=false --debug -v \
  --promptString "Name=Malcolm Jones" \
  --promptString "Email=bossjones@theblacktonystark.com" \
  --promptString "Computer name=supertop" \
  --promptString "Host name=supertop" \
  --promptString "version_manager=mise" \
  --promptBool   "ruby=true" \
  --promptBool   "pyenv=true" \
  --promptBool   "nodejs=true" \
  --promptBool   "k8s=true" \
  --promptBool   "cuda=false" \
  --promptBool   "fnm=true" \
  --promptBool   "opencv=false" \
  --promptBool   "fzf_tab=false"
```

- Add `--promptString "profile=personal"` **only once Finding 13 is implemented**; against
  today's `main` that key does not exist and the flag is inert.
- **Run this in a real TTY.** Every `promptBool` lives inside `if $interactive`; a non-TTY
  run silently produces all-`false` — which is precisely how the current config broke
  (Finding 3). Verify immediately:

  ```sh
  chezmoi data | grep -E '"(version_manager|fzf_tab|ruby|pyenv|nodejs|k8s|cuda|opencv|fnm)"'
  ```

- **Do not run `chezmoi apply` yet.** Keeping `init` and `apply` separate preserves the
  review gate; the repo's own Tutorial 04 recommends this ordering.

### 5. Land the source changes chosen by the unified plan

Candidates from this analysis: `home/shell/libpcap/path.zsh` (Finding 7), the `.vimrc`
decision (Task 3), `**/.claude/settings.local.json` appended to `home/dot_gitignore_global`
(Finding 15), `init.defaultBranch = main` (Finding 6), and the `profile` key (Finding 13).

### 6. Review and apply

```sh
cd ~/.local/share/chezmoi
chezmoi diff  --source=.        # review
chezmoi apply -v --source=.     # only after the diff looks right
```

### 7. Verify

Run every command in **Validation Commands** below, then diff against
`behaviour-baseline.txt`.

---

## Testing Strategy

This is a configuration change, so "tests" are **behavioural assertions** compared against
artifacts captured before any change.

**Pre-flight:** backup checksum verifies; `behaviour-baseline.txt` captured; the
`--diff-filter=A` resurrection guard is empty (already confirmed, Finding 1).

**Post-apply assertions:**

1. **`~/.vimrc` resolves to the decision made in Task 3** — assert on `readlink`/`wc -l`,
   not on file presence.
2. **Flags are correct** — `chezmoi data` shows five `true` and `cuda`/`opencv` `false`.
   This is the direct regression test for Finding 3.
3. **Shell starts cleanly** — `zsh -i -c exit` exits 0, and its stderr matches the
   *baseline* set (Finding 16), not an empty set.
4. **libpcap PATH survives** (if Finding 7's module lands).
5. **Version manager switched** — `mise --version` works, `~/.tool-versions.asdf.bak`
   exists, `~/.asdf` untouched.
6. **No unintended deletions** — diff the post-apply tree against `$BK/files`.

**Assertions already proven during this analysis (read-only):**

| # | Assertion | Result |
|---|---|---|
| 1 | Working tree is exactly `origin/main` (`0  0`) | pass |
| 2 | Resurrection guard `--diff-filter=A` is empty | pass |
| 3 | Backup tarball sha256 verifies (144 entries) | pass |
| 4 | `chezmoi managed` dir-vs-file split prevents the 16 GB trap (13 dirs skipped, incl. `dev`) | pass |
| 5 | Real `~/.config/chezmoi/chezmoi.yaml` unchanged across all measurement | pass |
| 6 | `~/.gitconfig` semantic diff = 2 lost / 11 gained (vs 360 textual lines) | pass |
| 7 | Zero `includeIf` blocks and zero `~/.gitconfig-*` files | pass |
| 8 | `plugins.toml` renders OK despite missing `myFzfTabRev` | pass |
| 9 | Target file set identical under asdf and mise configs (only scripts differ) | pass |
| 10 | `ZSH_DOTFILES_VERSION_MANAGER="mise"` renders under the target config | pass |
| 11 | `[plugins.asdf]` present under asdf, absent under mise | pass |
| 12 | `~/.vim` is a clean `gpakosz/.vim` clone on branch `vanilla` | pass |
| 13 | `aliases.zsh:2052` `ulimit` is inside a heredoc, not top-level | pass |
| 14 | `gh` active account owns the repo; remote protocol matches | pass |

**Edge cases to watch:**
- Ruby 4.0.1 is the most likely install failure; confirm `mise settings get ruby.compile`
  is `false`.
- A **non-TTY** Task 4 silently produces all-`false` booleans — verify `chezmoi data`
  rather than trusting the exit code.
- `profile` and `version_manager` are both **sticky** after the first init.
- If the `.vim` external lands, its `git pull` runs on every apply and `.vimrc.local` is
  upstream-tracked — a future local edit there becomes a merge conflict.

---

## Acceptance Criteria

- [ ] Backup verified by checksum and restorable.
- [ ] `chezmoi status` and `chezmoi diff` run without template errors.
- [ ] `chezmoi data` reports `version_manager: mise`, `fzf_tab: false`,
      `ruby/pyenv/nodejs/k8s/fnm` **true**, `cuda/opencv` **false**.
- [ ] `~/.vimrc` is a symlink to `.vim/.vimrc` resolving to 764 lines; `home/dot_vimrc` is
      deleted; `~/.vimrc.local` renders and is sourced **after** upstream (Finding 4).
- [ ] `init.defaultBranch = main` present in `~/.gitconfig`.
- [ ] `**/.claude/settings.local.json` present in `~/.gitignore_global`.
- [ ] **(Only once Finding 13 lands)** no `adobe` reference in the rendered `~/.gitconfig`
      (`chezmoi cat ~/.gitconfig | grep -ci adobe` → `0`). Against today's `main` this
      correctly returns **1** (`hub.host`, `dot_gitconfig:8`) — verified during analysis.
- [ ] `mise` active; `~/.tool-versions.asdf.bak` created; `~/.asdf` untouched.
- [ ] A new `zsh -i` session starts with no *new* errors beyond the recorded baseline.
- [ ] Every deviation has a documented restore path in this file.

---

## Validation Commands

```sh
BK=~/.backup/dotfiles/20260815-213326

# --- 0. Backup integrity -----------------------------------------------------
( cd "$BK" && shasum -a 256 -c dotfiles-20260815-213326.tar.gz.sha256 )

# --- 1. chezmoi is healthy ---------------------------------------------------
chezmoi --version                                   # expect v2.72.0
chezmoi doctor
cd ~/.local/share/chezmoi && chezmoi status --source=. && chezmoi diff --source=.

# --- 2. Config data is correct (catches the non-TTY all-false trap) ----------
chezmoi data | grep -E '"(version_manager|fzf_tab|ruby|pyenv|nodejs|k8s|cuda|opencv|fnm)"'
# ruby/pyenv/nodejs/k8s/fnm MUST be true; cuda/opencv false; version_manager "mise"

# --- 3. gitconfig ------------------------------------------------------------
git config --file ~/.gitconfig --get init.defaultbranch     # expect: main
git config --file ~/.gitconfig --list | grep -c includeif   # expect: 0
chezmoi cat ~/.gitconfig | grep -ci adobe                   # expect: 0
# Re-run the semantic comparison used in this analysis:
git config --file ~/.gitconfig --list | sort > /tmp/live.keys
chezmoi cat ~/.gitconfig | git config --file /dev/stdin --list | sort > /tmp/target.keys
comm -23 /tmp/live.keys /tmp/target.keys    # LOST   -- expect empty after apply
comm -13 /tmp/live.keys /tmp/target.keys    # GAINED -- expect empty after apply

# --- 4. vimrc (Finding 4) ----------------------------------------------------
ls -la ~/.vimrc; readlink ~/.vimrc || echo "(regular file)"
wc -l ~/.vim/.vimrc                                  # expect 764 -- must still exist
# If option (a)/(b) was chosen, ~/.vimrc must still resolve to 764 lines:
wc -l "$(readlink -f ~/.vimrc 2>/dev/null || echo ~/.vimrc)"

# --- 5. gitignore_global -----------------------------------------------------
grep -q '\*\*/.claude/settings.local.json' ~/.gitignore_global && echo "PASS: gitignore line"

# --- 6. Shell health ---------------------------------------------------------
zsh -n ~/.zshrc && echo "PASS: zshrc syntax"
zsh -i -c 'exit' && echo "PASS: interactive shell starts clean"
zsh -i -c 'echo $ZSH_DOTFILES_VERSION_MANAGER'       # expect: mise
# Compare stderr against the RECORDED baseline, not against empty (Finding 16).
# Any line printed here is a NEW warning introduced by the migration:
zsh -i -c 'true' 2>&1 | sort -u > /tmp/zsh-stderr-after.txt
comm -13 <(grep -E '^\(|^Using ' "$BK/behaviour-baseline.txt" | sort -u) /tmp/zsh-stderr-after.txt
# libpcap (only if Finding 7's module landed)
zsh -i -c 'case ":$PATH:" in *"libpcap/bin"*) echo "PASS: libpcap PATH";; *) echo "n/a";; esac'

# --- 7. Version manager migration -------------------------------------------
mise --version
mise ls --current
test -f ~/.tool-versions.asdf.bak && echo "PASS: asdf tool-versions backed up"
test -d ~/.asdf && echo "PASS: ~/.asdf left intact (rollback still possible)"
# The 13 orphaned tools are expected to be absent -- this is intentional (Finding 5):
for t in ag argocd dive fd jsonnet kompose packer poetry rclone rye terraform vault velero; do
  printf '%-10s %s\n' "$t" "$(command -v "$t" || echo 'ORPHANED (expected)')"
done

# --- 8. No unintended deletions ---------------------------------------------
# "$BK/files" is the first operand, so a file deleted from $HOME since the backup shows up
# as "Only in $BK/files: ...". Filter out only the noisy ~-only entries.
diff -rq "$BK/files" ~ 2>/dev/null | grep -v "^Only in $HOME:" | head -40
```

### Rollback

```sh
BK=~/.backup/dotfiles/20260815-213326

# Restore a single file
cp "$BK/files/.zshrc" ~/.zshrc

# Restore everything
RESTORE_DIR=$(mktemp -d)
tar -xzf "$BK"/dotfiles-*.tar.gz -C "$RESTORE_DIR" && cp -a "$RESTORE_DIR"/files/. ~/

# Restore the vim symlink setup (Finding 4)
cp "$BK/unmanaged-but-referenced/vim-dot-vimrc"       ~/.vim/.vimrc
cp "$BK/unmanaged-but-referenced/vim-dot-vimrc.local" ~/.vim/.vimrc.local
ln -sfn .vim/.vimrc ~/.vimrc

# Roll back the version manager (asdf data was never deleted).
# `version_manager` is sticky (hasKey short-circuits --promptString) -- edit the config
# directly, then re-render and apply before restoring .tool-versions:
sed -i '' 's/^\(\s*version_manager:\).*/\1 "asdf"/' ~/.config/chezmoi/chezmoi.yaml
cd ~/.local/share/chezmoi && chezmoi init --source=. && chezmoi apply --source=.
mv ~/.tool-versions.asdf.bak ~/.tool-versions

# Roll back the chezmoi binary
cp "$BK/chezmoi-preupgrade.bin" ~/.bin/chezmoi

# Remove the analysis worktree
git -C ~/.local/share/chezmoi worktree remove ~/.local/share/chezmoi-gap-analysis
```

---

## Personal vs Work: divergence summary

The point of running this twice. **Do not assume the work machine's conclusions.**

| Topic | Work (`adobetop`) | Personal (`Mac.scarlettlab.home`) |
|---|---|---|
| Source repo state | stale branch, ~30 behind, 10 unmerged | **clean, `== origin/main`** |
| Merge resurrection | 34 files (broke Copilot CLI) | **none** |
| chezmoi `2.31.1` | totally non-functional | **ran, warning only** |
| Feature flags | all `true` | **all `false` — the non-TTY trap already fired** |
| `includeIf` identity routing | 5 blocks, 3 identity files — highest risk | **none at all** |
| `hub.host` Adobe leak | source of the bug | **confirmed it lands here** |
| Third-party injections | 2, with `# >>> <<<` sentinels | **4 files, no sentinels; only libpcap uncovered** |
| Symlinked vimrc | not reported | 🔴 **`gpakosz/.vim`, 764 lines orphaned** |
| mise | not installed | **installed but inert, shadow-reading `~/.tool-versions`** |
| Orphaned tools | 11 | **13** (adds `rclone`, `rye`) |
| `git remote` / `gh` | HTTPS vs ssh; EMU account — pushes failed | **consistent; pushes work** |
| `.gitignore_global` line | lost | **lost — same, independently confirmed** |

---

## Notes

- **Two-machine workflow.** This is the personal-machine analysis. It and
  `specs/work-dotfiles-gap-analysis.md` (PR #114) both feed
  `specs/unified-dotfiles-gap-analysis.md`. **No implementation happens until that unified
  spec exists** — per the decision recorded on PR #114.
- **Scope of this PR:** the spec document only. No template changes, no shell modules, no
  `chezmoi apply`.
- **The 16 GB backup trap was real here too.** `chezmoi managed` listed **13 directories**
  among 136 entries, including `dev` and `dev/bossjones`. Filtering to regular files and
  symlinks kept the backup at **52 MB / 144 entries**.
- **The sheldon module loader hardcodes `~/.local/share/chezmoi`**
  (`plugins.toml.tmpl` L36–L57), so the *live shell* always sources from the main checkout,
  never from a worktree — the analysis worktree could not have affected the running shell.
  Worth parameterising; a candidate for the unified plan.
- **No new libraries required.** Only `chezmoi`, `git`, `gh` and `mise`.
- **Open questions for the unified plan:**
  - Finding 4 is **decided** (adopt `gpakosz/.vim`); what remains is whether `~/.tmux.conf`
    should get the same treatment — it has the identical unmanaged-symlink shape today, and
    `~/.tmux.conf.local` (19.1K) is the analogous override hook.
  - Finding 13 — implement `profile`, and confirm it renders away cleanly here.
  - Finding 5 — union the two machines' orphan lists (13 vs 11) before dropping anything.
  - Whether `core.editor` should be `vim` (main) or `nano` (this machine's current value).
