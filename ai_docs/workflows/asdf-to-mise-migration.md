# asdf → mise Migration Plan

**Status:** plan only. The current branch (`feature-asdf-to-mise`) exists for this migration but no implementation has landed yet. This doc inventories the asdf footprint, lists tools to migrate, and lays out the order of operations. The actual `mise.toml`, chezmoi script bodies, and shell-wiring diffs are out of scope here — they belong in the implementation session.

Background: [mise_overview.md](../reports/mise_overview.md) · [mise_configuration.md](../reports/mise_configuration.md)

## Why migrate

- **Performance:** asdf's shim layer adds ~120ms per binary invocation. mise's `PATH`-activation hook adds ~5–10ms only on `cd`. Concretely: every `git`, `kubectl`, `helm` invocation in this repo's shell pays the asdf shim tax today.
- **Security:** asdf plugins are third-party scripts; mise's `core`/`aqua`/`ubi` backends pull from curated sources with attestation/SLSA verification by default.
- **Surface area:** mise replaces three things this repo currently juggles separately — version manager (asdf), env-var loader (custom shell), task runner (`make`).

## Current asdf footprint

Files this migration must touch:

**Install scripts** (chezmoi `run_onchange_*` — re-run when their hash changes):

- `home/.chezmoiscripts/run_onchange_before_02-ubuntu-install-asdf.sh.tmpl`
- `home/.chezmoiscripts/run_onchange_before_02-centos-install-asdf.sh.tmpl`
- `home/.chezmoiscripts/run_onchange_after_50-ubuntu-install-asdf-plugins.sh.tmpl`
- `home/.chezmoiscripts/run_onchange_after_50-macos-install-asdf-plugins.sh.tmpl`
- `home/.chezmoiscripts/run_onchange_after_50-centos-install-asdf-plugins.sh.tmpl`

**Shell wiring:**

- `home/shell/asdf/path.zsh` — sets `ASDF_DIR`, `ASDF_COMPLETIONS`, `fpath` (OS-specific)
- `home/shell/asdf/env.zsh` — exports `ASDF_DIR`

**Sheldon plugin manifest:**

- `home/dot_sheldon/plugins.toml.tmpl` — has `[plugins.asdf]` blocks (one Linux, one Brew-prefix-templated for macOS, sourcing `asdf.sh` from `~/.asdf` or `$brewPrefix/opt/asdf*/libexec`)

**Doc references that lie if not updated:**

- `CLAUDE.md` — "ASDF Integration" section, plugin list, env vars
- `AUGMENTCODE.md`, `PLAN.md`
- `ai_docs/reports/zsh_dotfiles_report.md` — "ASDF Version Manager" section

**Test references:**

- `make test` runs the tmux/pytest suite that probes tool availability — those tests should pass post-migration unchanged (they don't care *how* tools are installed, just that they're on `PATH`).

## Tool inventory

Source: `home/.chezmoiscripts/run_onchange_after_50-macos-install-asdf-plugins.sh.tmpl` (the macOS list is the superset). Each entry below is what currently goes through asdf, plus the recommended mise backend.

