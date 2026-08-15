# Plan: Fix `make smoke-mise` so mise actually runs and tests actually validate

## Context

The branch `feature-asdf-to-mise` is partway through migrating from asdf to mise.
The smoke test `make smoke-mise` runs a Docker build that should provision the
container with mise, but the run shows three problems:

1. **Asdf scripts ran instead of mise scripts.** The chezmoi-rendered `.zshrc`
   even shows `ZSH_DOTFILES_VERSION_MANAGER="asdf"`, proving the template
   evaluated `version_manager` as `"asdf"` despite `VERSION_MANAGER=mise` being
   set and forwarded.
2. **All 5 pytest tests skipped.** Four have hard-coded `@pytest.mark.skip`
   ("only run locally") and the fifth uses `@pytest.mark.skipif(IN_DOCKER)`.
   Net result: zero test coverage in Docker — the smoke run can succeed even
   when the environment is broken (as it just did).
3. **Stray `dev/bossjones/` empty dirs in `$HOME`** appear in the chezmoi diff.
   They come from `home/.chezmoiexternal.yaml` declaring two personal git
   externals that have no business running in CI/Docker.

## Objective

After this plan: `make smoke-mise` provisions the container with mise (no asdf
plugins compiled), pytest runs Docker-aware assertions that actually verify
mise was installed and `version_manager=mise` propagated, and the chezmoi diff
shows no `dev/bossjones/` artifacts in the smoke output.

## Problem Statement

The bug is concentrated in **one nested template guard** in
`home/.chezmoi.yaml.tmpl`:

```gotmpl
# line 33
{{- if $interactive -}}
  ...lots of other prompts...
  # lines 100-104 — INSIDE the interactive block
  {{-   if hasKey . "version_manager" -}}
  {{-     $version_manager = .version_manager -}}
  {{-   else -}}
  {{-     $version_manager = promptString "Version manager (asdf or mise)" $version_manager -}}
  {{-   end -}}
{{- end -}}
```

`$interactive` is `stdinIsATTY` (line 2). In a Docker build there is no TTY,
so the whole block is skipped — including the line that would copy
`.version_manager` (the value from `--promptString version_manager="mise"`)
into `$version_manager`. The default `"asdf"` from line 20 wins. That single
detail cascades:

- `data.version_manager` is written as `"asdf"` to the rendered chezmoi config.
- `.chezmoiignore.tmpl` reads `.version_manager == "asdf"`, so it ignores
  the **mise** scripts and keeps the **asdf** scripts. Asdf compiles tmux,
  ruby, neovim, etc. — exactly what we saw.

Tests are independent: `test_dotfiles.py` was authored with a
"only run on my laptop" bias, so almost everything is unconditionally skipped
in Docker. We need a parallel set of Docker-aware tests that prove the smoke
container is in a known-good state.

## Solution Approach

Three small, focused changes (one root-cause fix, two cleanups):

1. **Move the `version_manager` resolution OUT of the `if $interactive`
   block.** Read from `.version_manager` (i.e. `--promptString`) whenever it
   is provided, regardless of TTY; only fall back to `promptString` when
   interactive. This is the same pattern the rest of the template should
   eventually adopt for any non-interactive-friendly flag.
2. **Add Docker-aware smoke tests** in `test_dotfiles.py` that run *only*
   when `IN_DOCKER` is true and assert the container is configured the way
   `VERSION_MANAGER=mise` requested.
3. **Gate the `dev/bossjones/*` externals** behind a non-CI check by
   converting `home/.chezmoiexternal.yaml` to a template
   (`home/.chezmoiexternal.yaml.tmpl`) and wrapping the entries in
   `{{- if not (env "ZSH_DOTFILES_PREP_CI") -}}`.

## Relevant Files

Existing files we will edit:

- `home/.chezmoi.yaml.tmpl` — the actual root-cause file. Move lines 100–104
  outside the `if $interactive` block (currently lines 33–105).
