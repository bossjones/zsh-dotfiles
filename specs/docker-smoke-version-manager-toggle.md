# Plan: Plumb `version_manager` toggle through Docker / Makefile / smoke-test script

## Task Description
The parent spec `specs/migrate-asdf-to-mise.md` introduced a chezmoi template variable
`version_manager` (values `asdf` | `mise`, default `asdf`) and added a matching matrix axis
to `.github/workflows/tests.yml` so CI exercises both lanes on every push. The companion
**local Docker smoke-test path** was not updated. Today there is no way to exercise
`version_manager=mise` on Ubuntu in Docker before merging — only macOS CI does. This task
closes that gap by plumbing a single `VERSION_MANAGER` env var end-to-end:

  shell env → `docker compose` (build args + container env) → `Dockerfile` ARG/ENV →
  `scripts/smoke-test-docker.sh` → `chezmoi init --promptString version_manager=…`

Default `asdf` everywhere to preserve current behavior. No new compose service. The
Dockerfile keeps installing both `mise` and (transitively, via the prereq installer)
`asdf` — having both binaries on `$PATH` is harmless under the **Mutual Exclusion
Invariant** (`specs/migrate-asdf-to-mise.md` lines 15–27): the rendered shell only
activates the selected manager because `home/shell/mise/path.zsh` and
`home/shell/asdf/*.zsh` first-check `ZSH_DOTFILES_VERSION_MANAGER` before any `command -v`
probe.

## Objective
Make `make smoke-mise` and `make smoke-asdf` (or `VERSION_MANAGER=mise make smoke`) run
the full Docker smoke pipeline against the chosen manager, with the smoke script forwarding
`--promptString version_manager=$VERSION_MANAGER` to every `chezmoi init` call and
branching its Ruby-install step between `asdf install ruby 4.0.1` and
`mise use -g ruby@4.0.1`.

## Problem Statement
Concrete gaps observed in the working tree on `feature-asdf-to-mise`:

- `Dockerfile` (line 90) brew-installs `mise` but declares no `ARG VERSION_MANAGER` /
  `ENV VERSION_MANAGER`, so the running container has no signal of which manager to use.
- `docker-compose.yml` (services `smoke` lines 14–26, `smoke-shell` lines 28–41) defines no
  build args and no `VERSION_MANAGER` in the `environment:` block.
- `Makefile` (lines 30–49) `smoke*` targets never set `VERSION_MANAGER`.
- `scripts/smoke-test-docker.sh`:
  - Hardcodes the asdf path in `setup_asdf_and_openssl()` (lines 177–221) — sources
    `~/.asdf/asdf.sh`, exports `ASDF_DIR`, runs `asdf install ruby 4.0.1`.
  - The two `chezmoi init` calls in `run_lint()` (line 238) and `run_build()` (lines
    298, 300) omit `--promptString version_manager=…`, so chezmoi falls back to whatever
    is persisted in `~/.config/chezmoi/chezmoi.yaml` (or the default `asdf`).

The parent spec's regression criterion (`specs/migrate-asdf-to-mise.md` line 192)
explicitly anticipates using `scripts/smoke-test-docker.sh` for VM-style validation —
but as written today the smoke script silently always runs the asdf lane.

## Solution Approach
Introduce `VERSION_MANAGER` as the single source of truth:

1. **Smoke script (`scripts/smoke-test-docker.sh`)** — read `VERSION_MANAGER` from env (or
   second positional arg, e.g. `./smoke-test-docker.sh build mise`), validate it's
   `asdf`|`mise`, log it, then:
   - Rename `setup_asdf_and_openssl()` → `setup_version_manager()` and branch on the var.
     Hoist the OS-shared `OPENSSL3_PREFIX` / `LDFLAGS` / `CPPFLAGS` exports above the
     branch (Ruby compile flags apply identically to both managers per parent spec
     line 162).
   - Pass `--promptString version_manager=$VERSION_MANAGER` to all three `chezmoi init`
     invocations (`run_lint` line 238, `run_build` lines 298, 300).
2. **Dockerfile** — add `ARG VERSION_MANAGER=asdf` and `ENV VERSION_MANAGER=${VERSION_MANAGER}`
   so the var survives `docker run` without re-passing. Do **not** condition the brew
   install on the var; both binaries on `$PATH` is the explicit invariant from the parent
   spec, and keeping a single image build keeps the layer cache reusable for both lanes.
