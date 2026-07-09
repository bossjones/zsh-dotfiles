# Plan: Integrate fzf-tab as a chezmoi feature-flagged option

## Task Description

Integrate [`Aloxaf/fzf-tab`](https://github.com/Aloxaf/fzf-tab) — which replaces zsh's
completion menu with an fzf selector — into this dotfiles repo as an **opt-in feature**,
gated behind a chezmoi feature flag. The plugin source under review is the local checkout
at `~/dev/fzf-tab` (currently `v1.3.0-3-g24105b1`).

The flag defaults to **off**. When off, the rendered shell configuration must be
byte-identical to what it is today — no startup-order changes, no new plugins, no new
zstyles. Users opt in with `chezmoi init --promptBool fzf_tab=true`.

## Objective

- `chezmoi init --promptBool fzf_tab=true` enables fzf-tab; the default, and every existing
  machine, stays on stock zsh completion with zero rendered-config drift.
- With the flag on, `bindkey '^I'` reports `fzf-tab-complete` in a real interactive shell,
  and fzf-tab loads after `compinit` and before all widget-wrapping plugins.
- With fzf absent from `$PATH`, fzf-tab is not sourced at all, so Tab keeps working.

## Problem Statement

This repo already anticipated fzf-tab: `home/dot_sheldon/plugins.toml.tmpl` lines 167-169
carry a commented-out `[plugins.fzf-tab]` stub. It was never enabled — and simply
uncommenting it would not work correctly, because fzf-tab's load-order rules conflict with
the current sheldon ordering.

### Reality check (confirmed by reading the source)

1. **fzf-tab's hard rules** (`~/dev/fzf-tab/README.md` lines 33-37):
   - fzf must be installed. There is no graceful fallback — `-ftb-fzf` execs `fzf`
     directly (`lib/-ftb-fzf:81`); if it's missing, Tab silently does nothing.
   - fzf-tab must load **after `compinit`**, but **before plugins that wrap widgets**
     (zsh-autosuggestions, zsh-syntax-highlighting, fast-syntax-highlighting).
     `enable-fzf-tab` copies the original `^I` widget with `zle -A` before wrapping
     (`fzf-tab.zsh:389`), and exposes `fzf-tab-dummy` (`fzf-tab.zsh:333`) precisely so
     f-sy-h has something to wrap.
   - It must be the **last plugin to bind `^I`**.
   - `:completion:*` styles should be configured before `compinit`.

2. **The current sheldon order is wrong for fzf-tab.** In `home/dot_sheldon/plugins.toml.tmpl`:
   - `[plugins.zsh-syntax-highlighting]` line 112 — `defer`
   - `[plugins.zsh-autosuggestions]` line 116 — **eager** (no `apply`)
   - `[plugins.fast-syntax-highlighting]` line 151 — `defer-more` (`zsh-defer -t 0.5`)
   - `[plugins.compinit]` line 163 — `defer`, sources `home/shell/compinit.zsh`
     (the real call is `compinit -u -C -d "${ZSH_COMPDUMP}"` at `compinit.zsh:56`)

   zsh-defer runs `defer` entries in registration order, then `defer-more` entries ~0.5s
   later. So today `compinit` runs *after* zsh-syntax-highlighting, and zsh-autosuggestions
   (eager) runs before every deferred plugin. Dropping fzf-tab into the existing stub
   position satisfies "after compinit" but violates "before widget wrappers" twice.

3. **`^I` is already safe.** The only other `^I` binders load eagerly: `[plugins.boss_fzf]`
   inline `source ~/.fzf.zsh` (lines 200-208) and `home/dot_zshrc.tmpl:19`. Both run during
   `eval "$(sheldon source)"`, before any deferred plugin. A deferred fzf-tab is therefore
   automatically last. `home/shell/fzf/completion.zsh:18` has its source line commented out.

4. **There are TWO identical sheldon templates**, byte-for-byte:
   - `home/dot_sheldon/plugins.toml.tmpl` → `~/.sheldon/plugins.toml`
   - `home/private_dot_config/sheldon/plugins.toml.tmpl` → `~/.config/sheldon/plugins.toml`

   Which one sheldon reads is genuinely ambiguous: `SHELDON_CONFIG_DIR` is exported from
   `home/shell/env.zsh:30`, but env.zsh is itself loaded *by* sheldon. On a fresh shell the
   variable is unset when `eval "$(sheldon source)"` runs, so sheldon falls back to
   `$XDG_CONFIG_HOME/sheldon`. **Both files must be edited identically.**

5. **No conflicting completion zstyles.** The only active one in the whole tree is
   `home/shell/config.zsh:53` (`matcher-list`). There is no `menu select` / `menu yes`
   anywhere — a clean slate. `setopt AUTO_MENU` (`home/dot_zshrc.local.tmpl:57`) is inert
   once fzf-tab owns `^I`.

6. **`home/shell/**` is not templated.** `home/.chezmoiignore.tmpl:1` ignores `shell`;
   sheldon reads those files straight from the chezmoi *source* checkout
   (`~/.local/share/chezmoi/home/shell`). So a new file there is visible regardless of any
   chezmoi flag, and cannot contain Go template syntax. Feature gating must live in
   `plugins.toml.tmpl`, and the new file must not match any existing sheldon glob
   (`**/env.zsh`, `**/path.zsh`, `**/aliases.zsh`, `**/{keybinding,completion}.zsh`,
   top-level `config.zsh`).

7. **The feature-flag pattern is already established.** `home/.chezmoi.yaml.tmpl` declares
   defaults, prompts via `hasKey` + `promptBool`/`promptString`, and emits into `data:`.
   Note lines 102-107: `version_manager` deliberately sits **outside** the `if $interactive`
   guard so non-TTY `chezmoi init --promptString version_manager=…` works in the Docker
   smoke path.

## Solution Approach

**Gated reorder.** When `fzf_tab=true`, the template hoists `compinit` + fzf-tab above the
highlighters and defers zsh-autosuggestions so it loads after fzf-tab. When `fzf_tab=false`,
`plugins.toml` renders **byte-identical to today**. This honors fzf-tab's README exactly
while keeping the blast radius at zero for anyone who doesn't opt in.

Supporting decisions:

1. **No binary module.** `build-fzf-tab-module` clones the full zsh source and compiles it.
   fzf-tab falls back to the bundled pure-zsh `lib/zsh-ls-colors` automatically
   (`fzf-tab.zsh:547`). Document the command; don't wire it into provisioning.
2. **Pin to `rev = "24105b15714bfec37989ed5c5b6e60f572253019"`** (= `v1.3.0-3-g24105b1`, the
   commit checked out at `~/dev/fzf-tab`), stored as a `myFzfTabRev` data key alongside
   `myFzfVersion` / `mySheldonVersion`.
3. **tmux popup enabled when available**, guarded by a runtime `tmux >= 3.2` check.
   `ftb-tmux-popup` already falls back to plain `fzf` outside tmux
   (`lib/ftb-tmux-popup:19-22`).
4. **Guard against missing fzf** with a custom sheldon `defer-if-fzf` template, so the
   plugin is never sourced on a box without fzf.

## Relevant Files

- `home/.chezmoi.yaml.tmpl` — add the `$fzf_tab` default, the prompt block, and `fzf_tab` +
  `myFzfTabRev` in `data:`. Mirror the `version_manager` placement (lines 102-107) so the
  prompt lives **outside** `if $interactive` and non-TTY `--promptBool` works.
- `home/dot_sheldon/plugins.toml.tmpl` — the gated reorder plus the new plugin stanzas.
- `home/private_dot_config/sheldon/plugins.toml.tmpl` — **identical** edit; keep in sync.
- `home/dot_zshrc.tmpl` — export `ZSH_DOTFILES_FZF_TAB` in both the darwin (line 9) and
  linux (line 32) branches, next to the existing `ZSH_DOTFILES_VERSION_MANAGER`.
- `README.md` — short "fzf-tab (optional)" section.

### New Files

- `home/shell/fzf-tab/settings.zsh` — plain zsh (no templating); holds the `:completion:*`
  prerequisites and the `:fzf-tab:*` styles. The filename is chosen so it matches **no**
  existing sheldon glob; it is loaded only by an explicitly gated stanza.
- `test_fzf_tab.py` — libtmux test, mirroring `test_dotfiles.py::TestDotfiles::test_aliases`.

### Patterns to reuse

- Flag plumbing: `home/.chezmoi.yaml.tmpl` lines 102-107 (`version_manager`).
- Template guard: `{{ if eq .version_manager "asdf" -}}` at `plugins.toml.tmpl:124`.
- Runtime signal: `export ZSH_DOTFILES_VERSION_MANAGER=…` at `dot_zshrc.tmpl:9`.
- tmux test harness: `test_dotfiles.py` fixtures `tmux_fake_session` and
  `zsh_output_subprocess`; markers `@pytest.mark.flaky()`, `@pytest.mark.skipif(IN_DOCKER, …)`.
- Version pinning as data keys: `myFzfVersion`, `mySheldonVersion`.

### Files explicitly NOT touched

`home/shell/config.zsh`, `home/shell/compinit.zsh`, `home/shell/fzf/*`,
`home/dot_zshrc.local.tmpl`, `home/.chezmoiignore.tmpl`, any `.chezmoiscripts/` file.

## Implementation Phases

### Phase 1: Foundation

Snapshot the flag-off render as a regression oracle, then add the `fzf_tab` flag and the
`myFzfTabRev` pin to `home/.chezmoi.yaml.tmpl`. Nothing observable changes yet.

### Phase 2: Core Implementation

Write `home/shell/fzf-tab/settings.zsh`, then perform the gated reorder in both
`plugins.toml.tmpl` files and export the runtime signal from `dot_zshrc.tmpl`.

### Phase 3: Integration & Polish

Add `test_fzf_tab.py`, run the full validation suite (byte-identity diff, template-sync
diff, live tmux check, fzf-missing fallback), and document the feature in `README.md`.

## Step by Step Tasks

IMPORTANT: Execute every step in order, top to bottom.

### 0. Capture the flag-off baseline

- Before touching anything, snapshot the rendered sheldon config:
  `chezmoi cat ~/.sheldon/plugins.toml > /tmp/plugins.before.toml`
- This is the regression oracle for the "byte-identical when off" criterion.

### 1. Add the `fzf_tab` flag to `home/.chezmoi.yaml.tmpl`

- Next to the other boolean defaults (after `{{- $cuda := false -}}`, line 18):
  ```gotmpl
  {{/* If this machine should use fzf-tab completion */}}
  {{- $fzf_tab := false -}}
  ```
- Add the prompt block **outside** `if $interactive`, immediately after the
  `version_manager` block (line 107), with a comment explaining why:
  ```gotmpl
  {{- /* fzf_tab: kept outside `if $interactive` so non-TTY `--promptBool fzf_tab=…`
         (Docker smoke / CI) matches. In non-TTY runs promptBool returns the
         --promptBool value or the default. */ -}}
  {{- if hasKey . "fzf_tab" -}}
  {{-   $fzf_tab = .fzf_tab -}}
  {{- else -}}
  {{-   $fzf_tab = promptBool "fzf_tab" $fzf_tab -}}
  {{- end -}}
  ```
- In `data:`, after `version_manager` (line 129):
  ```yaml
    fzf_tab: {{ $fzf_tab }}
  ```
- And alongside the pinned versions, after `myFzfVersion` (line 130):
  ```yaml
    myFzfTabRev: "24105b15714bfec37989ed5c5b6e60f572253019"
  ```

### 2. Create `home/shell/fzf-tab/settings.zsh`

Plain zsh — **no Go template syntax**; this file is read from the source checkout, not
rendered. It is sourced (deferred) immediately before `compinit`.

```zsh
#!/usr/bin/env zsh
# fzf-tab configuration.
#
# Loaded only when the chezmoi `fzf_tab` feature flag is on (see plugins.toml.tmpl).
# Deferred, and registered immediately BEFORE compinit so that `:completion:*` styles
# are in place first, per fzf-tab's README.

# --- :completion:* prerequisites ------------------------------------------------
# Group headers require a descriptions format. fzf-tab strips escape sequences here,
# so keep it plain (no %F{red}).
zstyle ':completion:*:descriptions' format '[%d]'

# fzf-tab supersedes zsh's own menu; `menu no` is what lets it capture the
# unambiguous prefix (see -ftb-complete's compstate[unambiguous] handling).
zstyle ':completion:*' menu no

# LS_COLORS is populated by zsh-dircolors-solarized in the defer-more phase, long
# after this file is sourced -- so evaluate lazily with `zstyle -e`, not `zstyle`.
zstyle -e ':completion:*' list-colors 'reply=("${(s.:.)LS_COLORS}")'

# --- :fzf-tab:* -----------------------------------------------------------------
zstyle ':fzf-tab:*' show-group full
zstyle ':fzf-tab:*' single-group color header
zstyle ':fzf-tab:*' continuous-trigger '/'
zstyle ':fzf-tab:*' switch-group F1 F2
zstyle ':fzf-tab:*' fzf-min-height 15
zstyle ':fzf-tab:*' fzf-pad 4

# Directory previews. eza when present, BSD/GNU-portable ls otherwise.
if command -v eza >/dev/null 2>&1; then
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
else
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 $realpath'
fi

# tmux popup rendering requires tmux >= 3.2. ftb-tmux-popup already degrades to plain
# fzf when $TMUX_PANE is unset, so gate on version only, not on "am I inside tmux".
if command -v tmux >/dev/null 2>&1; then
  _ftb_tmux_ver=$(tmux -V 2>/dev/null)
  _ftb_tmux_ver=${_ftb_tmux_ver#tmux }        # "tmux 3.5a" -> "3.5a"
  _ftb_tmux_ver=${_ftb_tmux_ver%%[^0-9.]*}    # "3.5a"      -> "3.5"
  autoload -Uz is-at-least
  if [[ -n $_ftb_tmux_ver ]] && is-at-least 3.2 $_ftb_tmux_ver; then
    zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
    zstyle ':fzf-tab:*' popup-min-size 80 12
    zstyle ':fzf-tab:*' popup-pad 0 0
  fi
  unset _ftb_tmux_ver
fi
```

Note: `local` is not usable at file scope in zsh — hence the plain variable plus `unset`.

### 3. Rework `home/dot_sheldon/plugins.toml.tmpl`

**3a.** In `[templates]` (after line 8), add a guard template so fzf-tab is never sourced
when fzf is missing. `command -v fzf` is evaluated during `eval "$(sheldon source)"`, by
which point the eager `[plugins.path]` glob has already sourced `home/shell/fzf/path.zsh`.

```gotmpl
{{ if .fzf_tab -}}
defer-if-fzf = { value = 'command -v fzf >/dev/null 2>&1 && zsh-defer source "{{ "{{ file }}" }}"', each = true }
{{ end -}}
```

**3b.** Immediately **before** `[plugins.zsh-syntax-highlighting]` (currently line 112),
insert the gated fzf-tab lane:

```gotmpl
{{ if .fzf_tab -}}
###################
# fzf-tab lane: styles -> compinit -> fzf-tab, all ahead of the widget wrappers.
# fzf-tab must load after compinit but before zsh-autosuggestions /
# zsh-syntax-highlighting / fast-syntax-highlighting, and must be the last
# plugin to bind ^I (the eager `boss_fzf` inline binding runs first).
###################
[plugins.fzf-tab-settings]
local = "~/.local/share/chezmoi/home/shell/fzf-tab"
use = ["settings.zsh"]
apply = ["defer"]

[plugins.compinit]
local = "~/.local/share/chezmoi/home/shell"
apply = ["defer"]

[plugins.fzf-tab]
github = "Aloxaf/fzf-tab"
rev = "{{ .myFzfTabRev }}"
apply = ["defer-if-fzf"]
{{ end -}}
```

**3c.** Give `[plugins.zsh-autosuggestions]` (line 116) a conditional `apply` so it loads
after fzf-tab when the flag is on, and stays eager when it is off:

```gotmpl
[plugins.zsh-autosuggestions]
github = "zsh-users/zsh-autosuggestions"
use = ["{{- "{{ name }}.zsh" }}"]
{{ if .fzf_tab }}apply = ["defer"]
{{ end -}}
```

**3d.** At the original `[plugins.compinit]` site (lines 163-165), gate the stanza so it
only renders when the flag is off, and delete the commented stub at lines 167-169:

```gotmpl
{{ if not .fzf_tab -}}
[plugins.compinit]
local = "~/.local/share/chezmoi/home/shell"
apply = ["defer"]
{{ end -}}
```

Whitespace matters: the flag-off render must match `/tmp/plugins.before.toml` exactly.
Tune the `{{-` / `-}}` trim markers until `diff` is clean (verified in step 7).

### 4. Mirror the edit into `home/private_dot_config/sheldon/plugins.toml.tmpl`

- Apply the identical change. The two files must remain byte-for-byte identical; a `diff`
  check is added to validation and should be considered for `.pre-commit-config.yaml`.

### 5. Export the runtime signal in `home/dot_zshrc.tmpl`

- In **both** the darwin branch (after line 9) and the linux branch (after line 32):
  ```gotmpl
  export ZSH_DOTFILES_FZF_TAB={{ .fzf_tab }}
  ```
- This gives tests and any future shell code a first-class signal, mirroring
  `ZSH_DOTFILES_VERSION_MANAGER`.

### 6. Add `test_fzf_tab.py`

Deferred plugins only run at the first zle prompt, so `zsh -i -c` cannot observe them —
the assertion must go through tmux. Follow `test_dotfiles.py::test_aliases`.

- `test_fzf_tab_binds_tab` — skip unless `os.environ.get("ZSH_DOTFILES_FZF_TAB") == "true"`;
  spawn `tmux_fake_session.new_window(window_shell="zsh -i")`, sleep ~3s for the defer
  queue to drain, send `bindkey '^I'`, `capture_pane()`, assert `fzf-tab-complete` in the output.
- `test_fzf_tab_loads_after_compinit` — assert `whence -w _fzf-tab-apply` resolves, which
  only happens once fzf-tab has sourced against a live compsys.
- `test_fzf_tab_absent_when_disabled` — skip unless the flag is `false`; assert
  `bindkey '^I'` does **not** contain `fzf-tab-complete`.
- Mark all three `@pytest.mark.flaky()` and `@pytest.mark.skipif(IN_DOCKER, ...)`, matching
  the existing suite's conventions.

### 7. Validate and document

- Run every command in **Validation Commands** below.
- Add a short "fzf-tab (optional)" section to `README.md` covering:
  `chezmoi init --promptBool fzf_tab=true`, the default-off behavior, the F1/F2 group
  switch, the `/` continuous trigger, Ctrl-Space multi-select, `toggle-fzf-tab`, and the
  optional manual `build-fzf-tab-module` speedup.

## Testing Strategy

Three layers, cheapest first:

1. **Offline template rendering** (deterministic, no network, no `apply`). Proves the flag
   plumbs through and that the flag-off output is unchanged. This is the primary gate.
2. **libtmux integration** (`test_fzf_tab.py`). The only way to observe a `zsh-defer`red
   plugin, since the defer queue drains at the first zle prompt.
3. **Manual smoke** on the workstation: open a new shell, press Tab on `cd ~/dev/`, confirm
   an fzf popup with `[directory]` group headers; press F1/F2; press `/` to descend.

Edge cases the tests must cover:

- **fzf missing from `$PATH`** — the `defer-if-fzf` template must skip sourcing, leaving
  stock Tab completion intact. Verify with `PATH=/usr/bin:/bin zsh -i`.
- **Flag off** — `plugins.toml` renders byte-identical; `bindkey '^I'` is not fzf-tab.
- **tmux < 3.2, or no tmux** — `fzf-command` stays unset and fzf renders inline.
- **`LS_COLORS` set late** — `zstyle -e` defers evaluation past zsh-dircolors-solarized.
- **Both sheldon templates in sync** — enforced by `diff`.

## Acceptance Criteria

- [ ] `chezmoi cat ~/.sheldon/plugins.toml` with `fzf_tab: false` is **byte-identical** to
      the pre-change snapshot.
- [ ] `home/dot_sheldon/plugins.toml.tmpl` and
      `home/private_dot_config/sheldon/plugins.toml.tmpl` are byte-identical.
- [ ] Rendering `.chezmoi.yaml.tmpl` with `--promptBool fzf_tab=true` emits `fzf_tab: true`;
      the default (no flag, non-TTY) emits `fzf_tab: false`.
- [ ] With the flag on, the rendered `plugins.toml` orders stanzas:
      `fzf-tab-settings` → `compinit` → `fzf-tab` → `zsh-syntax-highlighting` →
      `zsh-autosuggestions` (deferred) → `fast-syntax-highlighting`.
- [ ] With the flag on, `[plugins.compinit]` appears exactly once.
- [ ] `chezmoi doctor` reports no template errors.
- [ ] In a live shell with the flag on, `bindkey '^I'` → `fzf-tab-complete`.
- [ ] With fzf removed from `$PATH`, fzf-tab is not sourced and Tab still completes.
- [ ] `make test` passes.

## Validation Commands

> **This workstation is dry-run only. Never run `chezmoi apply` or `chezmoi init --apply`
> here** — every command below is read-only or `--dry-run`.

```bash
# 0. Templates parse; no chezmoi config errors.
chezmoi doctor

# 1. Both sheldon templates stayed in sync.
diff home/dot_sheldon/plugins.toml.tmpl home/private_dot_config/sheldon/plugins.toml.tmpl \
  && echo "OK: sheldon templates in sync"

# 2. The flag plumbs into `data:` in both directions (non-TTY, so promptBool takes the flag).
chezmoi execute-template --init --promptBool fzf_tab=true  < home/.chezmoi.yaml.tmpl | grep -E '^\s+fzf_tab: true'
chezmoi execute-template --init                            < home/.chezmoi.yaml.tmpl | grep -E '^\s+fzf_tab: false'

# 3. REGRESSION GATE: with the flag off, the rendered sheldon config is unchanged.
#    /tmp/plugins.before.toml was captured in Step 0, before any edits.
chezmoi cat ~/.sheldon/plugins.toml > /tmp/plugins.after.toml
diff /tmp/plugins.before.toml /tmp/plugins.after.toml \
  && echo "OK: flag-off render is byte-identical"

# 4. With the flag on, confirm the data renders and inspect the plugin order.
chezmoi init --dry-run --promptBool fzf_tab=true --promptString version_manager=asdf
grep -n '^\[plugins\.' /tmp/plugins.after.toml

# 5. Live behavior (flag on, real interactive shell; deferred plugins need a zle prompt).
tmux new-session -d -s fzftab-check 'zsh -i'
sleep 3
tmux send-keys -t fzftab-check "bindkey '^I'" Enter
sleep 1
tmux capture-pane -p -t fzftab-check | grep fzf-tab-complete
tmux kill-session -t fzftab-check

# 6. fzf-missing fallback: fzf-tab must not be sourced, Tab must still work.
env -i HOME="$HOME" PATH=/usr/bin:/bin zsh -i -c 'bindkey "^I"' | grep -v fzf-tab-complete

# 7. Full suite.
make test
```

## Notes

- **`chezmoi apply` is forbidden on this workstation** (dry-run only). Validation step 3's
  regression gate uses `chezmoi cat`, which renders a target without writing it.
- **The two-template duplication is the biggest footgun here.** Because
  `SHELDON_CONFIG_DIR` is exported from a file that sheldon itself sources, you cannot
  reason locally about which `plugins.toml` wins on a cold shell. Consider adding the
  `diff` from validation step 1 to `.pre-commit-config.yaml` as a permanent guard — that is
  arguably worth a follow-up issue independent of fzf-tab.
- **No new Python or system dependencies.** sheldon clones fzf-tab itself; fzf is already
  installed (`myFzfVersion: "0.73.1"`, `run_onchange_before_02-linux-install-fzf.sh.tmpl`).
- **The binary module is deliberately out of scope.** If completion in very large
  directories feels slow, run `build-fzf-tab-module` once by hand and restart zsh; fzf-tab
  picks it up automatically (`fzf-tab.zsh:530-547`). It clones the full zsh source matching
  `$ZSH_VERSION` and compiles it, so it needs a C toolchain, git, and network — not
  something to put in the provisioning path.
- **`setopt AUTO_MENU`** (`home/dot_zshrc.local.tmpl:57`, darwin/arm64 only) becomes inert
  once fzf-tab owns `^I`. Left in place; harmless.
- **Bumping the pin** later means updating `myFzfTabRev` in `home/.chezmoi.yaml.tmpl` and
  running `sheldon lock --update`.
