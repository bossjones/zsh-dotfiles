# Plan: Migrate asdf → mise via chezmoi `version_manager` toggle

## Context
The repo currently provisions asdf as the runtime version manager across macOS / Ubuntu / CentOS, with 18 tools pinned by `myAsdf*Version` template vars. The user wants to migrate to mise without immediately deleting asdf — instead, add a chezmoi template variable `version_manager` (values `asdf` | `mise`, default `asdf`) so that a single `chezmoi init` invocation provisions one or the other. CI must run both paths in parallel so we can validate parity before flipping the default.

## Task Description
Introduce a chezmoi-managed `version_manager` toggle that selects between asdf (current default) and mise. When `mise` is selected: skip the asdf install + plugin scripts, run a parallel set of mise install scripts, and switch shell sourcing from `. asdf.sh` to `eval "$(mise activate …)"`. Extend `.github/workflows/tests.yml` so both legs run in parallel on every push.

## Objective
Introduce a `version_manager` template variable, conditionally skip the asdf installer / plugin scripts and emit a parallel set of mise scripts when mise is selected, swap the shell-side asdf sourcing to `mise activate`, and extend `tests.yml` with a `version_manager: [asdf, mise]` matrix axis.

## Problem Statement
asdf v0.11.x is a bash-script implementation that's been superseded by the Go-based asdf v0.16+ and by mise (drop-in replacement, faster, native shim management, reads the same `.tool-versions`). The current repo pins asdf `v0.11.2`. We want a controlled migration that keeps asdf working for existing checkouts (default = `asdf`) while exercising the mise path in CI on every push.

## Solution Approach
1. Single string variable `version_manager` in `home/.chezmoi.yaml.tmpl`, defaulted to `"asdf"`, settable non-interactively via `chezmoi init … --promptString version_manager=mise`.
2. Convert `home/.chezmoiignore` → `home/.chezmoiignore.tmpl` and emit ignore patterns for the *unused* path (asdf scripts when mise selected, mise scripts when asdf selected). Cleanest gate — chezmoi never even renders the ignored scripts.
3. Add three new `run_onchange_before_02-*-install-mise.sh.tmpl` scripts (macOS via brew, Ubuntu/CentOS via `https://mise.run`), plus a single `run_onchange_after_50-mise-install-tools.sh.tmpl` (mise reuses the same `myAsdf*Version` data — mise treats those identifiers as plugin names natively).
4. Make the shell sourcing files (`compat.bash.tmpl`, `compat.sh.tmpl`, `dot_sheldon/plugins.toml.tmpl`, `private_dot_config/sheldon/plugins.toml.tmpl`, the `home/shell/asdf/*.zsh` files referenced by init) branch on `.version_manager`.
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
- `home/dot_sheldon/plugins.toml.tmpl` — wrap the `[plugins.asdf]` blocks (lines 125–141) in `{{ if eq .version_manager "asdf" }}`
- `home/private_dot_config/sheldon/plugins.toml.tmpl` — same
- `home/shell/asdf/env.zsh` — leave intact (sourced only when asdf selected; the `shell/` dir is in `.chezmoiignore` so it stays as-is in the repo)
- `home/shell/customs/aliases.zsh` lines 206–207, 810–829 — `enable_asdf` + kubectl helpers should detect mise (`enable_mise()` sibling; `mise current kubectl` instead of `asdf current kubectl`)
- `.github/workflows/tests.yml` — add matrix axis (line 33–34 area), pass `--promptString version_manager=${{ matrix.version_manager }}` to both `chezmoi init` calls (lines 119, 201), gate asdf-source vs mise-activate steps (lines 155–162, 192–203, 217–222)

