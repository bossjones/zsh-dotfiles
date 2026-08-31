# Spec: `hack/doctor` — a YAML-driven, per-machine migration doctor

> **Status:** design agreed 2026-08-31, not yet implemented
> **Companion to:** [`specs/unified-dotfiles-gap-analysis.md`](./unified-dotfiles-gap-analysis.md)
> **Tracking:** epic #116
> **Baseline:** `origin/main` @ `41d8a98`, branch `feat/unified-dotfiles-gap-analysis`

---

## Task Description

`specs/unified-dotfiles-gap-analysis.md` produced an ordered migration plan and a
**Testing Strategy** section full of behavioural assertions — resolved git identity in six probe
directories, `chezmoi data` values, `hub.host` absence, shell-startup baselines, symlink shapes.
Today every one of those is a shell snippet embedded in prose, executed by hand, on a fleet the
spec models as two machines.

The fleet is **three**, and the assertions differ per machine. Prose does not scale to that.

This document specifies a small program that makes those assertions **executable, declarative,
per-machine, and traceable back to the finding that motivated them**.

## Objective

A single self-contained script, driven by a single committed YAML file, that answers three
questions on any machine in the fleet:

1. **Which machine am I?** — and is that answer unambiguous?
2. **Is this machine safe to migrate?** (`--phase pre`)
3. **Did the migration land correctly?** (`--phase post`)

with a fourth as the everyday case: **is this machine still healthy?** (`--phase always`).

## Non-goals

- **It does not remediate.** Every check may carry a `fix:` string; it is *printed, never
  executed*. The operations in question (`chezmoi apply`, `scutil --set`, git identity routing,
  the asdf→mise migration) are the ones the unified spec marks `risk:high` and deliberately gates
  behind manual `chezmoi diff` review. An auto-fixer would be a second, untested path through
  exactly those operations.