3. **docker-compose.yml** — for both `smoke` and `smoke-shell` services, add `args:` to
   the `build:` block (passes the value into the image at build time) and append
   `VERSION_MANAGER=${VERSION_MANAGER:-asdf}` to `environment:` (passes it at run time, so
   you can re-use a cached image with a different selector).
4. **Makefile** — add two thin convenience targets (`smoke-asdf`, `smoke-mise`) that set
   the env var inline. Existing `smoke`, `smoke-lint`, `smoke-build`, `smoke-shell`
   continue to work unchanged because compose already reads the var.

## Relevant Files
Use these files to complete the task:

- `scripts/smoke-test-docker.sh` — primary wiring. Today: hardcoded asdf path, no
  `--promptString` on `chezmoi init`. Modify per the steps below.
- `Dockerfile` — add `ARG VERSION_MANAGER=asdf` + `ENV VERSION_MANAGER=${VERSION_MANAGER}`
  near the top of the user-section (after line 14, before USER switch on line 72). Update
  header comment (lines 1–8) to document the new build arg.
- `docker-compose.yml` — add `args:` and `VERSION_MANAGER=${VERSION_MANAGER:-asdf}` to the
  `smoke` service (lines 14–26) and `smoke-shell` service (lines 28–41). Update header
  comment (lines 1–12).
- `Makefile` — add `smoke-asdf` and `smoke-mise` targets, append both names to the
  `.PHONY` line (line 30).
- `specs/migrate-asdf-to-mise.md` — **read-only reference**. Provides the Mutual Exclusion
  Invariant (lines 15–27), the `--promptString` plumbing pattern (line 158–159), and the
  Ruby-install branching pattern (line 161). Do not modify.
- `.github/workflows/tests.yml` — **read-only reference**. The `--promptString` and
  conditional Ruby-install pattern at lines 120, 156–166, 198–215 is what we mirror in the
  smoke script. Do not modify.
- `home/shell/mise/path.zsh` and `home/shell/asdf/{env,path}.zsh` — **read-only
  reference**. Already self-guarded on `ZSH_DOTFILES_VERSION_MANAGER` per the Invariant —
  this is why we don't need to gate the Dockerfile install steps.

### New Files
None. All changes are edits to existing files.

## Implementation Phases

### Phase 1: Foundation — smoke script accepts and validates `VERSION_MANAGER`
Edit `scripts/smoke-test-docker.sh` to read the env var (with positional-arg override),
validate it, and log it during `setup_initial_environment`. Verify with
`bash -n` and a dry invocation that prints the resolved value before exiting. Don't
change any chezmoi behavior yet — keeps the foundation isolated.

### Phase 2: Core Implementation — branch the smoke script on the var
- Replace `setup_asdf_and_openssl` with `setup_version_manager` containing an
  `if [[ "$VERSION_MANAGER" == "asdf" ]] … else …` block. Move shared
  `OPENSSL3_PREFIX` / `LDFLAGS` / `CPPFLAGS` exports above the branch.
- Add `--promptString version_manager=$VERSION_MANAGER` to all three `chezmoi init` calls.
- Update both `case "$STAGE"` arms in `main()` (lines 390–419) to call the renamed
  function.

### Phase 3: Integration & Polish — Docker / compose / Makefile + verification
Wire up `Dockerfile` ARG/ENV, `docker-compose.yml` build args + environment, and the two
Makefile convenience targets. Run `docker compose config` to confirm interpolation. Run
`make smoke-asdf` (regression) and `make smoke-mise` (new path). Inside `make smoke-shell`
verify the Mutual Exclusion Invariant with `typeset -f mise` / `typeset -f asdf`.

## Step by Step Tasks
IMPORTANT: Execute every step in order, top to bottom.

### 1. Read and validate `VERSION_MANAGER` at the top of the smoke script
- In `scripts/smoke-test-docker.sh`, immediately after the `STAGE="${1:-all}"` line
  (around line 20), add:
  ```bash
  VERSION_MANAGER="${2:-${VERSION_MANAGER:-asdf}}"
  case "$VERSION_MANAGER" in
      asdf|mise) ;;
      *)
          echo "❌ VERSION_MANAGER must be 'asdf' or 'mise', got: $VERSION_MANAGER" >&2
          exit 1
          ;;
  esac
  export VERSION_MANAGER
  ```
