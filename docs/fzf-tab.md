# fzf-tab: fzf-powered Tab completion

A hands-on guide to enabling, using, and toggling the optional
[fzf-tab](https://github.com/Aloxaf/fzf-tab) integration in these dotfiles.

fzf-tab replaces zsh's built-in completion menu with an fzf selector: press Tab and you
get a fuzzy-filterable list instead of the classic menu. It is **off by default** and
gated behind the chezmoi `fzf_tab` feature flag. With the flag off, your rendered shell
configuration is byte-identical to a checkout without the feature — nothing changes
until you opt in.

## Prerequisites

- `fzf` on your `$PATH` (already provisioned by this repo's install scripts).
  If fzf is missing, fzf-tab is never sourced and stock Tab completion keeps working.
- Optional, for popup rendering: tmux ≥ 3.2.

## 1. Activating fzf-tab

### Option A: make targets (recommended)

The standard `macos-init-good-defaults-*` targets deliberately leave fzf-tab off.
Dedicated targets combine the same good defaults with `fzf_tab=true`:

```bash
# From a local checkout of this repo:
make macos-init-fzf-tab-source

# From GitHub, picking a branch (e.g. to test a feature branch on a VM):
make macos-init-fzf-tab-branch CHEZMOI_BRANCH=feature-fzf-tab

# Fresh machine without chezmoi installed yet:
make macos-init-fzf-tab-oneliner

# Preview only — shows what would change, applies nothing:
make macos-init-fzf-tab-dry-run
```

### Option B: chezmoi directly

```bash
chezmoi init --promptBool fzf_tab=true   # first init (interactive TTY)
chezmoi apply
exec zsh
```

Without a TTY (CI, provisioning scripts), the `fzf_tab` prompt is skipped and defaults
to off; opt in by setting `CM_fzf_tab=true` in the environment instead:

```bash
CM_fzf_tab=true chezmoi init --apply --force --source=.
```

### Verify it took

In a **new** interactive shell (deferred plugins need a first prompt; give it a second):

```bash
bindkey '^I'
# expected: "^I" fzf-tab-complete
```

Then type `cd ~/dev/` and press Tab — you should get an fzf selector with `[directory]`
group headers instead of the stock menu.

## 2. Daily use

| Key | Action |
|-----|--------|
| `Tab` | Open the fzf selector; type to fuzzy-filter |
| `Enter` | Accept the highlighted candidate |
| `F1` / `F2` | Switch between completion groups (files vs. options vs. …) |
| `/` | Continuous trigger: accept current match and immediately re-complete — great for descending directories |
| `Ctrl-Space` | Multi-select several candidates |
| `Esc` / `Ctrl-C` | Dismiss the selector |

Inside tmux ≥ 3.2 the selector renders in a floating tmux popup (`ftb-tmux-popup`);
outside tmux (or on older tmux) it falls back to inline fzf automatically.

**Optional speedup:** completion in very large directories can be accelerated by
compiling fzf-tab's binary module once by hand: run `build-fzf-tab-module`, then restart
zsh. It needs a C toolchain, git, and network, which is why it is deliberately not part
of provisioning.

## 3. Toggling on and off

Three layers, cheapest first. Day-to-day A/B testing should use layers 1–2; chezmoi is
only the install/uninstall boundary.

### Layer 1 — this shell only: `toggle-fzf-tab`

```bash
toggle-fzf-tab      # flip fzf-tab in the current shell
disable-fzf-tab     # one-way off (plugin built-in)
enable-fzf-tab      # one-way on  (plugin built-in)
```

Instant, affects only the shell you typed it in. New shells come up with fzf-tab on.

### Layer 2 — persistent, no chezmoi: `fzf-tab-off` / `fzf-tab-on`

```bash
fzf-tab-off
# fzf-tab disabled (persists across shells; run fzf-tab-on to re-enable)

fzf-tab-on
# fzf-tab enabled
```

`fzf-tab-off` disables the current shell **and** writes a sentinel file at
`${XDG_CONFIG_HOME:-$HOME/.config}/zsh-dotfiles/fzf-tab-disabled`. While the sentinel
exists, new shells never even source fzf-tab — Tab is 100% stock. `fzf-tab-on` removes
the sentinel and (in an already-running shell) re-enables in place; in shells that
started while disabled, run `exec zsh` after `fzf-tab-on`.

Verify either direction with `bindkey '^I'`:
`fzf-tab-complete` means on, `expand-or-complete` means off.

### Layer 3 — full removal: flip the chezmoi flag

Once stored, the flag will **not** be flipped by re-running
`chezmoi init --promptBool fzf_tab=false` — stored keys short-circuit the prompt
(the `hasKey` pattern). Instead:

```bash
# Edit the stored answer:
$EDITOR ~/.config/chezmoi/chezmoi.yaml    # set data.fzf_tab: false
chezmoi apply
exec zsh
```

or re-prompt everything with `chezmoi init --data=false`. This restores the rendered
config byte-identical to a machine that never opted in.

## 4. Troubleshooting

- **Tab does nothing / no selector appears** — check `command -v fzf`. Without fzf on
  `$PATH`, fzf-tab is intentionally never sourced (stock completion keeps working), so
  the selector can't appear.
- **`bindkey '^I'` says `expand-or-complete` right after login** — deferred plugins load
  at the first prompt via zsh-defer; wait a moment and check again. If it persists,
  check for the layer-2 sentinel:
  `ls "${XDG_CONFIG_HOME:-$HOME/.config}/zsh-dotfiles/fzf-tab-disabled"`.
- **No popup inside tmux** — popups need tmux ≥ 3.2 (`tmux -V`); older tmux falls back
  to inline fzf by design.
- **Colors look wrong early in a session** — `LS_COLORS` is populated late (defer-more
  phase) by zsh-dircolors-solarized; the styles evaluate it lazily, so a fresh completion
  after startup settles it.

## 5. How it's wired (for the curious)

- Flag plumbing: `home/.chezmoi.yaml.tmpl` (`fzf_tab`, pinned `myFzfTabRev`).
- Load order: `home/dot_sheldon/plugins.toml.tmpl` and its byte-identical twin
  `home/private_dot_config/sheldon/plugins.toml.tmpl` — when the flag is on, the lane
  `fzf-tab-settings → compinit → fzf-tab` is hoisted ahead of the widget-wrapping
  plugins (zsh-syntax-highlighting, zsh-autosuggestions, fast-syntax-highlighting),
  and fzf-tab is the last plugin to bind `^I`, per fzf-tab's README rules.
- Styles + toggle helpers: `home/shell/fzf-tab/settings.zsh`.
- Guard: the `defer-if-fzf` sheldon template skips sourcing fzf-tab when fzf is missing
  or the layer-2 sentinel exists.
- Runtime signal: `ZSH_DOTFILES_FZF_TAB` exported from `~/.zshrc`.
- Tests: `test_fzf_tab.py` (libtmux; flag-on tests self-skip on flag-off machines).