### New Files
- `home/.chezmoiscripts/run_onchange_before_02-macos-install-mise.sh.tmpl` — `brew install mise || true`, gated by `{{ if and (eq .chezmoi.os "darwin") (eq .version_manager "mise") }}`
- `home/.chezmoiscripts/run_onchange_before_02-ubuntu-install-mise.sh.tmpl` — `curl https://mise.run | sh`
- `home/.chezmoiscripts/run_onchange_before_02-centos-install-mise.sh.tmpl` — same as ubuntu
- `home/.chezmoiscripts/run_onchange_after_50-mise-install-tools.sh.tmpl` — `mise use -g <tool>@<version>` for each entry in the existing `myAsdf*Version` set; reuses macOS arm64 OpenSSL exports (lines 4–16 of the macOS asdf script)
- `home/shell/mise/env.zsh` — set `MISE_DIR` if needed (mise mostly self-bootstraps via activate)
- `home/shell/mise/path.zsh` — `eval "$(mise activate zsh)"` (consider deferral via sheldon as asdf currently is)

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
- `home/dot_sheldon/plugins.toml.tmpl` (lines 125–141): wrap the `[plugins.asdf]` blocks in `{{ if eq .version_manager "asdf" }}…{{ end }}`. mise activates inline; no sheldon plugin needed for the mise path.
- `home/private_dot_config/sheldon/plugins.toml.tmpl`: same edit (it duplicates the dot_sheldon file).

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

### 9. Verification — Local
- Run `chezmoi data --format=json | jq .version_manager` to confirm the default.
- Run `chezmoi init --promptString version_manager=mise --apply=false --force --source=.` against a scratch destination and inspect `chezmoi diff`.
- Run `chezmoi execute-template < home/.chezmoiignore.tmpl` for both values to confirm correct ignore lists.
- Run `chezmoi cat ~/.config/sheldon/plugins.toml` to ensure no asdf block leaks into the mise rendering.
- Run `chezmoi verify` to confirm all templates parse.

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
- `chezmoi data --format=json | jq .version_manager` — confirm variable resolves
- `chezmoi execute-template < home/.chezmoiignore.tmpl` — render the ignore file (do once per `version_manager` value via `chezmoi execute-template --init` with promptString)
- `chezmoi execute-template < home/compat.bash.tmpl | grep -E 'asdf|mise'` — confirm correct sourcing
- `chezmoi diff` — see all changes against current home dir
- `chezmoi cat ~/.config/sheldon/plugins.toml` — render single file end-to-end
- `chezmoi verify` — syntax-check entire source state
- `chezmoi doctor` — sanity check
- `make test` — run pytest suite locally

For the tightest feedback loop while iterating:
```bash
chezmoi data --format=json | jq .version_manager
chezmoi execute-template < home/compat.bash.tmpl
chezmoi diff
```

## Notes
- **Defaults**: keep `version_manager: "asdf"` for now. Once CI is green for both legs and you've rolled mise on at least one personal machine, flip the default in a follow-up PR.
- **External installer**: `zsh-dotfiles-prereq-installer` (run from `tests.yml` lines 82–84) likely installs asdf today as part of its setup. Confirm whether it does — if yes, the mise CI leg will end up with both managers on PATH. That's harmless (mise's PATH order wins via shim dir) but worth noting; consider adding `ZSH_DOTFILES_PREP_SKIP_ASDF=1` if that env var exists in the prep installer.
- **Version variable naming**: leave `myAsdf*Version` keys alone for now — renaming is a no-op refactor and these names are just identifiers. A follow-up PR can rename to `myTool*Version` once asdf is removed entirely.
- **Custom plugin URLs**: the asdf scripts register 8 custom plugin repos (kubectl, helm, k9s, kubectx, mkcert, opa, helm-docs, kubetail). mise's registry has all of these built in — verify per-tool with `mise registry | grep <tool>` before deleting the custom-repo handling in the mise port.
- **Sheldon**: mise activates via `eval` inline; no sheldon plugin needed. Keep the asdf sheldon plugin entry behind the `version_manager == "asdf"` conditional — don't delete it.
- **No new pip/uv deps required** for this change.