- In `setup_initial_environment()` (around line 29), add a `log_info "VERSION_MANAGER=$VERSION_MANAGER"` line alongside the existing `ZSH_DOTFILES_PREP_*` logs.
- Update the script's header comment block (lines 4–8) to document the new env var and
  the optional second positional arg. Show one example: `VERSION_MANAGER=mise ./scripts/smoke-test-docker.sh build`.

### 2. Rename and branch `setup_asdf_and_openssl` → `setup_version_manager`
- Rename the function definition at line 177.
- Hoist the `OPENSSL3_PREFIX` block (smoke script lines 202–214) **above** the
  asdf/mise branch — the OpenSSL flags apply to both Rubies identically.
- New body skeleton:
  ```bash
  setup_version_manager() {
      log_section "Version Manager Setup ($VERSION_MANAGER)"

      # Shared: OpenSSL 3 flags for Ruby compilation (apply to both managers)
      if command -v brew &> /dev/null; then
          OPENSSL3_PREFIX="$(brew --prefix openssl@3 2>/dev/null)" || true
          if [[ -n "$OPENSSL3_PREFIX" ]]; then
              export LDFLAGS="-L${OPENSSL3_PREFIX}/lib"
              export CPPFLAGS="-I${OPENSSL3_PREFIX}/include"
              log_info "OpenSSL 3 flags set: LDFLAGS=$LDFLAGS"
          fi
          GNUGETOPT_BIN="$(brew --prefix gnu-getopt 2>/dev/null)/bin" || true
          if [[ -d "$GNUGETOPT_BIN" ]]; then
              export PATH="${GNUGETOPT_BIN}:${PATH}"
          fi
      fi

      if [[ "$VERSION_MANAGER" == "asdf" ]]; then
          export ASDF_DIR="${HOME}/.asdf"
          export ASDF_COMPLETIONS="$ASDF_DIR/completions"
          if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
              # shellcheck source=/dev/null
              . "$HOME/.asdf/asdf.sh"
          fi
          export PATH="${HOME}/.asdf/bin:${HOME}/.asdf/shims:${PATH}"
          if command -v asdf &> /dev/null && [[ -n "${OPENSSL3_PREFIX:-}" ]]; then
              log_info "Installing Ruby 4.0.1 via asdf with OpenSSL 3..."
              asdf install ruby 4.0.1 -- --with-openssl-dir="${OPENSSL3_PREFIX}" || true
          fi
      else
          # mise — never source asdf.sh, never set ASDF_DIR (Mutual Exclusion Invariant)
          if command -v mise &> /dev/null; then
              eval "$(mise activate bash)"
              log_info "Installing Ruby 4.0.1 via mise..."
              if [[ -n "${OPENSSL3_PREFIX:-}" ]]; then
                  RUBY_CONFIGURE_OPTS="--with-openssl-dir=${OPENSSL3_PREFIX}" \
                      mise use -g ruby@4.0.1 || true
              else
                  mise use -g ruby@4.0.1 || true
              fi
          else
              log_warning "mise not found on PATH — skipping ruby install"
          fi
      fi

      log_success "Version manager configured: $VERSION_MANAGER"
  }
  ```
- Update the two callers in `main()` (lines 400, 410) from `setup_asdf_and_openssl` to
  `setup_version_manager`.

### 3. Forward `--promptString version_manager=$VERSION_MANAGER` to every `chezmoi init`
- `run_lint()` line 238 — change to:
  ```bash
  if chezmoi init --source=. --force --promptString version_manager="$VERSION_MANAGER" 2>&1; then
  ```
- `run_build()` lines 297–301 — change both branches to append the flag:
  ```bash
  if command -v retry &> /dev/null; then
      retry -t 4 -- "$chezmoi_bin" init -R --debug -v --apply --force \
          --promptString version_manager="$VERSION_MANAGER" --source=. || chezmoi_exit_code=$?
  else
      "$chezmoi_bin" init -R --debug -v --apply --force \
          --promptString version_manager="$VERSION_MANAGER" --source=. || chezmoi_exit_code=$?
  fi
  ```

### 4. Add `ARG` / `ENV` to the Dockerfile
- In `Dockerfile`, after line 14 (`ENV TERM=xterm-256color`) and before the apt-get block,
  add:
  ```dockerfile
  # Version manager selector (asdf | mise) — propagated from docker-compose.yml or
  # `docker build --build-arg VERSION_MANAGER=mise`
  ARG VERSION_MANAGER=asdf
  ENV VERSION_MANAGER=${VERSION_MANAGER}
  ```