- `test_dotfiles.py` — append a new `TestSmokeContainer` class with
  `@pytest.mark.skipif(not IN_DOCKER, ...)` markers. Existing skip decorators
  on the other tests are left intact (per user choice "Add Docker-aware smoke
  tests").
- `scripts/smoke-test-docker.sh` — verify it propagates `VERSION_MANAGER`
  correctly into pytest (export it for the pytest invocation so tests can
  read `os.getenv("VERSION_MANAGER")`).

Existing file we will rename + edit:

- `home/.chezmoiexternal.yaml` → `home/.chezmoiexternal.yaml.tmpl`
  (templates are required to use `{{ if … }}`; a plain `.yaml` file is not
  rendered).

### New files

- None.

## Implementation Phases

### Phase 1: Fix the root cause (mise actually runs)

Patch `home/.chezmoi.yaml.tmpl` so `--promptString version_manager=mise`
takes effect in non-interactive Docker runs.

### Phase 2: Make tests prove the smoke

Add Docker-aware assertions to `test_dotfiles.py` that fail loudly if the
container isn't configured as requested. Verify `VERSION_MANAGER` is exported
into the pytest environment.

### Phase 3: Clean up smoke output

Convert `home/.chezmoiexternal.yaml` to a template and gate personal
externals behind `ZSH_DOTFILES_PREP_CI`. Re-run smoke and confirm clean diff.

## Step by Step Tasks

IMPORTANT: Execute every step in order, top to bottom.

### 1. Fix `version_manager` resolution in `home/.chezmoi.yaml.tmpl`

- Open `home/.chezmoi.yaml.tmpl`.
- Delete the version_manager block currently at lines 100–104 (still inside
  `if $interactive`).
- Insert a replacement block **after** line 105 (after the closing `{{- end -}}`
  of the interactive block) and **before** the `if $interactive` writeToStdout
  on line 107:

  ```gotmpl
  {{- /* version_manager: honor --promptString in non-TTY runs (Docker, CI). */ -}}
  {{- /* `.version_manager` is set by `--promptString version_manager=…`     */ -}}
  {{- /* and is available regardless of stdinIsATTY.                          */ -}}
  {{- if hasKey . "version_manager" -}}
  {{-   $version_manager = .version_manager -}}
  {{- else if $interactive -}}
  {{-   $version_manager = promptString "Version manager (asdf or mise)" $version_manager -}}
  {{- end -}}
  ```

- Leave the default initializer on line 20 (`{{- $version_manager := "asdf" -}}`)
  alone — it remains the fallback for fully non-interactive runs that don't
  pass `--promptString`.

### 2. Verify the fix locally before running Docker

- From the repo root, render the template with both values and confirm the
  output:
  ```bash
  chezmoi execute-template --promptString version_manager=mise \
      < home/.chezmoiignore.tmpl
  # Expect: the asdf script lines, NOT the mise script lines
  ```
  ```bash
  chezmoi execute-template --promptString version_manager=asdf \
      < home/.chezmoiignore.tmpl
  # Expect: the mise script lines, NOT the asdf script lines
  ```
- The two outputs must differ. If they're identical, the fix isn't right.

### 3. Export `VERSION_MANAGER` for pytest in `scripts/smoke-test-docker.sh`

- Open `scripts/smoke-test-docker.sh`. Find the `run_test` (or equivalent)
  stage that invokes `pytest`.
- Ensure `VERSION_MANAGER` is exported at process scope (the script already
  has it set as a shell var via line 23, but confirm it's marked
  `export VERSION_MANAGER` so child pytest can read it via `os.getenv`).
- If pytest runs through `python -m pytest`, no extra change is needed beyond
  `export`. If pytest runs through a wrapper that scrubs env, add
  `VERSION_MANAGER="$VERSION_MANAGER"` inline.

### 4. Add Docker-aware smoke tests to `test_dotfiles.py`

- At the bottom of `test_dotfiles.py` (after the existing `TestDotfiles`
  class), append a new class. Do **not** modify existing skip decorators.
- The new class targets only Docker runs and asserts:

  ```python
  import os
  import shutil
  from pathlib import Path

  @pytest.mark.skipif(not IN_DOCKER, reason="Smoke assertions only run inside the smoke container")
  class TestSmokeContainer:
      """Validates the smoke container reflects the requested VERSION_MANAGER."""

      def test_version_manager_env_var_set(self):
          """The smoke harness must propagate VERSION_MANAGER into the test env."""
          assert os.getenv("VERSION_MANAGER") in {"asdf", "mise"}, (
              "VERSION_MANAGER must be exported by smoke-test-docker.sh"
          )

      def test_zshrc_records_correct_version_manager(self):
          """The rendered ~/.zshrc must record the version manager that was requested."""
          requested = os.getenv("VERSION_MANAGER", "asdf")
          zshrc = Path.home() / ".zshrc"
          assert zshrc.exists(), "~/.zshrc not rendered"
          contents = zshrc.read_text()
          assert f'ZSH_DOTFILES_VERSION_MANAGER="{requested}"' in contents, (
              f"Expected ZSH_DOTFILES_VERSION_MANAGER=\"{requested}\" in ~/.zshrc; "
              f"found:\n{contents[:500]}"
          )

      def test_requested_manager_binary_installed(self):
          """When VERSION_MANAGER=mise, mise must be on PATH (and asdf scripts must not have run)."""
          requested = os.getenv("VERSION_MANAGER", "asdf")
          if requested == "mise":
              assert shutil.which("mise") is not None, "mise binary missing despite VERSION_MANAGER=mise"
          else:
              # asdf path: ~/.asdf/asdf.sh must exist
              assert (Path.home() / ".asdf" / "asdf.sh").exists(), "asdf install missing despite VERSION_MANAGER=asdf"

      def test_other_manager_did_not_run(self):
          """When mise is requested, asdf-managed installs (e.g. ~/.asdf/installs/tmux) must be absent."""
          requested = os.getenv("VERSION_MANAGER", "asdf")
          asdf_installs = Path.home() / ".asdf" / "installs"
          if requested == "mise":
              assert not asdf_installs.exists() or not any(asdf_installs.iterdir()), (
                  f"asdf installed packages despite VERSION_MANAGER=mise: {list(asdf_installs.iterdir())}"
              )
  ```

- These tests are intentionally narrow: they read environment + filesystem
  state only, no shell sourcing required.

### 5. Convert `.chezmoiexternal.yaml` to a template and gate by CI

- Rename: `git mv home/.chezmoiexternal.yaml home/.chezmoiexternal.yaml.tmpl`
- Edit the new `.tmpl` to wrap the two git-repo entries:

  ```gotmpl
  {{- /* Personal externals — only fetched on real workstations, never in CI/Docker. */ -}}
  {{- if not (env "ZSH_DOTFILES_PREP_CI") }}
  dev/bossjones/oh-my-tmux:
    type: git-repo
    url: https://github.com/bossjones/.tmux.git

  dev/bossjones/boss-cheatsheets:
    type: git-repo
    url: https://github.com/bossjones/boss-cheatsheets.git
  {{- end }}
  ```

- The smoke container already exports `ZSH_DOTFILES_PREP_CI=1` (per
  `CLAUDE.md` and the smoke-test-docker.sh env block), so this resolves to an
  empty externals file inside the container.

### 6. Validate end-to-end

- Run `make smoke-mise` from the repo root.
- Confirm in the output:
  - The `chezmoi diff` no longer shows `dev/` and `dev/bossjones/` entries.
  - The chezmoi output runs `02-ubuntu-install-mise.sh.tmpl` and
    `50-mise-install-tools.sh.tmpl` (search the log for `mise`).
  - The chezmoi output does **not** run any `*-install-asdf-plugins.sh` or
    `*-install-asdf.sh.tmpl` scripts.
  - The pytest summary reports `4 passed, 5 skipped` (the 5 original skipped
    + 4 new smoke tests passed) instead of `5 skipped`.
- Run `make smoke-asdf` (or `make smoke`) and confirm:
  - asdf scripts run, mise scripts do not.
  - The 4 new tests still pass (they read `VERSION_MANAGER` and adapt).

## Testing Strategy

- **Template rendering** (Step 2): exercise both `--promptString
  version_manager=mise` and `=asdf` with `chezmoi execute-template` to prove
  the conditional inverts. Catches regressions in the template fix without
  needing Docker.
- **Docker smoke tests** (Step 4): the four new assertions form a contract
  between the smoke harness and the chezmoi templates. If anyone later
  re-introduces the original `if $interactive` nesting bug, all four tests
  fail loudly.
- **Manual smoke runs** (Step 6): run *both* `smoke-mise` and `smoke-asdf` to
  prove the toggle works in both directions, not just for mise.

## Acceptance Criteria

- `make smoke-mise` exits 0 and pytest reports `4 passed, 5 skipped`
  (previously `5 skipped`).
- `make smoke-mise` log contains the string `02-ubuntu-install-mise` and
  does **not** contain `02-ubuntu-install-asdf` or `50-ubuntu-install-asdf`.
- `make smoke-asdf` (or unset `VERSION_MANAGER` smoke) still works: the four
  new tests pass with `VERSION_MANAGER=asdf` semantics.
- The chezmoi diff in the smoke log no longer shows `dev/bossjones/*`
  entries.
- No regressions on local interactive `chezmoi init` on the user's
  workstation: `chezmoi init` still prompts (or reuses prior config) for
  `version_manager` because the `else if $interactive` branch is preserved.

## Validation Commands

Run these to verify each piece (in order):

- `chezmoi execute-template --promptString version_manager=mise < home/.chezmoiignore.tmpl | grep -F '02-ubuntu-install-asdf'`
  — must print the asdf script line (proves mise selection ignores asdf
  scripts). Empty output = template fix didn't take.
- `chezmoi execute-template --promptString version_manager=asdf < home/.chezmoiignore.tmpl | grep -F '50-mise-install-tools'`
  — must print the mise script line.
- `make smoke-mise 2>&1 | tee /tmp/smoke-mise.log` — full smoke run.
- `grep -c 'install-mise' /tmp/smoke-mise.log` — must be `>= 1`.
- `grep -c 'install-asdf-plugins' /tmp/smoke-mise.log` — must be `0`.
- `grep -E 'passed|skipped' /tmp/smoke-mise.log` — must contain
  `4 passed, 5 skipped` (or similar passed count).
- `grep -E '^diff --git a/dev' /tmp/smoke-mise.log` — must be empty.

## Notes

- **Why not delete the `if hasKey . "version_manager"` guard entirely?** Other
  prompts in the template (lines 33–98) follow the same `hasKey` → `promptString`
  pattern. Keeping the guard but moving it out of `if $interactive` matches the
  style and lets non-TTY runs pass the value via `--promptString` without
  regressing the interactive UX.
- **`.chezmoiexternal.yaml.tmpl` precedence:** chezmoi prefers the `.tmpl`
  variant if both files exist; delete the original `.yaml` after renaming
  (Step 5) to avoid ambiguity.
- **No new dependencies.** Pytest, libtmux, etc. are already in
  `requirements-test.txt`.
- **Out of scope (call-outs for follow-up):** The other prompts in
  `.chezmoi.yaml.tmpl` (ruby, pyenv, nodejs, k8s, cuda, fnm, opencv) are also
  trapped inside the `if $interactive` block. They're untouched here because
  the smoke-mise failure doesn't depend on them, but the same pattern will
  bite anyone trying to drive those flags from CI. Worth a follow-up ticket.
