# Plan: Migrate asdf → mise via chezmoi `version_manager` toggle

## Context
The repo currently provisions asdf as the runtime version manager across macOS / Ubuntu / CentOS, with 18 tools pinned by `myAsdf*Version` template vars. The user wants to migrate to mise without immediately deleting asdf — instead, add a chezmoi template variable `version_manager` (values `asdf` | `mise`, default `asdf`) so that a single `chezmoi init` invocation provisions one or the other. CI must run both paths in parallel so we can validate parity before flipping the default.

## Task Description
Introduce a chezmoi-managed `version_manager` toggle that selects between asdf (current default) and mise. When `mise` is selected: skip the asdf install + plugin scripts, run a parallel set of mise install scripts, and switch shell sourcing from `. asdf.sh` to `eval "$(mise activate …)"`. Extend `.github/workflows/tests.yml` so both legs run in parallel on every push.

## Objective
Introduce a `version_manager` template variable, conditionally skip the asdf installer / plugin scripts and emit a parallel set of mise scripts when mise is selected, swap the shell-side asdf sourcing to `mise activate`, and extend `tests.yml` with a `version_manager: [asdf, mise]` matrix axis.

## Problem Statement
asdf v0.11.x is a bash-script implementation that's been superseded by the Go-based asdf v0.16+ and by mise (drop-in replacement, faster, native shim management, reads the same `.tool-versions`). The current repo pins asdf `v0.11.2`. We want a controlled migration that keeps asdf working for existing checkouts (default = `asdf`) while exercising the mise path in CI on every push.

## Mutual Exclusion Invariant
**Strict invariant:** when `version_manager=mise`, NOTHING in the rendered shell environment may `eval`, source, or otherwise activate asdf — even if `asdf` happens to be on `$PATH` (e.g., system-installed, prior checkout, or pulled in by `zsh-dotfiles-prereq-installer`). Conversely, when `version_manager=asdf`, NOTHING may `eval` or activate mise — even if `mise` is on `$PATH`. Setting `ASDF_DIR` / `MISE_*` env vars when the corresponding tool isn't selected is also forbidden, since downstream code may assume those vars imply the tool is the active manager.

To enforce this at runtime (where chezmoi templating is unavailable — `home/shell/` is in `.chezmoiignore`, so files under it are read by sheldon directly from the source dir as plain `.zsh`):

1. `home/dot_zshrc.tmpl` exports `ZSH_DOTFILES_VERSION_MANAGER={{ .version_manager | quote }}` immediately after `{{ include "shell/init.zsh" }}` — before sheldon sources any plugin. This makes the value visible to every `home/shell/**/{env,path}.zsh` module.
2. Every shell-module file that activates a version manager OR sets manager-specific env vars MUST guard on `[ "${ZSH_DOTFILES_VERSION_MANAGER:-}" = "<manager>" ]` as the **first** check, before any `command -v` probe. Specifically:
   - `home/shell/mise/path.zsh` runs `eval "$(mise activate zsh)"` only when `ZSH_DOTFILES_VERSION_MANAGER == "mise"` AND `command -v mise` succeeds.
   - `home/shell/asdf/env.zsh` and `home/shell/asdf/path.zsh` set `ASDF_DIR` / completions only when `ZSH_DOTFILES_VERSION_MANAGER == "asdf"`.
3. `home/compat.bash.tmpl` and `home/compat.sh.tmpl` already gate at template-render time via `{{ if eq .version_manager … }}`. That covers bash/sh. Belt-and-suspenders: still export `ZSH_DOTFILES_VERSION_MANAGER` from those files for any sub-shell that re-sources them.
4. `home/shell/customs/aliases.zsh` helpers (`enable_asdf`, kubectl `mise current` / `asdf current`) MUST also guard on `ZSH_DOTFILES_VERSION_MANAGER` — never call `asdf` or `mise` based on `command -v` alone.

**Acceptance for the invariant:** on a host with both `asdf` and `mise` binaries on `$PATH` (simulate via `brew install mise` on an asdf-mode workstation, or vice versa), opening a fresh `zsh` MUST NOT eval the inactive manager. Verify with `typeset -f mise` (should be undefined under asdf mode) and `typeset -f asdf` (should be undefined under mise mode).

