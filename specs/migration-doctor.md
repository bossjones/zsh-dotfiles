# Spec: `hack/doctor` — a YAML-driven convergence doctor

> **Status:** design agreed 2026-08-31; Phases A–B implemented
> **User documentation:** [`docs/doctor.md`](../docs/doctor.md) (reference) ·
> [Tutorial 08](../docs/tutorials/08-investigate-an-environment.md) (hands-on)
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

The fleet is **three**. But the more important correction is not the count — it is the *shape* of
what we want:

> **Every work machine should look like every other work machine. Every personal machine should
> look like every other personal machine.** Where a machine differs from its profile today, that
> is drift to be eliminated, not a configuration to be preserved.

Per-machine divergence is a **symptom**, not a feature. Surfacing it is the point of the exercise.

## Objective

A single self-contained script, driven by a single committed YAML file, answering four questions
on any machine in the fleet:

1. **Which machine am I?** — and is that answer unambiguous?
2. **Is this machine safe to migrate?** (`--phase pre`)
3. **Did the migration land correctly?** (`--phase post`)
4. **How far is this machine from its profile?** (`--state target`) ← the convergence question

with the everyday case being the zero-argument run: *is this machine still healthy, and is its
known drift still only the drift we already accepted?*

## Non-goals

- **It does not remediate.** Every check may carry a `fix:` string; it is *printed, never
  executed*. The operations in question (`chezmoi apply`, `scutil --set`, git identity routing,
  the asdf→mise migration) are exactly the ones the unified spec marks `risk:high` and gates
  behind manual `chezmoi diff` review.
