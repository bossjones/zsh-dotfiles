# Tutorial 05: Run Smoke Tests Locally

> Reproduce the GitHub Actions CI matrix in Docker, before you push, using `make smoke*`.

**See also:** [docs/testing-and-ci.md](../testing-and-ci.md) (full reference) · [CONTRIBUTING.md](../../CONTRIBUTING.md#running-the-test-suite) · [Tutorials index](README.md)

---

## What you'll learn

- How `make smoke` reproduces CI end to end inside Docker
- The difference between the `lint`, `build`, `provision`, and `all` stages
- How to test the `asdf` and `mise` lanes independently
- How to drop into an interactive shell when a smoke test fails, to debug it live

**Prerequisites:** [Docker](https://www.docker.com/) and Docker Compose installed. No prior CI knowledge required.

**Time estimate:** 15–40 minutes for a full run (mostly Homebrew/tool installs inside the container); seconds to start an interactive debug shell.

---

## Why this exists

[`scripts/smoke-test-docker.sh`](../../scripts/smoke-test-docker.sh) exists specifically to reproduce [`.github/workflows/tests.yml`](../../.github/workflows/tests.yml) locally — same prereq installer, same chezmoi init/apply, same `post-install-chezmoi`, same pytest suite — so you can catch a CI failure on your laptop in minutes instead of waiting on a push-and-wait cycle.

---

## Step 1: Run the default smoke test

```sh
make smoke
```

This runs `docker compose up --build smoke`, which defaults to `VERSION_MANAGER=asdf` (see [`docker-compose.yml`](../../docker-compose.yml)).

To test the `mise` lane instead:

```sh
make smoke-mise
```

Both targets accept the `VERSION_MANAGER` environment variable directly too:

```sh
VERSION_MANAGER=mise docker compose up --build smoke
```

---

## Step 2: Run a single stage (faster iteration)

`scripts/smoke-test-docker.sh` supports four stages, and the Makefile exposes the first two directly:

| Stage | Make target | What it checks |
|-------|-------------|-----------------|
| `lint` | `make smoke-lint` | `pre-commit run --all-files`, then `chezmoi init --source=. --force --promptString version_manager=$VERSION_MANAGER` followed by `chezmoi diff --source=.` to validate every template parses and renders cleanly |
| `build` | `make smoke-build` | Installs Homebrew packages, runs the prereq installer, sets up the version manager, runs the real `chezmoi init --apply` + `post-install-chezmoi`, then runs the pytest suite |
| `provision` | (used internally by `Dockerfile.full`) | Same as `build`, minus the pytest run — used to bake a pre-provisioned image |
| `all` | (`make smoke` / `make smoke-mise`, default) | `lint` → `build`'s install steps → pytest, all in sequence |

```sh
make smoke-lint     # fastest — catches template/pre-commit issues in seconds
make smoke-build    # full provisioning + tests, no pre-commit
```

Source: `main()`'s `case "$STAGE"` block in [`scripts/smoke-test-docker.sh`](../../scripts/smoke-test-docker.sh).

---

## Step 3: Debug a failure interactively

If a stage fails and you need to poke around inside the same container environment:

```sh
make smoke-asdf-shell   # interactive zsh, VERSION_MANAGER=asdf
make smoke-mise-shell   # interactive zsh, VERSION_MANAGER=mise
```

These run `docker compose run --rm smoke-shell`, which launches the same image with `/bin/zsh` as the entrypoint and a TTY attached, instead of running the smoke script automatically.

---

## Step 4: Bake pre-provisioned images (optional, for repeated iteration)

If you're iterating on the test suite itself rather than the provisioning scripts, baking a pre-provisioned image once and reusing it is much faster than re-provisioning on every run:

```sh
make smoke-full-asdf   # bakes zsh-dotfiles-smoke-full:asdf (requires DOCKER_BUILDKIT=1)
make smoke-full-mise   # bakes zsh-dotfiles-smoke-full:mise
make smoke-full        # both lanes

make smoke-full-run-asdf   # docker run --rm -it zsh-dotfiles-smoke-full:asdf
make smoke-full-run-mise   # docker run --rm -it zsh-dotfiles-smoke-full:mise
```

To avoid Homebrew API rate limiting during the build, export a token first:

```sh
export HOMEBREW_GITHUB_API_TOKEN=ghp_your_token_here
```

---

## Step 5: Clean up

```sh
make smoke-clean         # docker compose down --rmi local --volumes --remove-orphans
make smoke-full-clean    # removes the baked smoke-full / smoke images
```

---

## What pass/fail actually means

| Result | Meaning |
|--------|---------|
| `lint` stage fails on `pre-commit` | A hook in [`.pre-commit-config.yaml`](../../.pre-commit-config.yaml) found an issue — read the specific hook's output |
| `lint` stage fails on `chezmoi diff` | A `.tmpl` file has a template syntax error or fails to render for the given `version_manager` — the script prints the diff/error to stderr |
| `build` stage fails during provisioning | Something in the Homebrew install, prereq installer, or `chezmoi apply`/`post-install-chezmoi` chain failed — this is the same failure you'd see in CI |
| `build`/`all` stage fails during `run_pytest` | An actual test in `test_dotfiles.py` / `test_scripts_backup_dotfiles.py` / `test_scripts_check_jsonc.py` failed |
| Everything prints `All stages passed!` | The full `all` stage (lint + build + tests) completed cleanly for that `VERSION_MANAGER` |

---

## Verify

```sh
# Confirm both lanes pass independently before opening a PR
make smoke-asdf
make smoke-mise

# Or, faster: just the lint stage on both, to catch template regressions
VERSION_MANAGER=asdf docker compose run --rm smoke lint
VERSION_MANAGER=mise docker compose run --rm smoke lint
```

A clean run ends with `Smoke Test Complete` / `All stages passed!` in the log for both `VERSION_MANAGER` values.

---

## Next steps

- **[docs/testing-and-ci.md](../testing-and-ci.md)** — the full pytest + libtmux fixture model and GitHub Actions matrix reference
- **[Tutorial 04: Switch Version Manager](04-switch-version-manager.md)** — understand what `VERSION_MANAGER` actually changes under the hood