- **It does not replace `check_dev_environment.py`.** See [Relationship to the existing
  script](#relationship-to-the-existing-script).
- **It does not run `chezmoi init` or `chezmoi apply`.** It only observes.
- **It is not a general-purpose config-management tool.** It asserts against one fleet.

---

## The fleet

| Name | Role | User | Arch | Identity status |
|---|---|---|---|---|
| `adobetop` | work | `malcolm` | arm64 | **Confirmed** — macOS 15.7.9 (24G830) |
| `supertop` | personal laptop | `bossjones` | arm64 (assumed) | **Hypothesis** — in `~/.ssh/config`, never surveyed |
| `minitop` | personal | `bossjones` | arm64 (assumed) | **Hypothesis** — see below |

### The `minitop` hypothesis

`~/.ssh/config` contains hosts `adobetop`, `supertop` and **`mac-mini`**. There is no host named
`minitop`. The unified spec records the personal machine as `Mac.scarlettlab.home`, with
`.chezmoi.hostname` resolving to the bare `"Mac"`.

A Mac mini left at the factory-default `ComputerName` of `Mac` produces exactly that. So the
working hypothesis is:

> **`minitop` is the informal name for the `mac-mini` host, which is the machine the unified
> spec calls `Mac.scarlettlab.home`.**

This is **not confirmed** and must not be treated as fact. Confirmation is P0 of issue
[`prompt: survey minitop`](#the-prompt-issues). Until then `hosts.minitop` ships with its
identity block commented `# HYPOTHESIS`.

### macOS has three hostnames, and one of them is normally unset

Measured on `adobetop` on 2026-08-31:

```
scutil --get ComputerName    adobetop
scutil --get LocalHostName   adobetop
scutil --get HostName        HostName: not set     ← macOS default
hostname                     adobetop.local        (LocalHostName + .local fallback)
```

`HostName` is unset on a machine that is working correctly. Nothing sets it unless
`sudo scutil --set HostName` is run explicitly. It follows that `Mac.scarlettlab.home` on the
mini was never `scutil HostName` either — it is DHCP/DNS-derived.

**Consequence for this design:** asserting all three names at `error` severity would flag a
healthy machine. Therefore:

| Name | Severity | Rationale |
|---|---|---|
| `ComputerName` | `error` | User-facing, user-controlled, what you actually renamed |
| `LocalHostName` | `error` | What `hostname` derives from, what chezmoi's `.chezmoi.hostname` sees |
| `HostName` | **`warn`**, `allow_unset: true` | Unset is the healthy default; flag only if set *wrongly* |

---

## Architecture

```
hack/doctor/
  doctor.py                     # uv PEP-723 self-contained script (new)
  profiles.yaml                 # the one committed config (new)
  tests/test_doctor.py          # TDD suite (new)
  check_dev_environment.py      # existing, untouched
  Makefile, README.md, ...      # existing, untouched

hack/schemas/
  doctor-profiles.schema.json   # JSON Schema for profiles.yaml (new)
```

Four moving parts:

1. **`profiles.yaml`** — declarative. `common:` checks apply fleet-wide; `hosts.<name>:` add
   machine-specific ones. Adding a check *instance* is a YAML edit and nothing else.
2. **A typed check registry** in `doctor.py` — one handler per `type`. Adding a check *kind* is
   one registered function plus one test.
3. **A profile resolver** — decides which host block applies, and **fails loudly rather than
   guessing** when it cannot tell.
4. **A JSON Schema** — `doctor.py --validate` rejects a malformed config before anything runs.

### Why typed checks with a `command` escape hatch

A pure `run: <shell>` engine would be smaller, but every check would re-invent quoting,
portability and its own failure message, and none could carry structured remediation. A purely
typed engine would need a new handler for every one-off assertion in the unified spec.

The split: a small typed vocabulary for the recurring 80% (files, symlinks, binaries, `chezmoi
data`, `git config`, hostnames), and `type: command` for the rest. Typed checks produce good
failure messages for free; `command` guarantees nothing is ever un-expressible.

---

## Profile resolution

This is the load-bearing part, because **`supertop` and `minitop` are both `arm64` running as
`bossjones`**. A hardware/user fingerprint alone cannot distinguish them.

Resolution is ordered; the first rule that produces a unique answer wins:

```
1.  --profile <name>                       explicit CLI flag
2.  $DOTFILES_DOCTOR_PROFILE               environment override
3.  ~/.config/dotfiles-doctor/profile      machine-local file, one line, never chezmoi-managed
4.  hostname match                         any of the three scutil names equals the host key,
                                           or appears in that host's identity.aliases
5.  identity.match fingerprint             ONLY if exactly one host block matches
```

If rule 5 matches **two or more** hosts, the doctor **exits 3** and names the candidates:

```
✗ Cannot resolve profile: 2 candidates match this machine's fingerprint
    supertop  (arch=arm64, username=bossjones)
    minitop   (arch=arm64, username=bossjones)

  Disambiguate by any of:
    sudo scutil --set ComputerName supertop && sudo scutil --set LocalHostName supertop
    echo supertop > ~/.config/dotfiles-doctor/profile
    doctor.py --profile supertop
```

**This friction is deliberate.** The doctor is unusable on the two personal machines until their
hostnames are set or a profile is pinned — which converts "the hostnames are probably wrong" from
a hunch into an enforced precondition, at zero extra implementation cost.

`aliases` exists so a machine can resolve *today*, under its stale name, while its `assert:` block
still reports the drift. The block below is shown fully populated to illustrate the schema; what
actually ships until the survey returns is this same block with its values commented
`# HYPOTHESIS` (see [the fleet](#the-minitop-hypothesis)):

```yaml
hosts:
  minitop:
    identity:
      aliases: [Mac, Mac.scarlettlab.home, mac-mini]   # tolerate today's reality
      match:
        arch: arm64
        username: bossjones
      assert:
        computer_name: minitop        # error
        local_host_name: minitop      # error
        host_name: minitop            # warn, allow_unset
      chezmoi:
        profile: personal
```

So the mini resolves via rule 4 on the alias `Mac`, then immediately reports two hostname
findings with `scutil --set` remediation. Resolution and correctness stay separate concerns.

---

## The YAML schema

### Top level

```yaml
version: 1                      # schema version, required

defaults:
  timeout: 10                   # seconds per check subprocess
  shell: /bin/zsh               # used by type: command

common:
  checks: [...]                 # apply to every host

hosts:
  <name>:
    identity: {...}
    description: "..."
    checks: [...]               # additive
    skip:                       # opt out of a common check
      - id: <common-check-id>
        reason: "required, one line"
```

**Merge semantics.** Effective checks = `common.checks` + `hosts.<name>.checks`, minus every id
in `hosts.<name>.skip`. A duplicate `id` across the merged set is a **schema error** — to vary a
common check for one host, `skip` it and add a distinct one. There is no silent override.

`skip.reason` is mandatory. A skipped check appears in output as `SKIP` with its reason, so
opting out is visible rather than invisible.

### `identity`

```yaml
identity:
  aliases: [<string>, ...]      # extra names rule 4 will match
  match:                        # rule 5 fingerprint; ALL must match
    arch: arm64                 # uname -m
    username: bossjones         # id -un
    os: darwin                  # uname -s, lowercased
  assert:                       # checked and reported; never used to resolve
    computer_name: <string>
    local_host_name: <string>
    host_name: <string>
    os_major: <int>
    hw_model: <regex>
  chezmoi:
    profile: personal | work    # asserted against `chezmoi data`
```

`match` **resolves**; `assert` **verifies**. Keeping them separate is what lets a mis-named
machine still find its own profile and then be told it is mis-named.

### A check

```yaml
- id: gitconfig-no-adobe             # required, unique, kebab-case
  title: personal gitconfig carries no Adobe references
  type: command                      # required, from the registry below
  phase: post                        # pre | post | always      (default: always)
  severity: error                    # error | warn             (default: error)
  traces: [M2, C1, "#119"]           # spec findings and/or GH issues
  when:                              # optional; check is SKIPped unless all match
    os: darwin
    profile: personal
    binary_present: hub
    file_present: ~/.gitconfig
  fix: |                             # printed on failure, never executed
    Re-run chezmoi init with --promptString "profile=personal".
    NOTE: profile is sticky -- see unified spec, S3.
  # --- type-specific fields follow ---
  run: chezmoi cat ~/.gitconfig
  want_stdout_not_matching: "(?i)adobe"
```

`phase` semantics:

| `phase` | Runs when | Meaning |
|---|---|---|
| `pre` | `--phase pre`, `--phase all` | Precondition. Must hold *before* migrating. |
| `post` | `--phase post`, `--phase all` | Acceptance. Must hold *after* migrating. |
| `always` | every invocation | Invariant. Should hold at all times. **Default.** |

`always` is the default because an unlabelled assertion is almost always an invariant, and
because the everyday zero-argument `doctor.py` should be useful.

---

## Check type registry (v1)

Every check accepts the common fields above. Paths are `~`-expanded. All `*_matching` fields are
Python `re.search` patterns.

### `command` — the escape hatch

| Field | Notes |
|---|---|
| `run` | executed via `defaults.shell -c`, **not** a login/interactive shell |
| `cwd` | optional working directory |
| `want_exit` | int, default `0` |
| `want_stdout` | exact match after `.strip()` |
| `want_stdout_matching` | regex must match |
| `want_stdout_not_matching` | regex must **not** match |
| `want_stdout_empty` | bool |

At least one `want_*` must be present. Multiple are ANDed.

### `file_exists`

`path`, `want: present | absent` (default `present`).

### `file_contains`

`path`, and exactly one of `want` (literal substring) or `want_matching` (regex).
`absent: true` inverts. A missing file is a **failure**, not an error — reported as such.

### `symlink`

`path`, `want: present | absent`, and optionally `target` (literal) or `target_matching` (regex).

Compares against `os.readlink()` — the **raw link text**, not `realpath`. This matters for M4:
`~/.vimrc` is expected to be the *relative* link `.vim/.vimrc`, and `realpath` would erase that
distinction.

### `binary`

`name`, `want: present | absent`, optional `in_dir` (asserts the resolved path's directory
prefix), optional `version_matching` with `version_arg` (default `--version`).

### `path_entry`

`dir`, `want: present | absent`.

Evaluated against the **interactive** shell's `$path` (`zsh -i -c 'print -l $path'`), cached
once per run — not the doctor's own inherited `PATH`. M3 is specifically about `zshrc`
injections, which the doctor's own environment would not show.

### `git_config`

`key`, optional `cwd` (the probe directory), and `want` / `want_matching` / `absent: true`.

Runs `git -C <cwd> config --get <key>`, i.e. the **resolved** value with `includeIf` applied.
This is the M1 requirement: assert resolved identity, never file contents. If `cwd` does not
exist the check reports `SKIP` with a reason rather than failing — probe directories are
machine-specific.

### `chezmoi_data`

`key` (dotted path into `chezmoi data` JSON), `want` / `want_matching`.
`chezmoi data` is executed **once per run** and cached.

### `chezmoi_managed`

`pattern` (regex applied per line of `chezmoi managed`), and `count` (exact) or `min` / `max`.

Covers the unified spec's acceptance criterion of 3 managed `gitconfig-` files on work and 0 on
personal.

### `hostname`

`which: computer | local | host`, `want` or `want_any_of: [...]`, `allow_unset: bool`
(default `false`).

### `brew`

`formula` or `cask`, `want: present | absent`. Implemented in v1 but **unused by the shipped
profiles** — it is the absorption path for `check_dev_environment.py`'s hardcoded lists. Backed
by a single cached `brew list` rather than one subprocess per package.

---

## The script

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml>=6", "jsonschema>=4"]
# ///
```

Self-contained per PEP 723 — `./doctor.py` bootstraps its own dependencies through `uv`, with no
virtualenv to create and nothing added to the repo's Python requirements. Two dependencies only.

### CLI

```
doctor.py                          resolve profile, run phase=always, text output
doctor.py --phase pre|post|always|all
doctor.py --profile <name>         override resolution
doctor.py --list-profiles          show hosts and which one matches here
doctor.py --only <id>[,<id>...]    run a subset
doctor.py --skip <id>[,<id>...]    exclude a subset
doctor.py --explain <id>           print one check's definition, traces and fix, run nothing
doctor.py --format text|json       json for CI and for agent consumption
doctor.py --validate               schema-check profiles.yaml and exit; execute nothing
doctor.py --dry-run                list what would run, in order
doctor.py --config <path>          default: alongside the script
```

### Exit codes

| Code | Meaning |
|---|---|
| `0` | All `error` checks passed. `warn` failures may be present. |
| `1` | At least one `error` check failed. |
| `2` | Config missing, unparseable, or schema-invalid. |
| `3` | Profile could not be resolved, or resolved ambiguously. |

Distinct codes matter: a pre-flight gate needs to distinguish "this machine is not ready" (`1`)
from "I do not know what this machine is" (`3`).

### Internals

One file, but structured:

- `Ctx` — the resolved environment: home, arch, username, the three hostnames, OS version,
  `hw.model`, resolved profile name, and a **command runner**. Every expensive probe
  (`chezmoi data`, `brew list`, the interactive `$path`) is lazy and memoised on `Ctx`.
- `Check` / `Result` — frozen dataclasses. `Result` carries
  `status ∈ {PASS, FAIL, WARN, SKIP, ERROR}`, a message, and the observed value.
- `CHECK_TYPES: dict[str, Handler]` — populated by an `@register("name")` decorator.
  A handler is `(Check, Ctx) -> Result` and is **pure with respect to `Ctx`**.
- `resolve_profile(cfg, ctx, override) -> str` — implements the five ordered rules.
- `load()` / `validate()` / `render()`.

The purity constraint on handlers is what makes the test suite possible: a test injects a `Ctx`
with a stubbed runner and a `tmp_path` home, and no handler ever reaches the real system.

### Output

```
Profile: minitop            (resolved by: alias 'Mac' -> hosts.minitop)
Phase:   always             28 checks (2 skipped)

identity
  ✗ ERROR  identity-computer-name    want 'minitop', got 'Mac'
           traces: Q6, #116
           fix:    sudo scutil --set ComputerName minitop
  ⚠ WARN   identity-host-name        not set  (allowed; set it only if you want a stable FQDN)
git
  ✓ PASS   gitconfig-no-adobe
  ✓ PASS   git-default-branch
  ⊘ SKIP   git-identity-adobe-corp   when.profile=work, this host is personal

24 passed · 1 failed · 1 warned · 2 skipped
```

---

## Testing strategy

TDD: the suite is written before the engine. Run via
`uv run --with pytest --with pyyaml --with jsonschema pytest hack/doctor/tests`, exposed as a
`make doctor-test` target.

Five layers, described innermost-first. **Phase A builds them in a different order** — schema
first, because config loading gates everything else — see the [task list](#ordered-task-list).

**1. Handler unit tests.** One per registered type: a passing case, a failing case, and the
interesting edge (missing file, non-matching regex, unset hostname, `absent: true` inversion).
Fake runner, `tmp_path` home, zero real subprocesses.

**2. Profile-resolution tests.** The most valuable layer, because this is where the fleet is
genuinely ambiguous:

- `--profile` beats everything, including a contradicting hostname
- `$DOTFILES_DOCTOR_PROFILE` beats the machine-local file
- alias match resolves `Mac` → `minitop`
- **two hosts matching one fingerprint ⇒ exit 3, both candidates named** ← the supertop/minitop case
- unknown `--profile` ⇒ exit 3 listing valid names
- zero matches ⇒ exit 3, not a silent pass

**3. Schema tests.** The committed `profiles.yaml` validates. Fixtures with an unknown `type`, a
duplicate `id` across `common` + `hosts`, a bad `phase`, a `skip` without `reason`, and a
`command` check with no `want_*` are each rejected with a useful message.

**4. Traceability test — the feedback loop.** Every `traces:` entry matching `^[SMC]\d+$` or
`^Q\d+$` must actually appear as a defined finding in **either** spec — `S1`–`S7`, `M1`–`M4`,
`C1`–`C7` and `Q1`–`Q8` live in `unified-dotfiles-gap-analysis.md`; `Q9`+ are defined in *this*
document. The test searches both files and fails on an entry found in neither.

Entries matching `^#\d+$` are only checked for **syntactic** validity offline — asserting an
issue exists requires the network, so that check runs solely under `DOCTOR_LIVE=1` via
`gh issue view`, and is skipped otherwise.

> This is the mechanism that stops `profiles.yaml` and the unified spec drifting apart in
> silence. Renaming or deleting a finding in the spec breaks the test suite. Without it, the
> config slowly becomes folklore.

**5. Live `adobetop` integration test.** Marked `@pytest.mark.live`, skipped unless
`DOCTOR_LIVE=1`. Runs `--profile adobetop --phase always --format json` against the real machine
and asserts every check either passes or is on an explicit, documented known-failure list. This
is the half of the work that "build it for the current machine" refers to: the `adobetop` profile
is authored against observed reality, not guessed.

---

## Traceability to the unified spec

Each check names the finding it enforces. Indicative initial mapping:

| Finding | Check(s) | Phase |
|---|---|---|
| S1 gitignore `settings.local.json` | `file_contains` on `~/.gitignore_global` | post |
| S2 `init.defaultBranch = main` | `git_config` | post |
| S3 `profile` key | `chezmoi_data` + `identity.chezmoi.profile` | post |
| S5 `core.editor` | `git_config` | post |
| S6 `version_manager = mise` | `chezmoi_data`, `binary` mise, `file_exists` `~/.tool-versions.asdf.bak` | post |
| S7 delete `dot_zshrc.local.tmpl` | `file_exists` absent (source tree) | post |
| M1 identity routing | `git_config user.email` + `url.*.insteadOf` across six probe `cwd`s | post |
| M2 `hub.host` | `command` on `chezmoi cat ~/.gitconfig`, `not_matching adobe` | post |
| M3 injections | `path_entry` / `binary` for `scout`, `awesome-cli`, `libpcap` | always |
| M4 `~/.vimrc` | `symlink` target `.vim/.vimrc` + line count | post |
| C2 resurrection guard | `command` git diff `--diff-filter=A`, `want_stdout_empty` | **pre** |
| C3 `myFzfTabRev` tripwire | `chezmoi_data` `fzf_tab` consistency | always |
| C5 remote/`gh` mismatch | `command` comparing `git remote -v` protocol to `gh auth status` | **pre** |
| Q6 hostname drift | `hostname` ×3 via `identity.assert` | always |
| Testing Strategy §4 | `command` `zsh -i -c exit`, stderr vs recorded baseline | always |

The known-good shell-startup baseline is per-host data — the unified spec records a
**pre-existing** `(eval):1: can't change option: zle` warning on the personal machine that must
not be misattributed to the migration. That string lives in `hosts.minitop`, not in `common`.

---

## The prompt issues

Two GitHub issues, one per unsurveyed machine, labelled **`prompt`** (new label: *"Runnable
research/agent prompt; pick up when ready"*), plus new labels `machine:supertop` and
`machine:minitop`. The existing `machine:personal` label stays — nine open issues reference it.

> **Created as `bossjones`, not `malcolm_adobe`.** `gh auth switch --user bossjones` first,
> switch back afterwards. This repo is public and personal; the unified spec's C5 records that
> the active `gh` account on `adobetop` is the Adobe Enterprise Managed User. Git commit identity
> is already correct (`bossjones@theblacktonystark.com` over ssh) — only the `gh` API account
> needs switching.

Each issue body is a runnable six-phase prompt. **The ordering is load-bearing.**

```
P0  CONFIRM IDENTITY     Three scutil names, hostname, arch, user, sw_vers, hw.model.
                         Record verbatim. Do NOT assume minitop is mac-mini or that
                         mac-mini is Mac.scarlettlab.home -- that is the hypothesis
                         under test.

P1  OBSERVE AND SCOUT    Read-only. File-level evidence, not inference.

P2  INTERVIEW  ◄─ gate   Ask the human, one question at a time, for every chezmoi data
                         value. Never infer. Never proceed on a default.

P3  WRITE FINDINGS       hosts.<name>: in profiles.yaml + a Findings subsection in the
                         unified spec + answers to Q1-Q8 where this machine has evidence.

P4  VALIDATION LOOP      --validate -> --phase pre -> iterate until green, or until every
                         red is a documented intentional finding. Run the test suite.

P5  STOP                 Open a PR. No chezmoi init. No chezmoi apply.
```

### P1 — what to observe

Mirrors the unified spec's evidence categories:

- `git config --list --show-origin`; `includeIf` blocks; resolved `user.email` per probe dir
- `~/.gitignore_global`; `init.defaultBranch`; `core.editor`; `hub.host`; is the `pr` alias used?
- `chezmoi data`, `chezmoi status`, `chezmoi diff --no-pager`, `chezmoi managed`, `chezmoi --version`
- Version manager: `asdf`/`mise` presence, `~/.tool-versions`, the orphaned-tool list
- `~/.vimrc` and `~/.tmux.conf` — regular file, symlink, or absent? `readlink`, not `realpath`
- Third-party `zshrc`/`zprofile` injections, found by **diffing rendered-vs-live**
- `zsh -i -c exit` exit code and full stderr — the baseline
- Source-repo state: branch, divergence from `origin/main`, the C2 resurrection guard
- A checksummed backup, taken **first**

> **Methodology note carried from the unified spec:** none of the personal machine's four
> injections used `# >>> … <<<` sentinel markers. **Sentinel-grep is not a sufficient audit.**
> Diff rendered against live.

### P2 — the interview, and why it is a hard gate

The chezmoi data keys are **sticky**. Once written to `~/.config/chezmoi/chezmoi.yaml`, `hasKey`
short-circuits the prompt and re-passing `--promptString` is a silent **no-op**. A wrong answer on
the first `init` is not correctable by re-running `init` — it requires hand-editing the config.

So the values must be *decided*, in the open, before anything is written. The interview covers
`profile`, `version_manager`, `pyenv`, `opencv`, `cuda`, `fzf_tab`, `Name`, `Email`,
`Computer name`, `Host name` — each posed as:

> *"This machine currently has **X**. The unified spec recommends **Y**, because **Z**.
> Which do you want?"*

which is only answerable once P1 has established X. Hence P1 → P2 and not the reverse.

Two traps the interview must surface rather than assume:

- **`profile` has only two values.** Both `supertop` and `minitop` resolve to `personal`, so
  chezmoi cannot distinguish them at all. If they need to differ on anything chezmoi renders, the
  key is insufficient — see Q9.
- **The prompts sit inside `if $interactive`.** A non-TTY `chezmoi init` silently yields
  all-`false`. That is precisely how the personal machine's config broke. Verify with
  `chezmoi data`, never by exit code.

---

## Relationship to the existing script

`hack/doctor/check_dev_environment.py` (698 lines, stdlib-only, hardcoded package lists) is
**untouched**, along with its `Makefile` targets, `README.md`, `QUICKSTART.md`,
`install_missing.sh` and `example_output.txt`.

The two have different jobs today: it answers *"is my toolchain installed?"*, `doctor.py` answers
*"is this specific machine in the state the migration plan says it should be?"*.

The convergence path — deliberately **not** part of this spec — is to move its package
inventory into `common.checks` as `type: brew` and `type: binary` data once `doctor.py` has
proven itself, then retire it. Tracked separately so a large mechanical data migration cannot
destabilise the engine it depends on.

---

## Security and public-repo constraints

`bossjones/zsh-dotfiles` is **public**. Therefore:

- **No private IPs or LAN topology in `profiles.yaml`.** The `~/.ssh/config` survey that produced
  the fleet table above stays out of the committed tree; only machine *names* are recorded.
- **No secrets, tokens, or key paths.** Checks assert *shape* — that a file exists, that a config
  key resolves to an expected value — never a credential.
- The unified spec's **Q4 is still open**: whether the three `~/.gitconfig-*` files are genuinely
  secret-free before being committed. `doctor.py` does not settle it and must not be read as
  having done so.
- `git.corp.adobe.com` already appears in the committed unified spec. This spec does not widen
  that exposure and does not treat it as licence to add more.

---

## Ordered task list

**Phase A — schema and engine (TDD)**
- [ ] `hack/schemas/doctor-profiles.schema.json`
- [ ] Test layer 3 (schema) — written first, red
- [ ] `doctor.py` skeleton: `Ctx`, `Check`, `Result`, registry, `load`/`validate`, `--validate`
- [ ] Test layer 2 (resolution) — red, including the ambiguity case
- [ ] `resolve_profile()` — green
- [ ] Test layer 1 (handlers) — red, one type at a time
- [ ] Handlers — green, one type at a time
- [ ] `render()` text + json; exit codes

**Phase B — the `adobetop` profile**
- [ ] `profiles.yaml`: `version`, `defaults`, `common.checks` from the shared findings
- [ ] `hosts.adobetop` from **observed** state
- [ ] Test layer 4 (traceability) — green
- [ ] Test layer 5 (live) — green, or every failure documented
- [ ] `make doctor-test` + `make doctor`

**Phase C — fleet expansion**
- [ ] `hosts.supertop` / `hosts.minitop` stubs, identity commented `# HYPOTHESIS`
- [ ] Labels `prompt`, `machine:supertop`, `machine:minitop` (as `bossjones`)
- [ ] Issue: *prompt: survey supertop*
- [ ] Issue: *prompt: survey minitop*
- [ ] `specs/unified-dotfiles-gap-analysis.md` → **Part 4**, and Q9–Q11

**Phase D — after the surveys return**
- [ ] Merge each machine's findings; resolve Q9
- [ ] Re-run `--phase pre` on all three; only then does epic #116 Phase 1 start

---

## Acceptance criteria

- [ ] `./hack/doctor/doctor.py --validate` exits `0`; a corrupted fixture exits `2`
- [ ] On `adobetop`, zero-argument `doctor.py` resolves `adobetop` and exits `0`
- [ ] `--profile nonesuch` exits `3` and lists the valid names
- [ ] A fixture with two fingerprint-identical hosts exits `3` naming **both**
- [ ] Every `traces:` entry resolves to a real finding in the unified spec (layer 4)
- [ ] `--format json` is machine-readable and carries `status`, `traces` and `fix` per check
- [ ] `hostname` checks report `adobetop`'s unset `HostName` as **`WARN`**, never `ERROR`
- [ ] `profiles.yaml` contains no IP address, credential, or key path
- [ ] `check_dev_environment.py` and every existing `Makefile` target still work unchanged
- [ ] Both prompt issues exist, labelled `prompt`, authored by `bossjones`

---

## Open questions

- **Q9 — Is chezmoi's two-valued `profile` sufficient for a three-machine fleet?** `supertop` and
  `minitop` both resolve to `personal`. Fine only if they never diverge on anything chezmoi
  renders. If they do, the unified spec needs a third value or a different mechanism. **Only the
  P1 surveys can answer this**, and it is the strongest argument for the doctor keeping its own
  per-host profiles rather than reusing `profile`.
- **Q10 — Is `minitop` actually `mac-mini`, and is `mac-mini` actually `Mac.scarlettlab.home`?**
  Two chained assumptions, neither verified. If false, the unified spec's entire "personal
  machine" evidence base belongs to a machine not yet identified.
- **Q11 — Should `supertop` be `profile=work` or `profile=personal`?** Assumed `personal` from
  its `bossjones` ssh user, but never surveyed. If work repos are cloned there, M1's identity
  routing applies and the assumption is wrong.
- **Q12 — Should `HostName` be set at all?** Unset is the macOS default and harmless. Setting it
  fleet-wide would make all three names agree and simplify resolution rule 4, at the cost of a
  `sudo` step per machine. Currently `warn`-only; this is a preference, not evidence.
- **Q13 — Where does `doctor.py` run in CI?** The GitHub Actions matrix is macOS-only and none of
  these three machines exists there, so `--phase pre|post` is meaningless in CI. Layers 1–4 of the
  test suite are CI-safe; layer 5 is not. Worth wiring the first four into the existing workflow.

---

## Notes

- **No implementation has been performed.** This document is the design gate.
- **Nothing here mutates a machine.** The doctor is read-only by construction, and the prompt
  issues explicitly forbid `chezmoi init` and `chezmoi apply`.
- **New dependencies: two** (`pyyaml`, `jsonschema`), both vendored per-run by `uv` and neither
  added to the repo's Python requirements.
- The fleet reconnaissance behind the machine table came from `~/.ssh/config` on `adobetop` on
  2026-08-31. `supertop` and `mac-mini` were **not** reachable — the work VPN was active — so
  every claim about them is hypothesis pending P0.