| Tool | Current asdf source | Recommended mise backend | Notes |
|---|---|---|---|
| `ruby` | core asdf-ruby | `core:ruby` | Native. Existing `foreman`, `tmuxinator` gem installs continue against the mise-managed ruby. |
| `golang` | core asdf-golang | `core:go` | **Do not use the asdf-go plugin via `asdf:`** — v0.16+ broke `local`/`global` (see [comparison page](https://mise.jdx.dev/dev-tools/comparison-to-asdf.html)). |
| `tmux` | core | `core:tmux` or `aqua:tmux/tmux` | Native. |
| `neovim` | core | `core:neovim` | Native. |
| `github-cli` | core | `core:gh` (or `aqua:cli/cli`) | Native. |
| `mkcert` | salasrod/asdf-mkcert | `ubi:FiloSottile/mkcert` | mise registry has it. |
| `shellcheck` | core | `core:shellcheck` (or `ubi:koalaman/shellcheck`) | Native. |
| `shfmt` | core | `core:shfmt` (or `ubi:mvdan/sh`) | Native. |
| `yq` | core | `core:yq` | Native. |
| `helm` | Antiarchitect/asdf-helm | `core:helm` (or `aqua:helm/helm`) | Native. |
| `helmfile` | core | `core:helmfile` | Native. |
| `helm-docs` | sudermanjr/asdf-helm-docs | `core:helm-docs` | Native. |
| `k9s` | virtualstaticvoid/asdf-k9s | `core:k9s` | Native. |
| `kubectx` | virtualstaticvoid/asdf-kubectx | `core:kubectx` | Native. |
| `opa` | tochukwuvictor/asdf-opa | `core:opa` (or `ubi:open-policy-agent/opa`) | Native. |
| `kubectl` | asdf-community/asdf-kubectl | `core:kubectl` | Native. |
| `kubetail` | janpieper/asdf-kubetail | check registry; `ubi:` fallback | Less common; verify. |

**No tool here requires the `asdf:` fallback backend.** Goal: a clean cut to mise-native installs.

## Migration steps

Run these in order. Each step should be a separate commit so a regression can be bisected.

1. **Add mise install scripts** (parallel to asdf, not replacing yet):
   - `home/.chezmoiscripts/run_onchange_before_03-{ubuntu,centos,macos}-install-mise.sh.tmpl` — installs mise via the platform-appropriate method (`brew` on macOS, `mise.run` script or distro pkg on Linux). Idempotent; safe to re-run.
2. **Author root `mise.toml`** at the dotfiles root capturing the tool inventory above. Use loose versions (e.g. `node = "20"`, not `"20.10.4"`); see [mise_configuration.md](../reports/mise_configuration.md) for `[tools]` patterns. Include `[settings.status].show_tools = true` so users see what's active.
3. **Replace shell wiring:**
   - Create `home/shell/mise/path.zsh` and `home/shell/mise/env.zsh`.
   - `path.zsh`: `eval "$(mise activate zsh)"`. Consider `zsh-defer` if startup-time benchmarks regress (see existing `home/shell/zsh_dot_d/` deferred-load patterns).
   - `env.zsh`: any global mise env vars (e.g. `MISE_TRUSTED_CONFIG_PATHS=$HOME`).
4. **Update sheldon manifest** (`home/dot_sheldon/plugins.toml.tmpl`):
   - Remove the two `[plugins.asdf]` blocks.
   - mise activation does not need a sheldon plugin — `eval "$(mise activate zsh)"` from `home/shell/mise/path.zsh` is sufficient.
5. **Run dual** — at this point both asdf and mise are installed. Verify:
   - `mise doctor` clean
   - `mise ls` shows the tool inventory
   - `which kubectl helm ruby` resolves under `~/.local/share/mise/...` (mise) rather than `~/.asdf/shims/...` (asdf)
   - `make test` passes on macOS (CI runs it on `macos-14` and `macos-latest`)
6. **Remove asdf:**
   - Delete the five `run_onchange_*-asdf-*.sh.tmpl` scripts.
   - Delete `home/shell/asdf/`.
   - Remove asdf install lines from any brew/apt prereq scripts.
   - Optionally have a `cleanup-asdf.sh` one-shot that removes `~/.asdf` for the user — but **gate it behind a prompt or env var**, not unconditional.
7. **Update docs:**
   - `CLAUDE.md`: rewrite the "ASDF Integration" + "Installed Tools" sections to reflect mise.
   - `AUGMENTCODE.md`, `PLAN.md`: scrub asdf references.
   - `ai_docs/reports/zsh_dotfiles_report.md`: replace "ASDF Version Manager" section with a mise summary linking to [mise_overview.md](../reports/mise_overview.md).
8. **Update CI** (`.github/workflows/*`): if any workflow references `~/.asdf` paths or env vars, swap for mise's. The CI mostly defers to `chezmoi apply`, so this should be small.

## Behavior differences to watch for

- **No more `~/.asdf/shims/`** — anything that hardcoded that path (scripts, IDE config, supervisord units, dotfiles) breaks. Grep `~/.asdf` across the repo before step 6.
- `.tool-versions` still works but takes lower precedence than `mise.toml`. If a directory has both, `mise.toml` wins. Decide per-project whether to delete `.tool-versions` for clarity.
- **Trust prompts:** mise will refuse to load `mise.toml` files outside trusted dirs. Set `MISE_TRUSTED_CONFIG_PATHS=$HOME` or list specific roots; alternatively run `mise trust` once per repo. CI must set this in the env.
- `asdf-go` 0.16+ → use mise's `core:go` directly; do not route through `asdf:asdf-vm/asdf-go`.
- `ASDF_DIR`, `ASDF_DATA_DIR`, etc. become dead env vars. Remove from `home/shell/asdf/env.zsh` (which is itself deleted in step 3).
- Sheldon's `[plugins.asdf]` source step is gone — confirm no other shell file `source`s `asdf.sh`.

## Verification

After step 6, on a fresh machine (or a `chezmoi apply --refresh-externals`):

```bash
mise doctor                       # all green
mise ls                           # shows the inventory; no missing tools
mise current                      # shows active versions for cwd
which ruby kubectl helm go        # paths under mise's data dir
echo $ASDF_DIR                    # empty
ls ~/.asdf                        # absent (or stale, if cleanup deferred)
make test                         # tmux/pytest suite passes
```

CI verification: GitHub Actions runs `chezmoi apply` + `make test` on `macos-14` and `macos-latest`. Both must pass before merge.

## Out of scope (defer to implementation session)

- The actual `mise.toml` content (versions, ordering, comments).
- Exact body of the new chezmoi mise-install scripts.
- Sheldon `plugins.toml.tmpl` diff.
- Whether to keep `.tool-versions` files in this repo or convert to `mise.toml`.
- Decisions on `auto_install` vs eager `mise install` in the chezmoi flow.