- **It does not replace `check_dev_environment.py`.** See [Relationship to the existing
  script](#relationship-to-the-existing-script).
- **It does not run `chezmoi init` or `chezmoi apply`.** It only observes.
- **It is not a place to record how machines differ.** It is a place to record how they should be
  the same, and to make each remaining difference visible, tracked, and expiring.

---

## The fleet

| Name | Profile | User | Arch | Identity status |
|---|---|---|---|---|
| `adobetop` | work | `malcolm` | arm64 | **Confirmed** — macOS 15.7.9 (24G830) |
| `supertop` | **personal** *(confirmed)* | `bossjones` | arm64 *(assumed)* | Apple Silicon laptop; in `~/.ssh/config`, never surveyed |
| `minitop` | personal *(assumed)* | `bossjones` | arm64 *(assumed)* | **Hypothesis** — see below |

### The `minitop` hypothesis

`~/.ssh/config` contains hosts `adobetop`, `supertop` and **`mac-mini`**. There is no host named
`minitop`. The unified spec records the personal machine as `Mac.scarlettlab.home`, with
`.chezmoi.hostname` resolving to the bare `"Mac"`.

A Mac mini left at the factory-default `ComputerName` of `Mac` produces exactly that. Working
hypothesis:

> **`minitop` is the informal name for the `mac-mini` host, which is the machine the unified
> spec calls `Mac.scarlettlab.home`.**

**Not confirmed.** Two chained assumptions, neither verified. Confirmation is P0 of
[#137](https://github.com/bossjones/zsh-dotfiles/issues/137). Until then `hosts.minitop.identity` ships with its
values commented `# HYPOTHESIS`.

### macOS has three hostnames, and one is normally unset

Every source enumerated on `adobetop`, 2026-08-31. `doctor.py --identity` probes the **nine**
that are real sources; the last four rows are recorded so nobody re-investigates them:

| Command | `adobetop` | Kind |
|---|---|---|
| `scutil --get ComputerName` | `adobetop` | **settable** — UI name; allows spaces/unicode |
| `scutil --get LocalHostName` | `adobetop` | **settable** — Bonjour/mDNS; DNS-safe charset only |
| `scutil --get HostName` | *not set* | **settable** — usually unset |
| `sysctl -n kern.hostname` | `adobetop.local` | derived — what `hostname` reads |
| `hostname` / `uname -n` | `adobetop.local` | derived from `kern.hostname` |
| `hostname -s` / `hostname -f` | `adobetop` / `adobetop.local` | derived |
| `networksetup -getcomputername` | `adobetop` | mirror of `ComputerName` |
| `hostinfo` | — | **not a hostname source** on modern macOS (kernel info only) |
| `smbutil status` | timed out | SMB off; unusable |
| `ipconfig getpacket en0` | empty | no DHCP `host_name` option here |
| `/etc/hosts` | loopback only | not a source |

**Three settable values; everything else derives.** When `HostName` is unset, macOS synthesises
`kern.hostname` as `LocalHostName + .local` — which is why `Mac.scarlettlab.home` on the mini was
never `scutil HostName`. It came from DNS.

The failure mode worth detecting is not any single value but **disagreement between the three
settable ones**, which is what `--identity` reports.

Nothing sets `HostName` unless `sudo scutil --set HostName` is run explicitly, so an unset value
is a healthy machine, not a broken one. Severity is calibrated accordingly:

| Name | Severity | Rationale |
|---|---|---|
| `ComputerName` | `error` | User-facing, user-controlled, what you actually renamed |
| `LocalHostName` | `error` | What `hostname` derives from, and what `.chezmoi.hostname` sees |
| `HostName` | **`warn`**, `allow_unset: true` | Unset is the healthy default; flag only if set *wrongly* |

This is not cosmetic. See [Host specialization](#host-specialization-and-the-answer-to-q9) — a
correct `LocalHostName` is the **prerequisite** for the templating mechanism that handles genuine
host differences.

### The setter script (Q12)

The doctor detects hostname drift; a companion **templated chezmoi script** fixes it at bootstrap.
The two chezmoi data keys that already exist map onto macOS's constraints exactly:

```
computer_name  →  ComputerName                 (spaces/unicode legal)
hostname       →  LocalHostName + HostName     (DNS-safe charset required)
```

That is why the personal machine carries `"boss workstation"` / `"bossworkstation"` — the space is
legal in one and not the other. **The keys were designed for this and nothing was consuming them.**

```gotemplate
{{- if eq .chezmoi.os "darwin" -}}
sudo scutil --set ComputerName  "{{ .computer_name }}"
sudo scutil --set LocalHostName "{{ .hostname }}"
sudo scutil --set HostName      "{{ .hostname }}"
{{- end }}
```

Consequences:

- **Q6 is answered.** The personal machine's stale `computer_name`/`hostname` stop being
  decorative and become the source of truth — so they must be corrected before this runs.
- Needs `sudo`, so it is a `run_onchange_` script the operator reviews, not a silent apply.
- `hostname` must be validated DNS-safe (no spaces) or `scutil --set LocalHostName` fails.
- The doctor's `identity.assert` block and this script read the **same** two keys, so they cannot
  disagree by construction.

---

## Two states: today, and target

The central concept, and what the layering exists to serve.

|  | Meaning | In the config |
|---|---|---|
| **Target state** | What every machine of this profile *should* look like | `common:` + `profiles.<p>:` |
| **Today's state** | Where a specific machine deviates, right now | `hosts.<h>.drift:` |

Every drift entry is a **dated, tracked, expiring** deviation — never an indefinite exception:

```yaml
hosts:
  minitop:
    drift:
      - id: minitop-zle-warning
        title: pre-existing "(eval):1: can't change option: zle" on shell startup
        observed: 2026-08-15        # when we first saw it
        expected: absent            # what the target state says
        tracked: "#129"             # REQUIRED -- no untracked drift
        type: command
        run: zsh -i -c exit
        want_stderr_matching: "can't change option: zle"
```

The doctor evaluates against either state:

| Mode | `drift` entries | `common`/`profiles` checks | Exit |
|---|---|---|---|
| `--state today` *(default)* | tolerated, reported `KNOWN` | must pass | `0` |
| `--state target` | **treated as failures** | must pass | `1` if any remain |

`--state target` answers *"how far is this fleet from converged?"* The drift register becomes a
machine-readable list of accepted deviations with a sunset, rather than a permanent home for
divergence.

**Untracked drift fails in both states.** A drift entry with no `tracked:` issue has no
convergence plan and is therefore not an accepted deviation — it is an unmanaged difference.
Schema-enforced: `tracked` is a required field.

### `--state` and `--phase` are different axes

They compose rather than overlap, and it is worth being precise because they look similar:

- **`phase`** — *when in the migration procedure* a check applies. `pre` is a precondition
  (safe to start?), `post` is acceptance (did it land?), `always` is an invariant.
- **`state`** — *whether known drift is tolerated* on this run.

`--phase post --state target` is the strongest assertion available: **fully migrated and fully
converged.** That combination is the real definition of "done" for epic #116.

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

### The three layers

```yaml
common:              # every machine, both profiles
profiles:
  work:              # every work machine
  personal:          # every personal machine
hosts:
  minitop:
    identity: {...}  # inherent and permanent: names, arch, hw model, OS
    drift:   [...]   # tracked, dated, expiring deviations
```

Effective checks = `common.checks` + `profiles.<p>.checks` + `hosts.<h>.drift`.

**There is no `hosts.<h>.checks` key.** This is deliberate and load-bearing: the schema provides
*nowhere* to park a permanent per-host assertion. A host block may contain only what is inherent
(`identity`) and what is temporary (`drift`).

A genuine, permanent hardware difference is therefore expressed at **profile** level, gated:

```yaml
profiles:
  personal:
    checks:
      - id: laptop-battery-health
        when: {hw_model: "MacBook.*"}    # minitop is a Mac mini; SKIPs cleanly
        type: command
        run: pmset -g batt
```

This costs a few extra characters when a real difference exists, and in exchange makes it
impossible to quietly accumulate host exceptions. `skip:` from the earlier draft is **removed**
for the same reason — opting a host out of a check *is* divergence, so it must be either a `when:`
condition (inherent) or a `drift` entry (temporary).

### Why typed checks with a `command` escape hatch

A pure `run: <shell>` engine would be smaller, but every check would re-invent quoting,
portability and its own failure message, and none could carry structured remediation. A purely
typed engine would need a new handler for every one-off assertion in the unified spec.

The split: a small typed vocabulary for the recurring 80%, and `type: command` for the rest.

---

## Host specialization, and the answer to Q9

An earlier draft asked whether chezmoi's two-valued `profile` key suffices for three machines.
**It does.** `profile` stays `personal | work`, and `supertop`/`minitop` both resolving to
`personal` is the *intended* outcome, not a limitation.

Where a machine genuinely needs something the rest of its profile does not, the mechanism is a
**chezmoi template with a conditional** that includes or removes the value — not a third profile
value, and not a per-host config sprawl.

That has a dependency worth naming explicitly. The unified spec rejected hostname gating because
`.chezmoi.hostname` resolves to a collision-prone bare `"Mac"` on the personal machine. So a
host-conditional template is only safe **once `ComputerName`/`LocalHostName` are correctly set**
on the personal machines.

> **The hostname fix is a prerequisite for the specialization mechanism, not cosmetic hygiene.**
> The doctor enforces it at `error` severity, which is what makes the template conditional viable
> later.

The doctor's own job with respect to specialization is to keep the number of such conditionals as
small as the evidence allows — every one is a divergence that has to justify itself.

---

## SSH config consolidation

Same convergence problem, different file. `~/.ssh/config` on `adobetop` repeats an identical
eight-line block across every LAN host entry. The mechanism, verified on macOS 15.7.9:

```
/etc/ssh/ssh_config:22        Include /etc/ssh/ssh_config.d/*        ← already present
/etc/ssh/ssh_config.d/        exists; contains 100-macos.conf
precedence:  1. CLI   2. ~/.ssh/config   3. /etc/ssh/ssh_config      (FIRST value wins)
```

**The precedence is exactly right for this.** `~/.ssh/config` is read *before* the system file and
first-match-wins, so any hand-edit on a machine automatically beats the shared default. Manual
edits cannot be overwritten — they win structurally, not by luck.

> ⚠️ **ssh_config is FIRST-match-wins; gitconfig is LAST-match-wins.** They are opposite. An
> `Include` belongs at the **top** of an ssh config, while M1's `includeIf` block must be **last**
> in the gitconfig. Getting this backwards yields a file that silently ignores local overrides.

> ⚠️ **Never hoist `StrictHostKeyChecking no` or `UserKnownHostsFile /dev/null` to `Host *`.**
> They are per-host today, which is defensible for LAN boxes that get reimaged. As a global
> default they would disable host-key verification **for `github.com` and `git.corp.adobe.com`
> too** — a real security regression. This is the one line in the shared block that must stay
> per-host.

> ⚠️ **`/etc/ssh/ssh_config.d/` is root-owned and outside `$HOME`,** which is chezmoi's entire
> domain. This needs a `run_onchange_` script with `sudo`, or a documented manual step. Number the
> file deliberately: `100-macos.conf` already exists and lower numbers win, so
> `200-zsh-dotfiles.conf` yields to Apple's file on conflict.

**Sequencing:** the shared block cannot be authored until `supertop`'s and `minitop`'s configs have
been compared against `adobetop`'s — otherwise "common" is a guess from one machine. Capturing
`~/.ssh/config` is therefore a **P1 item in both survey prompts**, and this work is blocked on
them.

---

## Profile resolution

Load-bearing, because **`supertop` and `minitop` are both `arm64` running as `bossjones`**. A
hardware/user fingerprint alone cannot distinguish them.

Ordered; the first rule producing a unique answer wins:

```
1.  --profile <name>                       explicit CLI flag
2.  $DOTFILES_DOCTOR_PROFILE               environment override
3.  ~/.config/dotfiles-doctor/profile      machine-local file, one line, never chezmoi-managed
4.  hostname match                         any of the three scutil names equals the host key,
                                           or appears in that host's identity.aliases
5.  identity.match fingerprint             ONLY if exactly one host block matches
```

Ambiguity under rule 5 **exits 3** and names the candidates:

```
✗ Cannot resolve profile: 2 candidates match this machine's fingerprint
    supertop  (arch=arm64, username=bossjones)
    minitop   (arch=arm64, username=bossjones)

  Disambiguate by any of:
    sudo scutil --set ComputerName supertop && sudo scutil --set LocalHostName supertop
    echo supertop > ~/.config/dotfiles-doctor/profile
    doctor.py --profile supertop
```

**Deliberate friction.** The doctor is unusable on the two personal machines until hostnames are
set or a profile is pinned — turning "the hostnames are probably wrong" from a hunch into an
enforced precondition, at zero implementation cost, and unblocking host-conditional templating as
a side effect.

`aliases` lets a machine resolve *today* under its stale name while `assert:` still reports the
drift. Shown fully populated to illustrate the schema; what ships until the survey returns is this
block with its values commented `# HYPOTHESIS`:

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
      profile: personal               # which profiles.<p> block applies
```

Resolution and correctness stay separate concerns: `match` **resolves**, `assert` **verifies**.

---

## The YAML schema

### Top level

```yaml
version: 1                      # schema version, required

defaults:
  timeout: 10                   # seconds per check subprocess
  shell: /bin/zsh               # used by type: command

common:
  checks: [...]                 # every machine

profiles:
  work:
    checks: [...]
  personal:
    checks: [...]

hosts:
  <name>:
    identity: {...}             # required
    description: "..."
    drift: [...]                # tracked deviations; NO `checks:` key exists
```

**Merge semantics.** Effective set = `common.checks` + `profiles.<resolved>.checks` +
`hosts.<resolved>.drift`. A duplicate `id` anywhere in the merged set is a **schema error** —
there is no silent override.

### `identity`

```yaml
identity:
  profile: personal | work      # required; selects the profiles.<p> block
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
```

`identity.profile` is asserted against `chezmoi data`'s `profile` key. A mismatch is an `error` —
it means the machine's chezmoi config disagrees with the fleet definition, which is precisely the
class of drift this whole design exists to catch.

### A check

```yaml
- id: gitconfig-no-adobe             # required, unique, kebab-case
  title: personal gitconfig carries no Adobe references
  type: command                      # required, from the registry below
  phase: post                        # pre | post | always      (default: always)
  severity: error                    # error | warn             (default: error)
  traces: [M2, C1, "#119"]           # spec findings and/or GH issues
  when:                              # optional; SKIP unless all match
    os: darwin
    hw_model: "MacBook.*"
    binary_present: hub
    file_present: ~/.gitconfig
  fix: |                             # printed on failure, never executed
    Re-run chezmoi init with --promptString "profile=personal".
    NOTE: profile is sticky -- see unified spec, S3.
  run: chezmoi cat ~/.gitconfig      # --- type-specific fields ---
  want_stdout_not_matching: "(?i)adobe"
```

`when.profile` is **not** available — a check that applies to only one profile belongs in that
profile's block, not in `common` behind a condition.

### A drift entry

Every field of a check, plus three required ones:

| Field | Required | Meaning |
|---|---|---|
| `observed` | yes | ISO date the deviation was first recorded |
| `expected` | yes | What the target state says instead |
| `tracked` | yes | GH issue driving convergence. **No untracked drift.** |

A drift entry's assertion describes **the deviation as it exists today**, so it *passes* under
`--state today` (confirming the drift is still what we think it is) and *fails* under
`--state target` (confirming it has not yet been eliminated). A drift check that stops passing
under `--state today` is also a finding: the machine changed underneath us.

### Sunset policy (Q14, decided)

**Drift is a valid accepted deviation only while its tracking issue is open.**

```
tracked issue OPEN    + drift present  →  KNOWN   (accepted, has a plan)
tracked issue CLOSED  + drift present  →  FAIL    (the fix did not take)
tracked issue OPEN    + drift ABSENT   →  FAIL    (stale register entry; delete it)
no tracked issue                       →  schema error
```

Chosen over a `review_by:` date because a self-set deadline on personal dotfiles has no external
forcing function and becomes a rubber stamp. Issue state is a signal already maintained as part of
normal work, so the register stays honest with **no new discipline**. The middle row is the
valuable one: closing #123 while the drift is still present is exactly the silent failure a date
would never catch.

Mechanics: `gh` issue states are fetched in **one batched `gh api graphql` call**, cached to
`~/.cache/dotfiles-doctor/issues.json` with a TTL. **Offline degrades to `WARN`, never `FAIL`** —
no network means no verdict, not a bad verdict. Runs when `gh` is authenticated or under
`DOCTOR_LIVE=1`.

Reporting keeps age visible without gating on it: the drift register prints oldest-`observed`
first with a day count, so a quietly ageing entry is obvious without a build failing over it.

### `phase` semantics

| `phase` | Runs when | Meaning |
|---|---|---|
| `pre` | `--phase pre`, `--phase all` | Precondition. Must hold *before* migrating. |
| `post` | `--phase post`, `--phase all` | Acceptance. Must hold *after* migrating. |
| `always` | every invocation | Invariant. **Default.** |

---

## Check type registry (v1)

Common fields as above. Paths are `~`-expanded. All `*_matching` fields are Python `re.search`
patterns.

### `command` — the escape hatch

| Field | Notes |
|---|---|
| `run` | executed via `defaults.shell -c`, **not** a login/interactive shell |
| `cwd` | optional working directory |
| `want_exit` | int, default `0` |
| `want_stdout` | exact match after `.strip()` |
| `want_stdout_matching` / `want_stdout_not_matching` | regex |
| `want_stdout_empty` | bool |
| `want_stderr_matching` / `want_stderr_not_matching` | regex — needed for the shell-startup baseline |

At least one `want_*` required. Multiple are ANDed.

### `file_exists`
`path`, `want: present | absent` (default `present`).

### `file_contains`
`path`, and exactly one of `want` (literal substring) or `want_matching` (regex).
`absent: true` inverts. A missing file is a **failure**, not an error.

### `symlink`
`path`, `want: present | absent`, optional `target` (literal) or `target_matching` (regex).

Compares against `os.readlink()` — the **raw link text**, not `realpath`. Matters for M4:
`~/.vimrc` is expected to be the *relative* link `.vim/.vimrc`, which `realpath` would erase.

### `binary`
`name`, `want: present | absent`, optional `in_dir` (resolved-path directory prefix), optional
`version_matching` with `version_arg` (default `--version`).

### `path_entry`
`dir`, `want: present | absent`.

Evaluated against the **interactive** shell's `$path` (`zsh -i -c 'print -l $path'`), cached once
per run — not the doctor's inherited `PATH`. M3 is about `zshrc` injections, which the doctor's own
environment would not show.

### `git_config`
`key`, optional `cwd` (probe directory), and `want` / `want_matching` / `absent: true`.

Runs `git -C <cwd> config --get <key>` — the **resolved** value with `includeIf` applied. This is
the M1 requirement: assert resolved identity, never file contents. A missing `cwd` reports `SKIP`
with a reason rather than failing.

### `chezmoi_data`
`key` (dotted path into `chezmoi data` JSON), `want` / `want_matching`. Executed once, cached.

### `chezmoi_managed`
`pattern` (regex per line of `chezmoi managed`), and `count` (exact) or `min` / `max`.
Covers the 3-managed-`gitconfig-`-files-on-work / 0-on-personal criterion.

### `chezmoi_data_complete`

No fields. Diffs the keys emitted by the current `home/.chezmoi.yaml.tmpl` `data:` block against
the keys present in live `chezmoi data`; any missing key is a finding.

This exists because "a flag was introduced after your last `apply`" is a **recurring class**, not
three incidents. `adobetop` is missing `version_manager`, `fzf_tab` **and** `profile` today —
which is the direct cause of C3. A generic check catches the next flag automatically, with no one
remembering to add an assertion for it.

Distinguishes the two stickiness cases, because they have different fixes:

| Situation | Fix |
|---|---|
| Key **absent** | `hasKey` is false ⇒ the prompt fires ⇒ re-run `chezmoi init` |
| Key **present but wrong** | `hasKey` short-circuits ⇒ hand-edit `~/.config/chezmoi/chezmoi.yaml` |

### `hostname`
`which: computer | local | host`, `want` or `want_any_of: [...]`, `allow_unset` (default `false`).

### `brew`
`formula` or `cask`, `want: present | absent`. Implemented in v1 but **unused by the shipped
profiles** — the absorption path for `check_dev_environment.py`'s hardcoded lists. Backed by one
cached `brew list`, not one subprocess per package.

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
virtualenv to create and nothing added to the repo's Python requirements.

### CLI

```
doctor.py                          resolve, phase=always, state=today, text output
doctor.py --state today|target     tolerate known drift, or demand convergence
doctor.py --phase pre|post|always|all
doctor.py --profile <name>         override resolution
doctor.py --list-profiles          show hosts and which matches here
doctor.py --identity               probe every macOS hostname source; flag disagreement
doctor.py --drift                  print only the drift register, with tracking issues
doctor.py --only <id>[,...]        run a subset
doctor.py --skip <id>[,...]        exclude a subset (CLI only; no config equivalent)
doctor.py --explain <id>           print one check's definition, traces, fix; run nothing
doctor.py --format text|json       json for CI and agent consumption
doctor.py --validate               schema-check and exit; execute nothing
doctor.py --dry-run                list what would run, in order
doctor.py --config <path>          default: alongside the script
```

### Exit codes

| Code | Meaning |
|---|---|
| `0` | All `error` checks passed. `warn` failures and (under `--state today`) known drift may be present. |
| `1` | At least one `error` check failed, or unresolved drift under `--state target`. |
| `2` | Config missing, unparseable, or schema-invalid. |
| `3` | Profile could not be resolved, or resolved ambiguously. |

Distinct codes matter: a pre-flight gate must distinguish "this machine is not ready" (`1`) from
"I do not know what this machine is" (`3`).

### Internals

One file, structured:

- `Ctx` — resolved environment: home, arch, username, three hostnames, OS version, `hw.model`,
  resolved profile/host, and a **command runner**. Every expensive probe (`chezmoi data`,
  `brew list`, the interactive `$path`) is lazy and memoised.
- `Check` / `Result` — frozen dataclasses. `Result.status ∈ {PASS, FAIL, WARN, SKIP, KNOWN, ERROR}`.
  `KNOWN` is drift passing under `--state today`.
- `CHECK_TYPES: dict[str, Handler]` via an `@register("name")` decorator. A handler is
  `(Check, Ctx) -> Result`, **pure with respect to `Ctx`** — which is what makes the suite
  possible: tests inject a stubbed runner and a `tmp_path` home, and no handler touches the real
  system.
- `resolve_profile(cfg, ctx, override) -> str`, `load()`, `validate()`, `render()`.

### Output

```
Host:    minitop            (resolved by: alias 'Mac' -> hosts.minitop)
Profile: personal           state=today  phase=always
Checks:  26 (2 skipped)     Drift: 3 entries

identity
  ✗ ERROR  identity-computer-name    want 'minitop', got 'Mac'
           traces: Q6, #116
           fix:    sudo scutil --set ComputerName minitop
  ⚠ WARN   identity-host-name        not set (allowed; set only for a stable FQDN)
git
  ✓ PASS   gitconfig-no-adobe
  ⊘ SKIP   laptop-battery-health     when.hw_model='MacBook.*', this host is Macmini9,1

drift  (tolerated under --state today; all fail under --state target)
  ● KNOWN  minitop-zle-warning       #129  since 2026-08-15
  ● KNOWN  minitop-libpcap-path      #123  since 2026-08-15
  ✗ ERROR  minitop-vimrc-symlink     UNTRACKED -- no convergence plan

22 passed · 2 failed · 1 warned · 2 skipped · 2 known drift
```

---

## Testing strategy

TDD: the suite is written before the engine. Run via
`uv run --with pytest --with pyyaml --with jsonschema pytest hack/doctor/tests`, exposed as
`make doctor-test`.

Six layers, described innermost-first. **Phase A builds them in a different order** — schema
first, because config loading gates everything else.

**1. Handler unit tests.** One per registered type: passing case, failing case, and the
interesting edge (missing file, non-matching regex, unset hostname, `absent: true` inversion).
Fake runner, `tmp_path` home, zero real subprocesses.

**2. Profile-resolution tests.** The most valuable layer, because the fleet is genuinely
ambiguous:

- `--profile` beats everything, including a contradicting hostname
- `$DOTFILES_DOCTOR_PROFILE` beats the machine-local file
- alias match resolves `Mac` → `minitop`
- **two hosts matching one fingerprint ⇒ exit 3, both candidates named** ← supertop/minitop
- unknown `--profile` ⇒ exit 3 listing valid names
- zero matches ⇒ exit 3, not a silent pass

**3. Schema tests.** The committed `profiles.yaml` validates. Fixtures are each rejected with a
useful message: unknown `type`; duplicate `id` across `common`/`profiles`/`hosts`; bad `phase`; a
`command` check with no `want_*`; **a `drift` entry missing `tracked`/`observed`/`expected`**; and
**a `hosts.<h>.checks` key**, which must be rejected outright as no longer part of the schema.

**4. State-semantics tests.** The `today`/`target` distinction:

- a drift entry whose assertion holds ⇒ `KNOWN` + exit `0` under `--state today`
- the same entry ⇒ `FAIL` + exit `1` under `--state target`
- a drift entry with `tracked` absent ⇒ schema error (layer 3), never a runtime tolerance
- a drift entry whose assertion **stops** holding under `today` ⇒ `FAIL` — the machine moved
- `--phase post --state target` composes: both filters apply

**5. Traceability test — the feedback loop.** Every `traces:` entry matching `^[SMC]\d+$` or
`^Q\d+$` must appear as a defined finding in **either** spec — `S1`–`S7`, `M1`–`M4`, `C1`–`C7`,
`Q1`–`Q8` in `unified-dotfiles-gap-analysis.md`; `Q9`+ in *this* document. The test searches both
and fails on an entry found in neither. Every `tracked:` and `^#\d+$` entry is checked for
**syntactic** validity offline; asserting an issue actually exists needs the network, so that runs
only under `DOCTOR_LIVE=1` via `gh issue view`.

> This is what stops `profiles.yaml` and the specs drifting apart in silence. Rename or delete a
> finding and the suite breaks. Without it, the config slowly becomes folklore.

**6. Live `adobetop` integration test.** Marked `@pytest.mark.live`, skipped unless
`DOCTOR_LIVE=1`. Runs `--profile adobetop --phase always --format json` against the real machine;
every check passes or is on an explicit documented known-failure list. This is what "build it for
the current machine" refers to: the `adobetop` entry is authored against observed reality, not
guessed.

### `make smoke-doctor` — the CI gate (Q13, decided)

No CI runner is in the fleet, so `--phase pre|post` can never assert anything real there. The
smoke test asserts something different and more valuable: **that the script runs at all on a clean
machine.** It follows the repo's existing `make smoke-cuda` / `make smoke-gpu` idiom.

|  | Unit layers 1–6 | `make smoke-doctor` |
|---|---|---|
| Proves | the logic is correct | the script **executes** from scratch |
| Catches | bad regex, bad resolution, broken `traces:` | PEP-723 bootstrap failure, `uv` missing, pyyaml/jsonschema drift, a `profiles.yaml` that parses but won't load |
| Needs | pytest + stubs | a real macOS runner, no fleet host |

Three exit-code assertions, no host resolution required:

```sh
doctor.py --validate                                            # → 0, real profiles.yaml
doctor.py --config tests/fixtures/ci.yaml --profile fake \
          --state target                                        # → 1, known-failing fixture
doctor.py --profile nonesuch                                    # → 3
doctor.py --validate --format json | python3 -m json.tool       # → parseable
```

Runs on **both `macos-14` and `macos-latest`**. The identity probe is the most OS-sensitive code
in the design — `scutil`, `sysctl` and `networksetup` behaviour is exactly what shifts between
macOS releases — so a single-version job would miss the failure this is meant to catch.

---

## Traceability to the unified spec

| Finding | Check(s) | Layer | Phase |
|---|---|---|---|
| S1 gitignore `settings.local.json` | `file_contains` on `~/.gitignore_global` | common | post |
| S2 `init.defaultBranch = main` | `git_config` | common | post |
| S3 `profile` key | `chezmoi_data` + `identity.profile` | common | post |
| S5 `core.editor` | `git_config` | common | post |
| S6 `version_manager = mise` | `chezmoi_data`, `binary` mise, `file_exists` `~/.tool-versions.asdf.bak` | common | post |
| S7 delete `dot_zshrc.local.tmpl` | `file_exists` absent | common | post |
| M1 identity routing | `git_config user.email` + `url.*.insteadOf` across six probe `cwd`s | **profiles.work** | post |
| M2 `hub.host` | `command` on `chezmoi cat ~/.gitconfig`, `not_matching adobe` | **profiles.personal** | post |
| M3 injections | `path_entry` / `binary` — `scout`+`awesome-cli` work, `libpcap` personal | profiles | always |
| M4 `~/.vimrc` | `symlink` target `.vim/.vimrc` + line count | common | post |
| C2 resurrection guard | `command` git diff `--diff-filter=A`, `want_stdout_empty` | common | **pre** |
| C3 `myFzfTabRev` tripwire | `chezmoi_data` `fzf_tab` consistency | common | always |
| C5 remote/`gh` mismatch | `command` comparing `git remote -v` to `gh auth status` | common | **pre** |
| Q6 hostname drift | `hostname` ×3 via `identity.assert` | host | always |
| Testing Strategy §4 | `command` `zsh -i -c exit`, `want_stderr_*` vs baseline | common | always |

The M3 split is instructive: `scout` and `awesome-cli` are *work* tooling and `libpcap` is
*personal*, so these are profile-level, not host-level, even though each was discovered on a single
machine. The unified spec's own conclusion — the modules are existence-gated and therefore inert
where the tool is absent — is what makes that safe.

The `(eval):1: can't change option: zle` warning is **not** in `common`. It is a `drift` entry on
whichever host actually has it, tracked to #129, because the target state is that no machine emits
it.

---

## The prompt issues

Two GitHub issues, one per unsurveyed machine, labelled **`prompt`** (new label: *"Runnable
research/agent prompt; pick up when ready"*), plus `machine:supertop` and `machine:minitop`. The
existing `machine:personal` label stays — nine open issues reference it.

> **Created as `bossjones`, not `malcolm_adobe`.** `gh auth switch --user bossjones` first, switch
> back afterwards. This repo is public and personal; the unified spec's C5 records that the active
> `gh` account on `adobetop` is the Adobe Enterprise Managed User. Git commit identity is already
> correct (`bossjones@theblacktonystark.com` over ssh) — only the `gh` API account needs switching.

Each body is a runnable six-phase prompt. **The ordering is load-bearing.**

```
P0  CONFIRM IDENTITY     Three scutil names, hostname, arch, user, sw_vers, hw.model.
                         Record verbatim. Do NOT assume minitop is mac-mini, or that
                         mac-mini is Mac.scarlettlab.home -- that is the hypothesis
                         under test.

P1  OBSERVE AND SCOUT    Read-only. File-level evidence, not inference.

P2  INTERVIEW  ◄─ gate   Ask the human, one question at a time, for every chezmoi data
                         value. Never infer. Never proceed on a default.

P3  CLASSIFY AND WRITE   For each finding, decide: does this belong in the TARGET state
                         (common/profiles) or is it DRIFT? Write it to the right layer.

P4  VALIDATION LOOP      --validate -> --state today -> --state target -> iterate.
                         Run the test suite.

P5  STOP                 Open a PR. No chezmoi init. No chezmoi apply.
```

### P1 — what to observe

Mirrors the unified spec's evidence categories:

- `git config --list --show-origin`; `includeIf` blocks; resolved `user.email` per probe dir
- `~/.gitignore_global`; `init.defaultBranch`; `core.editor`; `hub.host`; is the `pr` alias used?
- `chezmoi data`, `chezmoi status`, `chezmoi diff --no-pager`, `chezmoi managed`, `chezmoi --version`
- Version manager: `asdf`/`mise` presence, `~/.tool-versions`, the orphaned-tool list
- `~/.vimrc` and `~/.tmux.conf` — regular file, symlink, or absent? `readlink`, not `realpath`.
  On `adobetop` both are symlinks and `~/.tmux.conf`'s target is an **absolute path containing the
  username** — check whether this machine has the same shape or a portable one
- **`~/.ssh/config` verbatim**, plus `/etc/ssh/ssh_config.d/` contents — needed to author the
  shared `Host *` block (Q16). Redact nothing; the comparison needs the real file, but **only
  machine names reach the committed tree**
- Every hostname source: run the full `--identity` command set from
  [the hostname table](#macos-has-three-hostnames-and-one-is-normally-unset)
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

> *"This machine currently has **X**. The other machines in this profile have **Y**. The unified
> spec recommends **Z**, because **W**. Which do you want?"*

only answerable once P1 has established X. Hence P1 → P2, never the reverse.

**The target defaults to steer toward** (decided 2026-08-31 — the interview confirms rather than
discovers these):

| Key | Target | Note |
|---|---|---|
| `version_manager` | `mise` | S6 |
| `fzf_tab` | `false` | Off by default. Must be **present**, not absent — see C1/C3 |
| `profile` | per purpose | `work` for adobetop, `personal` for supertop/minitop |
| `cuda`, `opencv` | `false` | Linux-only concerns (Q8); revisit in the Linux phase |
| `computer_name` / `hostname` | the machine's real name | now consumed by the setter script (Q12) |

Three traps the interview must surface rather than assume:

- **The prompts sit inside `if $interactive`.** A non-TTY `chezmoi init` silently yields
  all-`false` — precisely how the personal machine's config broke. Verify with `chezmoi data`,
  never by exit code. For `fzf_tab` specifically, `--promptBool fzf_tab=true` is consumed *inside*
  the interactive branch, so a non-TTY run needs `CM_fzf_tab=true` in the environment instead
  (`home/.chezmoi.yaml.tmpl:111–121`).
- **Never enable `fzf_tab` by hand-editing `~/.config/chezmoi/chezmoi.yaml`.**
  `plugins.toml.tmpl:135` dereferences `.myFzfTabRev`, which only
  `.chezmoi.yaml.tmpl:147` emits — and `missingkey=error` turns the omission into a failed
  `apply`. Re-running `chezmoi init` regenerates both keys together and is the only safe path.
- **A value that differs from the rest of the profile is a decision, not a fact.** If this machine
  has `pyenv=false` and the other personal machine has `pyenv=true`, the interview must ask which
  is right rather than recording the difference.

### P3 — the classification step

The step that makes this fleet converge rather than fragment. For every finding:

| Question | Destination |
|---|---|
| Should *every* machine satisfy this? | `common.checks` |
| Should *every machine of this profile*? | `profiles.<p>.checks` |
| Is this a deviation we intend to eliminate? | `hosts.<h>.drift` + a tracking issue |
| Is it inherent and permanent (hardware)? | a profile check with a `when:` gate |

The default answer is the **highest** layer that fits. Pushing a finding down to `drift` requires
justifying why it cannot be uniform — and filing the issue that will eventually remove it.

---

## Relationship to the existing script

`hack/doctor/check_dev_environment.py` (698 lines, stdlib-only, hardcoded package lists) is
**untouched**, along with its `Makefile` targets, `README.md`, `QUICKSTART.md`,
`install_missing.sh` and `example_output.txt`.

Different jobs today: it answers *"is my toolchain installed?"*; `doctor.py` answers *"does this
machine match its profile, and where doesn't it?"*

The convergence path — deliberately **not** in scope here — is to move its package inventory into
`common.checks` as `type: brew` / `type: binary` data once `doctor.py` has proven itself, then
retire it. Tracked separately so a large mechanical data migration cannot destabilise the engine
it depends on.

---

## Security and public-repo constraints

`bossjones/zsh-dotfiles` is **public**. Therefore:

- **No private IPs or LAN topology in `profiles.yaml`.** The `~/.ssh/config` survey behind the
  fleet table stays out of the committed tree; only machine *names* are recorded.
- **No secrets, tokens, or key paths.** Checks assert *shape* — that a file exists, that a config
  key resolves to an expected value — never a credential.
- The unified spec's **Q4 is still open**: whether the three `~/.gitconfig-*` files are genuinely
  secret-free before being committed. This spec does not settle it.
- `git.corp.adobe.com` already appears in the committed unified spec. This spec does not widen that
  exposure and does not treat it as licence to add more.

---

## Ordered task list

**Phase A — schema and engine (TDD)**
- [x] `hack/schemas/doctor-profiles.schema.json` (three layers; **no** `hosts.<h>.checks`)
- [x] Test layer 3 (schema) — written first, red
- [x] `doctor.py` skeleton: `Ctx`, `Check`, `Result`, registry, `load`/`validate`, `--validate`
- [x] Test layer 2 (resolution) — red, including the ambiguity case
- [x] `resolve_profile()` — green
- [x] Test layer 4 (state semantics) — red
- [x] Drift evaluation + `--state` — green
- [x] Test layer 1 (handlers) — red, one type at a time
- [x] Handlers — green, one type at a time (incl. `chezmoi_data_complete`)
- [x] `--identity` probe: the 9 real hostname sources (the other 4 in the table above are not
      sources on modern macOS), plus disagreement detection
- [ ] Issue-state lookup for `tracked:` — batched, cached, offline ⇒ `WARN`
- [x] `render()` text + json; exit codes

**Phase B — the `adobetop` profile**
- [x] `profiles.yaml`: `version`, `defaults`, `common.checks`
- [x] `profiles.work` / `profiles.personal` from the unified spec's findings
- [x] `hosts.adobetop` from **observed** state, with any drift tracked
- [x] Test layer 5 (traceability) — green
- [x] Test layer 6 (live) — green, or every failure documented
- [x] `make doctor-test` + `make doctor` + `make smoke-doctor`
- [ ] Wire `smoke-doctor` + layers 1–5 into CI on **both** macOS runners (Q13)

**Phase C — fleet expansion**
- [x] `hosts.supertop` / `hosts.minitop` stubs, identity commented `# HYPOTHESIS`
- [x] Labels `prompt`, `machine:supertop`, `machine:minitop` (as `bossjones`)
- [x] Issue: [#136](https://github.com/bossjones/zsh-dotfiles/issues/136) *survey supertop*
- [x] Issue: [#137](https://github.com/bossjones/zsh-dotfiles/issues/137) *survey minitop*
- [ ] `specs/unified-dotfiles-gap-analysis.md` → **Part 4**; Q9 resolved, Q10–Q13 added

**Phase D — after the surveys return**
- [ ] Merge findings, classified per P3
- [ ] Reconcile any value that differs *within* a profile — the alignment work
- [ ] Author the hostname setter script; correct `computer_name`/`hostname` first (Q12/Q6)
- [ ] Compare the three `~/.ssh/config`s; author `200-zsh-dotfiles.conf` (Q16)
- [ ] Re-run `--state today` on all three; only then does epic #116 Phase 1 start
- [ ] `--state target` becomes the definition of done for #116

---

## Acceptance criteria

- [ ] `./hack/doctor/doctor.py --validate` exits `0`; a corrupted fixture exits `2`
- [ ] On `adobetop`, zero-argument `doctor.py` resolves `adobetop` and exits `0`
- [ ] `--profile nonesuch` exits `3` and lists valid names
- [ ] A fixture with two fingerprint-identical hosts exits `3` naming **both**
- [ ] A config containing `hosts.<h>.checks` is **rejected** by the schema
- [ ] A drift entry without `tracked` is **rejected** by the schema
- [ ] The same drift entry is `KNOWN`/exit `0` under `--state today` and `FAIL`/exit `1` under
      `--state target`
- [ ] Every `traces:` entry resolves to a real finding in either spec (layer 5)
- [ ] `--format json` carries `status`, `traces`, `tracked` and `fix` per check
- [ ] `hostname` checks report `adobetop`'s unset `HostName` as **`WARN`**, never `ERROR`
- [ ] `--identity` reports all three settable names and flags disagreement between them
- [ ] `chezmoi_data_complete` flags `adobetop`'s missing `version_manager`/`fzf_tab`/`profile`
- [ ] Drift whose `tracked:` issue is **closed** fails; offline degrades to `WARN`, never `FAIL`
- [ ] `make smoke-doctor` passes on both `macos-14` and `macos-latest`
- [ ] `profiles.yaml` contains no IP address, credential, or key path
- [ ] `check_dev_environment.py` and every existing `Makefile` target still work unchanged
- [x] Both prompt issues exist, labelled `prompt`, authored by `bossjones` (#136, #137)

---

## Open questions

### Resolved 2026-08-31

| # | Question | Resolution |
|---|---|---|
| **Q9** | Does two-valued `profile` suffice for three machines? | **Yes.** `supertop`+`minitop` both `personal` is intended. Host specialization uses a template conditional, gated on a correct `LocalHostName`. |
| **Q11** | Is `supertop` work or personal? | **`personal`.** |
| **Q12** | Should `HostName` be set fleet-wide? | **Yes, via a templated setter script** driven by the `computer_name`/`hostname` chezmoi data keys. See [the setter script](#the-setter-script-q12). |
| **Q13** | Where does the doctor run in CI? | **As `make smoke-doctor`**, on both macOS runners. See [the CI gate](#make-smoke-doctor--the-ci-gate-q13-decided). |
| **Q14** | Drift sunset policy? | **Tied to GitHub issue state**, not a date. See [Sunset policy](#sunset-policy-q14-decided). |

Carried in from the unified spec and closed by direct measurement on `adobetop`:

| # | Question | Answer |
|---|---|---|
| **Q1** | Work machine's `~/.vimrc`? | Symlink → `.vim/.vimrc`, `~/.vim` a git repo — **same shape as personal**. M4's side-effect risk retired. `~/.vimrc.local` is *absent* here but present on personal. |
| **Q2** | Work machine's `~/.tmux.conf`? | Also an unmanaged symlink, but to `/Users/malcolm/dev/bossjones/oh-my-tmux/.tmux.conf` — **absolute, and contains the username**, so it cannot work on a `bossjones` machine. #125 is wider than "personal only". |
| **Q3** | Is `hub` vestigial? | **No.** On work: `hub` installed, `alias.pr` wired to it, `hub.host = git.corp.adobe.com`. M2's gate-don't-remove is correct. |
| **Q4** | Are the `~/.gitconfig-*` files secret-free? | **Yes — read and confirmed.** 139/135/139 bytes; each is a GitHub username, an email, and a URL rewrite. No tokens or key paths. Safe for a public repo; exposes nothing not already in the committed spec. |
| **Q7** | Is a Linux box in the fleet? | **Yes** (`boss-deeplearning`, Ubuntu), **but out of scope.** macOS alignment first; Linux is a later phase. |
| **Q8** | Was work's `cuda: true` deliberate? | **No — `cuda` is a Linux concern.** Target state is `false` on every macOS host; revisit in the Linux phase. Same for `opencv`. |

### Still open

- **Q10 — Is `minitop` = `mac-mini` = `Mac.scarlettlab.home`?** Two chained assumptions, neither
  verified. If false, the unified spec's entire "personal machine" evidence base belongs to a
  machine not yet identified. `doctor.py --identity` is the instrument; **P0 of the minitop survey
  is the answer.**
- **Q16 — What belongs in the shared `Host *` block?** Cannot be authored from one machine; blocked
  on the two surveys capturing `~/.ssh/config`. See
  [SSH config consolidation](#ssh-config-consolidation).
- **Q15 — RESOLVED.** `vault` re-pins to OSS `2.0.4` (latest; 2.0.0 shipped 2026-04-14). Dropping
  `+ent` and jumping 1.11 → 2.0 are two separate breaking changes — see the unified spec's C4.
- **Q17 — RESOLVED.** `fzf_tab` stays `false` fleet-wide, so nothing exercises the `myFzfTabRev`
  dereference and C3's tripwire remains latent. The doctor asserts the key is **present and
  false**, because *absent* is a different failure with a different fix.

---

## Notes

- **No implementation has been performed.** This document is the design gate.
- **Nothing here mutates a machine.** The doctor is read-only by construction, and the prompt
  issues explicitly forbid `chezmoi init` and `chezmoi apply`.
- **New dependencies: two** (`pyyaml`, `jsonschema`), vendored per-run by `uv`, neither added to
  the repo's Python requirements.
- The fleet reconnaissance behind the machine table came from `~/.ssh/config` on `adobetop` on
  2026-08-31. `supertop` and `mac-mini` were **not** reachable — the work VPN was active — so every
  claim about them is hypothesis pending P0.
