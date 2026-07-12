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
- After opting in, switching back to stock completion never requires chezmoi:
  `toggle-fzf-tab` flips the current shell, `fzf-tab-off` / `fzf-tab-on` flip it
  persistently for all future shells via a sentinel file.

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
5. **Runtime toggle layer, so A/B-ing the two completion systems never requires chezmoi.**
   fzf-tab's built-ins (`disable-fzf-tab` / `enable-fzf-tab` / `toggle-fzf-tab`,
   `fzf-tab.zsh:342-476`) give per-session switching — `disable-fzf-tab` rebinds `^I` to
   the saved original widget and unhooks its `compadd`/`_main_complete`/`_approximate`
   patches. On top of that, a sentinel file
   `${XDG_CONFIG_HOME:-$HOME/.config}/zsh-dotfiles/fzf-tab-disabled` plus `fzf-tab-off` /
   `fzf-tab-on` helper functions make the preference persist across shells: the
   `defer-if-fzf` guard skips sourcing fzf-tab entirely when the sentinel exists. The
   chezmoi flag remains the install/uninstall boundary, not the day-to-day A/B switch.

   | Layer | Command | Scope |
   |---|---|---|
   | Per-session | `toggle-fzf-tab` (plugin built-in) | current shell only |
   | Persistent preference | `fzf-tab-off` / `fzf-tab-on` (sentinel-backed) | current + all future shells |
   | Full removal | edit `data.fzf_tab` in `~/.config/chezmoi/chezmoi.yaml`, `chezmoi apply`, `exec zsh` | machine-wide, byte-identical to today |

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
rendered. It is sourced (deferred) immediately before `compinit`. Structure: sentinel
path → styles function → toggle helpers → sentinel early-return → apply styles.

```zsh
#!/usr/bin/env zsh
# fzf-tab configuration and runtime toggle helpers.
#
# Loaded only when the chezmoi `fzf_tab` feature flag is on (see plugins.toml.tmpl).
# Deferred, and registered immediately BEFORE compinit so that `:completion:*` styles
# are in place first, per fzf-tab's README.
#
# Toggle layers (cheapest first):
#   toggle-fzf-tab            plugin built-in, current shell only
#   fzf-tab-off / fzf-tab-on  sentinel-backed, persists across shells, no chezmoi
#   chezmoi flag              edit data.fzf_tab in ~/.config/chezmoi/chezmoi.yaml + apply

_zsh_dotfiles_fzf_tab_sentinel="${XDG_CONFIG_HOME:-$HOME/.config}/zsh-dotfiles/fzf-tab-disabled"

# All styles live in a function so fzf-tab-on can re-apply them after fzf-tab-off
# deleted them.
_zsh_dotfiles_fzf_tab_styles() {
  # --- :completion:* prerequisites ----------------------------------------------
  # Group headers require a descriptions format. fzf-tab strips escape sequences
  # here, so keep it plain (no %F{red}).
  zstyle ':completion:*:descriptions' format '[%d]'

  # fzf-tab supersedes zsh's own menu; `menu no` is what lets it capture the
  # unambiguous prefix (see -ftb-complete's compstate[unambiguous] handling).
  zstyle ':completion:*' menu no

  # LS_COLORS is populated by zsh-dircolors-solarized in the defer-more phase, long
  # after this file is sourced -- so evaluate lazily with `zstyle -e`, not `zstyle`.
  zstyle -e ':completion:*' list-colors 'reply=("${(s.:.)LS_COLORS}")'

  # --- :fzf-tab:* ----------------------------------------------------------------
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

  # tmux popup rendering requires tmux >= 3.2. ftb-tmux-popup already degrades to
  # plain fzf when $TMUX_PANE is unset, so gate on version only, not "am I inside
  # tmux".
  local ftb_tmux_ver
  if command -v tmux >/dev/null 2>&1; then
    ftb_tmux_ver=$(tmux -V 2>/dev/null)
    ftb_tmux_ver=${ftb_tmux_ver#tmux }        # "tmux 3.5a" -> "3.5a"
    ftb_tmux_ver=${ftb_tmux_ver%%[^0-9.]*}    # "3.5a"      -> "3.5"
    autoload -Uz is-at-least
    if [[ -n $ftb_tmux_ver ]] && is-at-least 3.2 $ftb_tmux_ver; then
      zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
      zstyle ':fzf-tab:*' popup-min-size 80 12
      zstyle ':fzf-tab:*' popup-pad 0 0
    fi
  fi
}

# Persistent off-switch: disables the current shell now and, via the sentinel,
# every future shell (defer-if-fzf in plugins.toml skips sourcing fzf-tab).
fzf-tab-off() {
  mkdir -p "${_zsh_dotfiles_fzf_tab_sentinel:h}"
  touch "$_zsh_dotfiles_fzf_tab_sentinel"
  (( $+functions[disable-fzf-tab] )) && disable-fzf-tab
  # Revert the styles this file set, so stock compsys behaves exactly like the
  # flag-off render. (fzf-tab's own disable-fzf-tab already restores list-grouped.)
  zstyle -d ':completion:*:descriptions' format
  zstyle -d ':completion:*' menu
  zstyle -d ':completion:*' list-colors
  print "fzf-tab disabled (persists across shells; run fzf-tab-on to re-enable)"
}

fzf-tab-on() {
  rm -f "$_zsh_dotfiles_fzf_tab_sentinel"
  # enable-fzf-tab only exists if the plugin was sourced; when the sentinel was
  # present at startup, defer-if-fzf skipped it entirely.
  if (( $+functions[enable-fzf-tab] )); then
    _zsh_dotfiles_fzf_tab_styles
    enable-fzf-tab
    print "fzf-tab enabled"
  else
    print "fzf-tab will load in new shells (run: exec zsh)"
  fi
}

# The helpers above are defined unconditionally so a disabled shell can still run
# fzf-tab-on. Styles apply only when the toggle is not off.
[[ -f "$_zsh_dotfiles_fzf_tab_sentinel" ]] && return 0
_zsh_dotfiles_fzf_tab_styles
```