## Solution Approach
1. Single string variable `version_manager` in `home/.chezmoi.yaml.tmpl`, defaulted to `"asdf"`, settable non-interactively via `chezmoi init … --promptString version_manager=mise`.
2. Convert `home/.chezmoiignore` → `home/.chezmoiignore.tmpl` and emit ignore patterns for the *unused* path (asdf scripts when mise selected, mise scripts when asdf selected). Cleanest gate — chezmoi never even renders the ignored scripts.
3. Add three new `run_onchange_before_02-*-install-mise.sh.tmpl` scripts (macOS via brew, Ubuntu/CentOS via `https://mise.run`), plus a single `run_onchange_after_50-mise-install-tools.sh.tmpl` (mise reuses the same `myAsdf*Version` data — mise treats those identifiers as plugin names natively).
4. Make the shell sourcing files (`compat.bash.tmpl`, `compat.sh.tmpl`, `dot_sheldon/plugins.toml.tmpl`, `private_dot_config/sheldon/plugins.toml.tmpl`) branch on `.version_manager`. `home/shell/asdf/*.zsh` stays as-is (env vars only — environmentally inert when asdf isn't installed). The new mise activation point lives at `home/shell/mise/{env,path}.zsh`, auto-sourced by sheldon's existing `**/env.zsh` and `**/path.zsh` globs (no per-tool sheldon plugin entry needed).
5. Extend `.github/workflows/tests.yml` with a `version_manager` matrix axis and a conditional asdf-vs-mise activation block in the pytest step.

## Relevant Files
Files to modify:
- `home/.chezmoi.yaml.tmpl` — add `$version_manager` prompt + `version_manager:` data field (lines 4–96, 107–141)
- `home/.chezmoiignore` → rename to `home/.chezmoiignore.tmpl` — add conditional ignore block for the inactive path
- `home/.chezmoiscripts/run_onchange_before_02-ubuntu-install-asdf.sh.tmpl` — wrap in `{{ if eq .version_manager "asdf" }}` (defensive — the ignore is the primary gate)
- `home/.chezmoiscripts/run_onchange_before_02-centos-install-asdf.sh.tmpl` — same
- `home/.chezmoiscripts/run_onchange_after_50-macos-install-asdf-plugins.sh.tmpl` — same
- `home/.chezmoiscripts/run_onchange_after_50-ubuntu-install-asdf-plugins.sh.tmpl` — same
- `home/.chezmoiscripts/run_onchange_after_50-centos-install-asdf-plugins.sh.tmpl` — same
- `home/compat.bash.tmpl` — branch lines 29–33 and 124–127 between asdf source vs. `eval "$(mise activate bash)"`
- `home/compat.sh.tmpl` — branch lines 32–36 and 124–127 the same way
- `home/dot_sheldon/plugins.toml.tmpl` — keep `[plugins.asdf]` gated on `{{ if eq .version_manager "asdf" }}…{{ end }}` (no `else` branch). Remove any inline `[plugins.mise]` block — mise activation moves to `home/shell/mise/path.zsh`, picked up by the existing `[plugins.env]` / `[plugins.path]` globs (lines 30–36).
- `home/private_dot_config/sheldon/plugins.toml.tmpl` — same edit (this file duplicates the dot_sheldon variant)
- `home/shell/asdf/env.zsh` and `home/shell/asdf/path.zsh` — gate every existing block on `[ "${ZSH_DOTFILES_VERSION_MANAGER:-}" = "asdf" ]` as the FIRST check (per the Mutual Exclusion Invariant). Setting `ASDF_DIR` / fpath when mise is the active manager is forbidden.
- `home/dot_zshrc.tmpl` — add `export ZSH_DOTFILES_VERSION_MANAGER={{ .version_manager | quote }}` immediately after the `{{ include "shell/init.zsh" }}` line in BOTH the `darwin` and `linux` branches, before sheldon sources plugins.
- `home/shell/customs/aliases.zsh` lines 206–207, 810–829 — `enable_asdf` + kubectl helpers should detect mise (`enable_mise()` sibling; `mise current kubectl` instead of `asdf current kubectl`)
- `.github/workflows/tests.yml` — add matrix axis (line 33–34 area), pass `--promptString version_manager=${{ matrix.version_manager }}` to both `chezmoi init` calls (lines 119, 201), gate asdf-source vs mise-activate steps (lines 155–162, 192–203, 217–222)

### New Files
- `home/.chezmoiscripts/run_onchange_before_02-macos-install-mise.sh.tmpl` — `brew install mise || true`, gated by `{{ if and (eq .chezmoi.os "darwin") (eq .version_manager "mise") }}`
- `home/.chezmoiscripts/run_onchange_before_02-ubuntu-install-mise.sh.tmpl` — `curl https://mise.run | sh`
- `home/.chezmoiscripts/run_onchange_before_02-centos-install-mise.sh.tmpl` — same as ubuntu
- `home/.chezmoiscripts/run_onchange_after_50-mise-install-tools.sh.tmpl` — `mise use -g <tool>@<version>` for each entry in the existing `myAsdf*Version` set; reuses macOS arm64 OpenSSL exports (lines 4–16 of the macOS asdf script)
- `home/shell/mise/env.zsh` — plain `.zsh` (NOT a chezmoi template). Set any mise-specific env vars (e.g., `MISE_DATA_DIR`) — likely empty for now since mise self-bootstraps via `activate`.
- `home/shell/mise/path.zsh` — plain `.zsh` (NOT a chezmoi template). Body MUST gate on `ZSH_DOTFILES_VERSION_MANAGER` to satisfy the Mutual Exclusion Invariant — never `eval mise activate` based on `command -v mise` alone:
  ```sh
  if [ "${ZSH_DOTFILES_VERSION_MANAGER:-}" = "mise" ] && command -v mise >/dev/null 2>&1; then
      eval "$(mise activate zsh)"
  fi
  ```
  Auto-sourced by sheldon's `[plugins.env]` / `[plugins.path]` globs (lines 30–36 of `dot_sheldon/plugins.toml.tmpl`) — no per-tool sheldon entry required. The env-var check is set by `dot_zshrc.tmpl` before sheldon runs.

## Implementation Phases

### Phase 1: Foundation — Template variable + ignore gating
Add `version_manager` to `.chezmoi.yaml.tmpl`, convert `.chezmoiignore` to a template, and validate end-to-end with `chezmoi data`, `chezmoi diff`, `chezmoi verify` *before* writing any new install scripts. This decouples the toggle from the actual mise work and lets us iterate on the gate alone.

### Phase 2: Core Implementation — Mise installers + tool provisioning
Create the three OS-specific mise install scripts and the unified plugin/tool installer. Cross-validate by running `chezmoi diff` with `version_manager=mise` and inspecting which scripts chezmoi plans to run. Locally run with `chezmoi apply --debug` against a throwaway state directory.

### Phase 3: Integration & Polish — Shell sourcing + CI matrix
Switch the runtime sourcing in `compat.{bash,sh}.tmpl` and the sheldon plugin file. Update `aliases.zsh` (`enable_mise()`, kubectl helper). Extend `tests.yml` with the matrix axis and verify both lanes pass.

## Step by Step Tasks
IMPORTANT: Execute every step in order, top to bottom.

### 1. Add `version_manager` template variable
- Edit `home/.chezmoi.yaml.tmpl`:
  - After line 18, declare `{{- $version_manager := "asdf" -}}`.
  - Inside the `if $interactive` block (around line 96), append a `hasKey . "version_manager"` / `else promptString "Version manager (asdf or mise)" $version_manager` block matching the existing pattern.
  - In the `data:` section (line 107+), add `version_manager: {{ $version_manager | quote }}`.
- Confirm with `chezmoi data --format=json | jq .version_manager` → expects `"asdf"` after first apply, `"mise"` when set.

### 2. Convert `.chezmoiignore` to a template
- `git mv home/.chezmoiignore home/.chezmoiignore.tmpl` (chezmoi recognizes the `.tmpl` extension on ignore files).
- Append a templated block:
  ```
  {{ if eq .version_manager "mise" }}
  .chezmoiscripts/run_onchange_before_02-ubuntu-install-asdf.sh
  .chezmoiscripts/run_onchange_before_02-centos-install-asdf.sh
  .chezmoiscripts/run_onchange_after_50-macos-install-asdf-plugins.sh
  .chezmoiscripts/run_onchange_after_50-ubuntu-install-asdf-plugins.sh
  .chezmoiscripts/run_onchange_after_50-centos-install-asdf-plugins.sh
  {{ else }}
  .chezmoiscripts/run_onchange_before_02-macos-install-mise.sh
  .chezmoiscripts/run_onchange_before_02-ubuntu-install-mise.sh
  .chezmoiscripts/run_onchange_before_02-centos-install-mise.sh
  .chezmoiscripts/run_onchange_after_50-mise-install-tools.sh
  {{ end }}
  ```
  Note: ignore patterns refer to *target* paths (chezmoi strips the `.tmpl` suffix), so list them without `.tmpl`.
- Validate with `chezmoi verify` and `chezmoi diff` for both values of `version_manager`.

### 3. Create mise install scripts (one per OS)
- `home/.chezmoiscripts/run_onchange_before_02-macos-install-mise.sh.tmpl`:
  ```sh
  {{- if and (eq .chezmoi.os "darwin") (eq .version_manager "mise") -}}
  #!/bin/bash
  command -v mise >/dev/null 2>&1 || brew install mise
  {{ end -}}
  ```
- `home/.chezmoiscripts/run_onchange_before_02-ubuntu-install-mise.sh.tmpl` (and the centos sibling):
  ```sh
  {{- if and (eq .chezmoi.os "linux") (eq .version_manager "mise") -}}
  #!/bin/sh
  command -v mise >/dev/null 2>&1 || curl https://mise.run | sh
  {{ end -}}
  ```
  Gate the centos copy on `.chezmoi.osRelease.id` matching the existing pattern from `run_onchange_before_02-centos-install-asdf.sh.tmpl`.

### 4. Create the mise tool-install script
- `home/.chezmoiscripts/run_onchange_after_50-mise-install-tools.sh.tmpl`:
  - Top-level guard: `{{- if eq .version_manager "mise" -}}`.
  - Reuse the macOS arm64 OpenSSL export block from `run_onchange_after_50-macos-install-asdf-plugins.sh.tmpl` (lines 4–16) inside `{{ if eq .chezmoi.os "darwin" }}…{{ end }}`.
  - `eval "$(mise activate bash)"` then iterate over the same `dict` of `myAsdf*Version` entries from the asdf script:
    ```
    {{ range $tool, $ver := $tools -}}
      mise use -g {{ $tool }}@{{ $ver }} || true
    {{ end -}}
    ```
  - Append the ruby gem install loop (foreman, tmuxinator) — same as current asdf script lines 77–84.
  - Note: mise's built-in registry handles `kubectl`, `helm`, `k9s`, `kubectx`, `mkcert`, `opa`, `helm-docs`, `kubetail` natively — no need to register custom plugins like the asdf script does. Verify each is available via `mise registry | grep <tool>` before relying on this.

### 5. Defensive guards inside existing asdf scripts
- Add `{{- if ne .version_manager "asdf" -}}exit 0{{- end -}}` (or wrap the entire body in `{{ if eq .version_manager "asdf" }}…{{ end }}`) at the top of each of the 5 existing asdf scripts. Belt-and-suspenders — the chezmoiignore already excludes them, but this guarantees safety if someone bypasses the ignore.

### 6. Branch shell sourcing on `version_manager`
- `home/compat.bash.tmpl` (lines 29–33, 124–127): wrap existing asdf source block in `{{ if eq .version_manager "asdf" }}…{{ else }}eval "$(mise activate bash)"{{ end }}`.
- `home/compat.sh.tmpl` (lines 32–36, 124–127): same with `mise activate sh`.
- `home/dot_sheldon/plugins.toml.tmpl` (lines 124–146): keep the `[plugins.asdf]` blocks gated on `{{ if eq .version_manager "asdf" }}…{{ end }}` and **delete** the `{{ else }}[plugins.mise]\ninline = '...'\n{{ end }}` branch entirely. Mise activation moves to `home/shell/mise/path.zsh`, which sheldon auto-sources via the existing `[plugins.env]` and `[plugins.path]` globs (lines 30–36).
- `home/private_dot_config/sheldon/plugins.toml.tmpl`: same edit (it duplicates the dot_sheldon file).
- Create `home/shell/mise/env.zsh` and `home/shell/mise/path.zsh` (plain `.zsh`, self-guarded — see "New Files" above).

### 7. Update aliases.zsh
- `home/shell/customs/aliases.zsh` lines 206–207: rename `enable_asdf()` to a generic `enable_version_manager()` that detects which is installed (`command -v mise && eval "$(mise activate zsh)" || . "$HOME/.asdf/asdf.sh"`), or add a parallel `enable_mise()` and leave `enable_asdf()` for backward compat.
- Lines 810–829: update kubectl helpers to prefer `mise current kubectl` when mise is on PATH, falling back to `asdf current kubectl`. Keep the asdf branch for any host still on the asdf path.

### 8. Update CI workflow with matrix axis
- `.github/workflows/tests.yml`:
  - In `strategy.matrix` (around lines 28–34), add `version_manager: [asdf, mise]`.
  - Both `chezmoi init` lines (119, 201): change to
    ```
    retry -t 4 -- "$HOME/.bin/chezmoi" init -R --debug -v --apply --force \
      --promptString version_manager=${{ matrix.version_manager }} --source=.
    ```
  - The asdf-source block (lines 155–162, 192–203, 217–222) needs `if: matrix.version_manager == 'asdf'` and a parallel mise block with `if: matrix.version_manager == 'mise'` that runs `eval "$(mise activate bash)"` and `mise install ruby@3.2.1` (or `mise use -g ruby@3.2.1`) instead of `asdf install ruby 3.2.1`.
  - The `OPENSSL3_PREFIX` exports for arm64 ruby compilation apply identically — keep them outside the conditional.

### 9. Verification — Local (dry-run only on primary workstation)
**Constraint:** never run `chezmoi apply` or `chezmoi init --apply` (with or without a scratch `--destination`) on the user's primary workstation. Stick to render-only / dry-run commands. Real `apply` validation belongs in CI or on a throwaway VM/container.

- Render the ignore template against an in-memory data set:
  ```sh
  chezmoi execute-template --init --promptString version_manager=asdf < home/.chezmoiignore.tmpl
  chezmoi execute-template --init --promptString version_manager=mise < home/.chezmoiignore.tmpl
  ```
  (Note: chezmoi 2.x `execute-template --init` does not auto-process `.chezmoi.yaml.tmpl`; provide `.version_manager` via a small wrapper. If `--init --promptString` doesn't surface the value, prepend the data with `--data` JSON, e.g. `printf '%s' "$(cat home/.chezmoiignore.tmpl)" | chezmoi execute-template --init --promptString version_manager=mise` and verify by piping with explicit data: `echo '{{ .version_manager }}' | chezmoi execute-template --init --promptString version_manager=mise`.)
- Render compat & sheldon files the same way:
  ```sh
  chezmoi execute-template --init --promptString version_manager=mise < home/compat.bash.tmpl | grep -E 'asdf|mise'
  chezmoi execute-template --init --promptString version_manager=asdf < home/dot_sheldon/plugins.toml.tmpl | grep -E 'asdf|mise'
  ```
- `chezmoi diff --dry-run` against the *current* home directory — should show only the diffs introduced by this change with `version_manager` set to whatever is in the current config.
- `chezmoi verify` to syntax-check the entire source state.
- `chezmoi data --format=json | jq .version_manager` to confirm the persisted value.

**Do NOT run** any of the following on the primary workstation: `chezmoi apply`, `chezmoi init --apply`, `chezmoi init --force` against any destination (`$HOME` or scratch). Even with `--apply=false`, `init` writes config files and may pull plugin sources.

### 10. Verification — CI
- Push branch, confirm both `version_manager=asdf` and `version_manager=mise` matrix legs pass on `macos-14` and `macos-latest`.
- Inspect the mise leg's `chezmoi diff` output in the debug logs to confirm asdf install scripts are skipped.

## Testing Strategy
- **Template-level**: For each `.tmpl` modified, run `chezmoi execute-template < file` with both `version_manager=asdf` and `version_manager=mise` and visually confirm the rendered shell is correct.
- **Diff-level**: `chezmoi diff` against a clean home directory for both selections — ensure exactly the right install scripts appear and no orphan asdf references slip through when mise is active.
- **CI integration**: The full pytest suite (`make test`) should pass on both matrix legs; tmux fixtures don't currently depend on a specific manager, so this should be a free win.
- **Regression**: After CI passes for both, run a real `chezmoi apply` on a fresh VM (or via the existing `scripts/smoke-test-docker.sh`) with `--promptString version_manager=mise` and confirm the toolchain (ruby, golang, kubectl, helm, etc.) lands at the pinned versions.

## Acceptance Criteria
- `chezmoi init --promptString version_manager=asdf --apply --force --source=.` produces the same observable system state as before this change (no diff in installed tools).
- `chezmoi init --promptString version_manager=mise --apply --force --source=.` installs mise, provisions every tool currently pinned via `myAsdf*Version`, and writes shell init that uses `mise activate` instead of `asdf.sh`.
- `chezmoi verify` succeeds with both values.
- `.github/workflows/tests.yml` runs both `version_manager` legs in parallel and both green.
- No `asdf` references remain on the rendered output when `version_manager=mise` (verify with `chezmoi cat <file> | grep -i asdf` returning empty for `compat.bash`, `compat.sh`, sheldon `plugins.toml`).

## Validation Commands
**All commands below are read-only / render-only — safe to run on the primary workstation.** Do NOT add `chezmoi apply` or `chezmoi init --apply` to this list.

- `chezmoi data --format=json | jq .version_manager` — confirm variable resolves
- `chezmoi execute-template --init --promptString version_manager=mise < home/.chezmoiignore.tmpl` — render the ignore file (run once per value)
- `chezmoi execute-template --init --promptString version_manager=mise < home/compat.bash.tmpl | grep -E 'asdf|mise'` — confirm correct sourcing
- `chezmoi diff --dry-run` — preview changes against current home dir
- `chezmoi verify` — syntax-check entire source state
- `chezmoi doctor` — sanity check
- `make test` — pytest suite (uses libtmux; doesn't apply chezmoi)

For the tightest feedback loop while iterating (all read-only):
```bash
chezmoi data --format=json | jq .version_manager
chezmoi execute-template --init --promptString version_manager=mise < home/compat.bash.tmpl
chezmoi diff --dry-run
```

For real `chezmoi apply` validation, push the branch and rely on the CI matrix (both `asdf` and `mise` legs run on every push). Or use a throwaway VM / Docker container — never the primary workstation.

## Notes
- **Defaults**: keep `version_manager: "asdf"` for now. Once CI is green for both legs and you've rolled mise on at least one personal machine, flip the default in a follow-up PR.
- **External installer**: `zsh-dotfiles-prereq-installer` (run from `tests.yml` lines 82–84) likely installs asdf today as part of its setup. Confirm whether it does — if yes, the mise CI leg will end up with both managers on PATH. That's harmless (mise's PATH order wins via shim dir) but worth noting; consider adding `ZSH_DOTFILES_PREP_SKIP_ASDF=1` if that env var exists in the prep installer.
- **Version variable naming**: leave `myAsdf*Version` keys alone for now — renaming is a no-op refactor and these names are just identifiers. A follow-up PR can rename to `myTool*Version` once asdf is removed entirely.
- **Custom plugin URLs**: the asdf scripts register 8 custom plugin repos (kubectl, helm, k9s, kubectx, mkcert, opa, helm-docs, kubetail). mise's registry has all of these built in — verify per-tool with `mise registry | grep <tool>` before deleting the custom-repo handling in the mise port.
- **Sheldon**: mise activation lives in `home/shell/mise/path.zsh` (plain `.zsh`, self-guarded with `command -v mise`); sheldon's `[plugins.env]` / `[plugins.path]` blocks (lines 30–36 of `dot_sheldon/plugins.toml.tmpl`) auto-source it. Keep `[plugins.asdf]` gated on `version_manager == "asdf"`, but delete any inline `[plugins.mise]` entry — it's superseded by the shell module.
- **No new pip/uv deps required** for this change.