- Leave `mise` in the brew install on line 90 unchanged — both binaries on `$PATH` is
  explicitly safe per the parent spec's Mutual Exclusion Invariant.
- Update the header comment (lines 1–8) — add a usage line:
  `#   VERSION_MANAGER=mise make smoke   # Test mise lane`

### 5. Wire `VERSION_MANAGER` into `docker-compose.yml`
- Under the `smoke` service `build:` block (lines 16–20), add:
  ```yaml
      args:
        VERSION_MANAGER: ${VERSION_MANAGER:-asdf}
  ```
- Under the `smoke` service `environment:` block (lines 22–26), append:
  ```yaml
        - VERSION_MANAGER=${VERSION_MANAGER:-asdf}
  ```
- Make the same two additions to the `smoke-shell` service (lines 28–41).
- Update the header comment (lines 1–12) — add:
  ```yaml
  #   VERSION_MANAGER=mise docker compose up --build smoke   # Test mise lane
  ```

### 6. Add convenience Makefile targets
- In `Makefile`, append the new target names to the `.PHONY` declaration on line 30:
  ```makefile
  .PHONY: smoke smoke-lint smoke-build smoke-shell smoke-clean smoke-asdf smoke-mise
  ```
- After `smoke-clean` (around line 49), add:
  ```makefile
  smoke-asdf:  ## Run smoke test with version_manager=asdf (default)
  	@echo "\033[0;34mRunning smoke test with VERSION_MANAGER=asdf...\033[0m"
  	VERSION_MANAGER=asdf docker compose up --build smoke

  smoke-mise:  ## Run smoke test with version_manager=mise
  	@echo "\033[0;34mRunning smoke test with VERSION_MANAGER=mise...\033[0m"
  	VERSION_MANAGER=mise docker compose up --build smoke
  ```

### 7. Lint and dry-validate
- `shellcheck scripts/smoke-test-docker.sh` — must pass (or only have pre-existing
  warnings unrelated to this change).
- `bash -n scripts/smoke-test-docker.sh` — syntax check.
- `VERSION_MANAGER=asdf docker compose config | grep -E 'VERSION_MANAGER|args'` — confirm
  `asdf` shows up in both `args:` and `environment:` for both services.
- `VERSION_MANAGER=mise docker compose config | grep -E 'VERSION_MANAGER|args'` — same
  for `mise`.

### 8. Run the regression lane (asdf)
- `make smoke-asdf` — must produce the same green outcome as today's `make smoke`.
- Inside the running container (or via `make smoke-shell` with
  `VERSION_MANAGER=asdf`), confirm `chezmoi data --format=json | jq .version_manager`
  returns `"asdf"`.

### 9. Run the new lane (mise)
- `make smoke-mise` — must complete cleanly. Expect `chezmoi diff` (during `run_lint`)
  to show mise install scripts and skip asdf install scripts.
- Inside `make smoke-shell` with `VERSION_MANAGER=mise`:
  ```bash
  chezmoi data --format=json | jq .version_manager   # → "mise"
  zsh -ic 'echo "$ZSH_DOTFILES_VERSION_MANAGER"'     # → mise
  zsh -ic 'typeset -f asdf'                          # empty (Mutual Exclusion Invariant)
  zsh -ic 'mise current ruby'                        # → 4.0.1
  ```

### 10. Update parent spec acceptance crosslink (optional, defer)
- Optionally add a one-line note in `specs/migrate-asdf-to-mise.md` "Notes" section
  pointing at this spec for local Docker validation. **Defer** unless the parent spec
  is being touched in the same PR — avoid drive-by edits.

## Testing Strategy

- **Static**: `shellcheck` + `bash -n` on the smoke script; `docker compose config` on the
  compose file (compose validates interpolation and schema).
- **Smoke (asdf lane)**: `make smoke-asdf` end-to-end on a clean Docker state. This is the
  regression check — it must match current `make smoke` behavior bit-for-bit.
- **Smoke (mise lane)**: `make smoke-mise` end-to-end. Validates that
  `--promptString version_manager=mise` propagates through `chezmoi init` and that the
  `setup_version_manager` mise branch installs Ruby and activates `mise`.