Notes:

- `local` works here because the tmux-version scratch variable now lives inside a
  function (the earlier file-scope `unset` dance is gone).
- `zstyle -d` restores today's state exactly — the repo currently sets **none** of these
  three styles, so deleting them is a faithful revert, not an approximation.
- With the sentinel present at startup this file still loads (it is a plain `defer`
  stanza), but only defines the helpers and returns before touching any zstyle, so stock
  compsys is unpolluted.

### 3. Rework `home/dot_sheldon/plugins.toml.tmpl`

**3a.** In `[templates]` (after line 8), add a guard template so fzf-tab is never sourced
when fzf is missing **or the user has toggled it off persistently** (the `fzf-tab-off`
sentinel from step 2). Both checks are evaluated during `eval "$(sheldon source)"`, by
which point the eager `[plugins.path]` glob has already sourced `home/shell/fzf/path.zsh`.

```gotmpl
{{ if .fzf_tab -}}
defer-if-fzf = { value = 'command -v fzf >/dev/null 2>&1 && [[ ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/zsh-dotfiles/fzf-tab-disabled" ]] && zsh-defer source "{{ "{{ file }}" }}"', each = true }
{{ end -}}
```

The zsh snippet uses only double quotes, so it stays valid inside the TOML single-quoted
literal. With the sentinel present, the disabled state is a true "off" — fzf-tab is never
sourced, not merely loaded-then-disabled. The reordered compinit / zsh-autosuggestions
lanes still render (they're gated on the chezmoi flag, not the sentinel) but are
behaviorally neutral; for a byte-exact stock environment, the flag-off render remains the
gold standard.

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
- `test_fzf_tab_sentinel_skips_sourcing` — skip unless the flag is `true`. Point
  `XDG_CONFIG_HOME` at a pytest `tmp_path` that already contains
  `zsh-dotfiles/fzf-tab-disabled` (spawn with
  `window_shell=f"env XDG_CONFIG_HOME={tmp_path} zsh -i"` so the real `~/.config` is
  never touched); assert `bindkey '^I'` does **not** report `fzf-tab-complete` and
  `whence -w disable-fzf-tab` resolves to nothing (the plugin was never sourced), while
  `whence -w fzf-tab-on` is a function (helpers still defined).
- `test_fzf_tab_off_on_roundtrip` — skip unless the flag is `true`. Spawn with a clean
  tmp `XDG_CONFIG_HOME`; send `fzf-tab-off`, assert `bindkey '^I'` is no longer
  `fzf-tab-complete` and the sentinel file exists under `tmp_path`; send `fzf-tab-on`,
  assert `fzf-tab-complete` is back and the sentinel is gone.
- Mark all five `@pytest.mark.flaky()` and `@pytest.mark.skipif(IN_DOCKER, ...)`, matching
  the existing suite's conventions.

### 7. Validate and document

- Run every command in **Validation Commands** below.
- Add a short "fzf-tab (optional)" section to `README.md` covering:
  - Enabling: `chezmoi init --promptBool fzf_tab=true` (first init) and the default-off
    behavior.
  - Daily use: the F1/F2 group switch, the `/` continuous trigger, Ctrl-Space
    multi-select, and the optional manual `build-fzf-tab-module` speedup.
  - **Switching back — the three toggle layers, in order:**
    1. `toggle-fzf-tab` — instant, current shell only (plugin built-in; `disable-fzf-tab`
       / `enable-fzf-tab` for one-way switches).
    2. `fzf-tab-off` / `fzf-tab-on` — persistent across all new shells, no chezmoi;
       backed by `${XDG_CONFIG_HOME:-$HOME/.config}/zsh-dotfiles/fzf-tab-disabled`.
    3. Full removal — after the first init the flag is stored in
       `~/.config/chezmoi/chezmoi.yaml`, and because of the `hasKey` pattern,
       `chezmoi init --promptBool fzf_tab=false` will **not** flip it. Edit
       `data.fzf_tab: false` in that file, then `chezmoi apply && exec zsh`
       (or `chezmoi init --data=false` to re-prompt everything). This restores the
       byte-identical stock config.

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
- **Sentinel present at startup** — fzf-tab must never be sourced; helpers still defined;
  no fzf-tab zstyles leak into stock compsys.
- **`fzf-tab-off` / `fzf-tab-on` roundtrip** — `^I` and the sentinel file flip together,
  in the same live shell.
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
- [ ] With the flag on and the sentinel file present, a new shell never sources fzf-tab:
      `bindkey '^I'` is stock, `disable-fzf-tab` is undefined, and none of the three
      `:completion:*` styles from `settings.zsh` are set — but `fzf-tab-on` is defined.
- [ ] `fzf-tab-off` in a live shell restores the pre-fzf-tab `^I` widget, deletes the
      three zstyles it set, and creates the sentinel; `fzf-tab-on` reverses all of it
      in-place without a shell restart.
- [ ] `README.md` documents all three toggle layers, including the
      `~/.config/chezmoi/chezmoi.yaml` flip path (and why `--promptBool` alone can't
      flip an already-stored flag).
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

# 7. Runtime toggle roundtrip (flag on). XDG_CONFIG_HOME points at a temp dir so the
#    real ~/.config is untouched; deferred plugins need a zle prompt, hence tmux.
tmpcfg=$(mktemp -d)
tmux new-session -d -s fzftab-toggle "env XDG_CONFIG_HOME=$tmpcfg zsh -i"
sleep 3
tmux send-keys -t fzftab-toggle "fzf-tab-off; bindkey '^I'" Enter
sleep 1
tmux capture-pane -p -t fzftab-toggle | tail -3        # expect: NOT fzf-tab-complete
ls "$tmpcfg/zsh-dotfiles/fzf-tab-disabled"             # expect: sentinel exists
tmux send-keys -t fzftab-toggle "fzf-tab-on; bindkey '^I'" Enter
sleep 1
tmux capture-pane -p -t fzftab-toggle | tail -3        # expect: fzf-tab-complete
ls "$tmpcfg/zsh-dotfiles/fzf-tab-disabled" 2>&1        # expect: No such file
tmux kill-session -t fzftab-toggle
rm -rf "$tmpcfg"

# 8. Full suite.
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
- **Flipping the flag after the first init is not `--promptBool`.** The `hasKey` pattern
  means once `fzf_tab` is stored in `~/.config/chezmoi/chezmoi.yaml`, re-running
  `chezmoi init --promptBool fzf_tab=…` is a no-op (hasKey short-circuits the prompt).
  Edit `data.fzf_tab` in that file and `chezmoi apply`, or `chezmoi init --data=false` to
  re-prompt everything. This is also why the runtime toggle layer exists: day-to-day A/B
  between fzf-tab and stock completion should use `toggle-fzf-tab` (per shell) or
  `fzf-tab-off` / `fzf-tab-on` (persistent), never a chezmoi round-trip.
- **Bumping the pin** later means updating `myFzfTabRev` in `home/.chezmoi.yaml.tmpl` and
  running `sheldon lock --update`.