- **Mutual Exclusion Invariant** (parent spec lines 15–27): inside a `make smoke-shell`
  with `VERSION_MANAGER=mise`, confirm `typeset -f asdf` is empty and the
  `ZSH_DOTFILES_VERSION_MANAGER` env var equals `mise`. Symmetric check under
  `VERSION_MANAGER=asdf` (`typeset -f mise` empty).
- **No new pytest cases needed** — the existing tmux-based pytest suite (`make test`)
  doesn't depend on which version manager is active; it inherits the lane via the
  outer container's chezmoi state.

## Acceptance Criteria
- `make smoke-asdf` passes on a clean Docker state, producing the same observable
  end-state (rendered `compat.bash`, sheldon `plugins.toml`, `~/.tool-versions`) as
  pre-change `make smoke`.
- `make smoke-mise` passes on a clean Docker state, with `chezmoi data --format=json |
  jq .version_manager` returning `"mise"` and rendered shell init using `mise activate
  bash` instead of `. asdf.sh`.
- Inside `make smoke-shell` with `VERSION_MANAGER=mise`, `typeset -f asdf` is empty AND
  `[ "$ZSH_DOTFILES_VERSION_MANAGER" = "mise" ]` is true.
- Inside `make smoke-shell` with `VERSION_MANAGER=asdf`, `typeset -f mise` is empty AND
  `[ "$ZSH_DOTFILES_VERSION_MANAGER" = "asdf" ]` is true.
- `docker compose config` renders the `VERSION_MANAGER` value into both `args:` and
  `environment:` for both services, with `asdf` as the default when unset.
- `shellcheck scripts/smoke-test-docker.sh` reports no new findings vs. the pre-change
  baseline.

## Validation Commands
Execute these commands to validate the task is complete (all are read-only or
Docker-local — none touches the workstation's `$HOME`, per the standing
`chezmoi --dry-run only` constraint):

- `shellcheck scripts/smoke-test-docker.sh` — lint the modified script.
- `bash -n scripts/smoke-test-docker.sh` — syntax check.
- `VERSION_MANAGER=asdf docker compose config | grep -E 'VERSION_MANAGER|args'` — confirm
  asdf interpolation in both services.
- `VERSION_MANAGER=mise docker compose config | grep -E 'VERSION_MANAGER|args'` — confirm
  mise interpolation in both services.
- `make smoke-asdf` — full asdf-lane regression run (~10–20 min on a cold cache).
- `make smoke-mise` — full mise-lane run (~10–20 min on a cold cache).
- `chezmoi execute-template --init --promptString version_manager=mise < home/compat.bash.tmpl | grep -E 'asdf|mise'`
  — read-only render check on the workstation; should show only `mise activate bash`.
- (Inside `make smoke-shell` with `VERSION_MANAGER=mise`)
  `chezmoi data --format=json | jq .version_manager` — must print `"mise"`.

## Notes

- **Memory constraint**: per persisted feedback, never run `chezmoi apply` or
  `chezmoi init --apply` on the primary workstation, even into a scratch destination. All
  apply-style validation goes through Docker (`make smoke-*`) or CI. The
  `chezmoi execute-template` render check is the only on-host verification.
- **Layer cache**: keeping a single Dockerfile path (no conditional brew install) means
  one image layer cache works for both lanes — switching `VERSION_MANAGER` only
  re-renders chezmoi templates, doesn't rebuild the image.
- **Why not a separate `smoke-mise` compose service?** Two services would duplicate the
  build context and layer cache for no benefit; an env var is sufficient because the
  Dockerfile build is identical and the runtime branching all happens inside the smoke
  script.
- **Why not gate the Dockerfile brew install of `mise`?** The Mutual Exclusion Invariant
  (parent spec lines 15–27) explicitly tolerates both binaries on `$PATH` — the
  rendered shell only activates the selected one. Gating would add layer-cache
  complexity without correctness benefit.
- **Out of scope** (deferred to follow-up PRs):
  - Renaming `myAsdf*Version` template keys — since done in a later PR (tool-version keys renamed to `my<Tool>Version`; `myAsdfVersion` kept).
  - Flipping the default `version_manager` from `asdf` to `mise` (parent spec line 222
    defers this until both CI legs and at least one personal machine are green on mise).
  - Adding a Linux/Docker leg to `.github/workflows/tests.yml`. The existing macOS matrix
    already covers both lanes per spec; this Docker work is a local-dev convenience.
- **No new dependencies**. No `uv add` needed.
