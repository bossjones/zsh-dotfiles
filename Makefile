.PHONY: help
help:  ## Show this help (every documented target)
	@awk 'BEGIN {FS = ":.*?## "} \
		/^[a-zA-Z0-9_.-]+:.*?## / {printf "  \033[36m%-28s\033[0m %s\n", $$1, $$2}' \
		$(MAKEFILE_LIST)

# `make` with no target keeps its historical meaning: `sync`.
.DEFAULT_GOAL := sync

sync:  ## uv sync --all-extras and install the pre-commit hooks
	@uv sync --all-extras
	uv run pre-commit install

pre-commit:  ## Run every pre-commit hook against all files
	uv run pre-commit run -a

test:  ## Run the tmux-based integration suite (py.test, 6 reruns)
	py.test --tb=short --no-header --showlocals --reruns 6 test_dotfiles.py test_fzf_tab.py test_scripts_backup_dotfiles.py test_scripts_check_jsonc.py test_ccstatusline_settings.py

test-pdb:  ## Run the integration suite under the bpdb debugger
	py.test --pdb --pdbcls bpdb:BPdb --tb=short --no-header --showlocals test_dotfiles.py test_fzf_tab.py test_scripts_backup_dotfiles.py test_scripts_check_jsonc.py test_ccstatusline_settings.py

uv-test:  ## Run the integration suite through `uv run pytest` (verbose, timed)
	uv run pytest -vvvv --tb=short --no-header --showlocals --reruns 6 --durations-min=0.05 --durations=10 test_dotfiles.py test_fzf_tab.py test_scripts_backup_dotfiles.py test_scripts_check_jsonc.py test_ccstatusline_settings.py

uv-test-pdb:  ## Run the integration suite through uv under the bpdb debugger
	uv run pytest --pdb --pdbcls bpdb:BPdb --tb=short --no-header --showlocals test_dotfiles.py test_fzf_tab.py test_scripts_backup_dotfiles.py test_scripts_check_jsonc.py test_ccstatusline_settings.py

.PHONY: update-cursor-rules
update-cursor-rules:  ## Update cursor rules from prompts/drafts/cursor_rules
	# Create .cursor/rules directory if it doesn't exist.
	# Note: at the time of writing, cursor does not support generating .mdc files via Composer Agent.s
	mkdir -p .cursor/rules || true
	# Copy files from prompts/drafts/cursor_rules to .cursor/rules and change extension to .mdc
	# Exclude README.md files from being copied
	find hack/drafts/cursor_rules -type f -name "*.md" ! -name "README.md" -exec sh -c 'for file; do target=$${file%.md}; cp -a "$$file" ".cursor/rules/$$(basename "$$target")"; done' sh {} +

.PHONY: install-hooks
install-hooks:  ## Create the 3.12 uv venv and install the pre-commit hooks
	uv venv --python 3.12
	uv run pre-commit install

.PHONY: smoke smoke-lint smoke-build smoke-shell smoke-clean smoke-asdf smoke-mise smoke-asdf-shell smoke-mise-shell
smoke:  ## Run full smoke test in Docker (reproduces CI; uses VERSION_MANAGER env var, default asdf)
	@echo "\033[0;34mRunning smoke test in Docker (VERSION_MANAGER=$${VERSION_MANAGER:-asdf})...\033[0m"
	docker compose up --build smoke

smoke-lint:  ## Run lint stage only in Docker
	@echo "\033[0;34mRunning lint stage in Docker...\033[0m"
	docker compose run --rm smoke lint

smoke-build:  ## Run build stage only in Docker
	@echo "\033[0;34mRunning build stage in Docker...\033[0m"
	docker compose run --rm smoke build

smoke-shell:  ## Start interactive shell for debugging smoke test failures
	@echo "\033[0;34mStarting interactive smoke test shell...\033[0m"
	docker compose run --rm smoke-shell

smoke-clean:  ## Clean up smoke test Docker resources
	@echo "\033[0;34mCleaning up smoke test containers...\033[0m"
	docker compose down --rmi local --volumes --remove-orphans

smoke-asdf:  ## Run smoke test with version_manager=asdf (current default)
	@echo "\033[0;34mRunning smoke test with VERSION_MANAGER=asdf...\033[0m"
	VERSION_MANAGER=asdf docker compose up --build smoke

smoke-mise:  ## Run smoke test with version_manager=mise
	@echo "\033[0;34mRunning smoke test with VERSION_MANAGER=mise...\033[0m"
	VERSION_MANAGER=mise docker compose up --build smoke

smoke-asdf-shell:  ## Interactive shell with VERSION_MANAGER=asdf for manual verification
	@echo "\033[0;34mStarting interactive shell with VERSION_MANAGER=asdf...\033[0m"
	VERSION_MANAGER=asdf docker compose run --rm smoke-shell

smoke-mise-shell:  ## Interactive shell with VERSION_MANAGER=mise for manual verification
	@echo "\033[0;34mStarting interactive shell with VERSION_MANAGER=mise...\033[0m"
	VERSION_MANAGER=mise docker compose run --rm smoke-shell

# ---------------------------------------------------------------------------
# CUDA / GPU verification (ad-hoc; not part of CI)
#
# CI runs on macOS only and the cuda sheldon plugin is Linux-gated, so nothing in
# .github/workflows ever sources home/shell/cuda/*. These targets are the real
# gate for that code.
#
#   smoke-cuda  - no GPU needed. Exercises the shell modules against real NVIDIA
#                 apt packages, real update-alternatives and real ld.so.conf.d.
#   smoke-gpu   - needs a GPU + nvidia-container-toolkit. Answers "can my driver
#                 run binaries built by toolkit X?" before installing X on the host.
#
# Override the toolkit under test:
#   CUDA_SERIES=12-1 make smoke-cuda
#   CUDA_IMAGE=nvidia/cuda:12.1.0-devel-ubuntu22.04 make smoke-gpu
#   MIN_DRIVER=580.126.20 make smoke-gpu     # also assert a documented floor
# ---------------------------------------------------------------------------
.PHONY: smoke-cuda smoke-cuda-shell smoke-gpu smoke-gpu-shell smoke-cuda-clean

smoke-cuda:  ## Verify the CUDA shell modules against real NVIDIA packages (no GPU required)
	@echo "\033[0;34mVerifying CUDA shell modules in Docker (CUDA_SERIES=$${CUDA_SERIES:-13-0})...\033[0m"
	docker compose run --rm --build cuda-verify

smoke-cuda-shell:  ## Interactive shell in the CUDA verification container
	@echo "\033[0;34mStarting CUDA verification shell...\033[0m"
	docker compose run --rm --build cuda-verify-shell

smoke-gpu:  ## Verify a CUDA toolkit against the host driver (requires GPU + nvidia-container-toolkit)
	@echo "\033[0;34mVerifying GPU/driver compatibility (CUDA_IMAGE=$${CUDA_IMAGE:-nvidia/cuda:13.0.0-devel-ubuntu22.04})...\033[0m"
	@command -v nvidia-smi >/dev/null 2>&1 || { echo "\033[0;31mnvidia-smi not found on the host - no GPU to test.\033[0m"; exit 2; }
	@nvidia-ctk cdi list >/dev/null 2>&1 || echo "\033[0;33mwarning: no CDI spec found. Run: sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml\033[0m"
	docker compose run --rm --build gpu-verify

smoke-gpu-shell:  ## Interactive shell in the GPU verification container
	@echo "\033[0;34mStarting GPU verification shell...\033[0m"
	docker compose run --rm --build gpu-verify-shell

smoke-cuda-clean:  ## Remove the CUDA/GPU verification images
	@echo "\033[0;34mRemoving CUDA/GPU verification images...\033[0m"
	-docker rmi chezmoi-cuda-verify chezmoi-cuda-verify-shell chezmoi-gpu-verify chezmoi-gpu-verify-shell 2>/dev/null || true
	-docker compose rm -f cuda-verify cuda-verify-shell gpu-verify gpu-verify-shell 2>/dev/null || true

.PHONY: smoke-full smoke-full-asdf smoke-full-mise \
        smoke-full-run-asdf smoke-full-run-mise smoke-full-clean

smoke-full: smoke-full-asdf smoke-full-mise  ## Bake pre-provisioned images for both VERSION_MANAGER lanes

smoke-full-asdf:  ## Bake pre-provisioned smoke image (asdf lane); requires DOCKER_BUILDKIT=1
	@echo "\033[0;34mBaking pre-provisioned smoke image (asdf)...\033[0m"
	DOCKER_BUILDKIT=1 docker build -f Dockerfile -t zsh-dotfiles-smoke:asdf \
		--build-arg VERSION_MANAGER=asdf \
		--secret id=homebrew_token,env=HOMEBREW_GITHUB_API_TOKEN .
	DOCKER_BUILDKIT=1 docker build -f Dockerfile.full -t zsh-dotfiles-smoke-full:asdf \
		--build-arg VERSION_MANAGER=asdf \
		--build-arg BASE_IMAGE=zsh-dotfiles-smoke:asdf .

smoke-full-mise:  ## Bake pre-provisioned smoke image (mise lane); requires DOCKER_BUILDKIT=1
	@echo "\033[0;34mBaking pre-provisioned smoke image (mise)...\033[0m"
	DOCKER_BUILDKIT=1 docker build -f Dockerfile -t zsh-dotfiles-smoke:mise \
		--build-arg VERSION_MANAGER=mise \
		--secret id=homebrew_token,env=HOMEBREW_GITHUB_API_TOKEN .
	DOCKER_BUILDKIT=1 docker build -f Dockerfile.full -t zsh-dotfiles-smoke-full:mise \
		--build-arg VERSION_MANAGER=mise \
		--build-arg BASE_IMAGE=zsh-dotfiles-smoke:mise .

smoke-full-run-asdf:  ## Run baked asdf image (interactive zsh)
	docker run --rm -it zsh-dotfiles-smoke-full:asdf

smoke-full-run-mise:  ## Run baked mise image (interactive zsh)
	docker run --rm -it zsh-dotfiles-smoke-full:mise

smoke-full-clean:  ## Remove baked smoke images
	-docker rmi zsh-dotfiles-smoke-full:asdf zsh-dotfiles-smoke-full:mise \
	            zsh-dotfiles-smoke:asdf      zsh-dotfiles-smoke:mise 2>/dev/null || true

# ---------------------------------------------------------------------------
# chezmoi init with good defaults (new-machine provisioning)
#
# Host name / Computer name are autopopulated from this machine; everything
# else defaults to the standard bossjones answers. Override any variable on
# the command line, e.g.:
#   make macos-init-good-defaults-branch CHEZMOI_BRANCH=claude/ruby-4-0-1-upgrade-5a05fa
# ---------------------------------------------------------------------------
CHEZMOI_REPO ?= https://github.com/bossjones/zsh-dotfiles.git
CHEZMOI_BRANCH ?= main
CHEZMOI_HOSTNAME ?= $(shell scutil --get LocalHostName 2>/dev/null || hostname -s)
CHEZMOI_COMPUTER_NAME ?= $(shell scutil --get ComputerName 2>/dev/null || hostname -s)

CHEZMOI_GOOD_DEFAULTS := \
	--promptString "Name=Malcolm Jones" \
	--promptString "Email=bossjones@theblacktonystark.com" \
	--promptString "Computer name=$(CHEZMOI_COMPUTER_NAME)" \
	--promptString "Host name=$(CHEZMOI_HOSTNAME)" \
	--promptString "version_manager=mise" \
	--promptBool "ruby=true" \
	--promptBool "pyenv=true" \
	--promptBool "nodejs=true" \
	--promptBool "k8s=false" \
	--promptBool "cuda=false" \
	--promptBool "fnm=true" \
	--promptBool "opencv=false"

.PHONY: macos-init-good-defaults-source macos-init-good-defaults-branch \
        macos-init-good-defaults-oneliner macos-init-good-defaults-dry-run

macos-init-good-defaults-source:  ## chezmoi init --apply from the current checkout (--source=.)
	@echo "\033[0;34mRunning chezmoi init --apply from --source=. (host: $(CHEZMOI_HOSTNAME))...\033[0m"
	chezmoi init -R --debug -v --apply $(CHEZMOI_GOOD_DEFAULTS) --source=.

macos-init-good-defaults-branch:  ## chezmoi init --apply from GitHub on CHEZMOI_BRANCH (default: main)
	@echo "\033[0;34mRunning chezmoi init --apply from $(CHEZMOI_REPO) branch $(CHEZMOI_BRANCH) (host: $(CHEZMOI_HOSTNAME))...\033[0m"
	chezmoi init -R --debug -v --apply --branch $(CHEZMOI_BRANCH) $(CHEZMOI_GOOD_DEFAULTS) $(CHEZMOI_REPO)

macos-init-good-defaults-oneliner:  ## Install chezmoi via chezmoi.io/get, then init --apply from GitHub
	@echo "\033[0;34mInstalling chezmoi via one-liner and running init --apply (host: $(CHEZMOI_HOSTNAME))...\033[0m"
	sh -c "$$(curl -fsLS chezmoi.io/get)" -- init -R --debug -v --apply $(CHEZMOI_GOOD_DEFAULTS) $(CHEZMOI_REPO)

macos-init-good-defaults-dry-run:  ## Preview what init would do from --source=. without changing anything
	@echo "\033[0;34mDry-running chezmoi init from --source=. (host: $(CHEZMOI_HOSTNAME))...\033[0m"
	chezmoi init -R --debug -v --dry-run $(CHEZMOI_GOOD_DEFAULTS) --source=.

# ---------------------------------------------------------------------------
# fzf-tab opt-in (kept OUT of CHEZMOI_GOOD_DEFAULTS on purpose)
#
# fzf-tab replaces zsh's completion menu with an fzf selector; it is an
# optional add-on, so it lives in its own variable and is only combined with
# the good defaults in the dedicated *-fzf-tab targets below, e.g.:
#   make macos-init-fzf-tab-branch CHEZMOI_BRANCH=feature-fzf-tab
# ---------------------------------------------------------------------------
CHEZMOI_FZF_TAB_DEFAULTS := --promptBool "fzf_tab=true"

.PHONY: macos-init-fzf-tab-source macos-init-fzf-tab-branch \
        macos-init-fzf-tab-oneliner macos-init-fzf-tab-dry-run

macos-init-fzf-tab-source:  ## Good defaults + fzf-tab enabled, init --apply from the current checkout (--source=.)
	@echo "\033[0;34mRunning chezmoi init --apply with fzf-tab from --source=. (host: $(CHEZMOI_HOSTNAME))...\033[0m"
	chezmoi init -R --debug -v --apply $(CHEZMOI_GOOD_DEFAULTS) $(CHEZMOI_FZF_TAB_DEFAULTS) --source=.

macos-init-fzf-tab-branch:  ## Good defaults + fzf-tab enabled, init --apply from GitHub on CHEZMOI_BRANCH (default: main)
	@echo "\033[0;34mRunning chezmoi init --apply with fzf-tab from $(CHEZMOI_REPO) branch $(CHEZMOI_BRANCH) (host: $(CHEZMOI_HOSTNAME))...\033[0m"
	chezmoi init -R --debug -v --apply --branch $(CHEZMOI_BRANCH) $(CHEZMOI_GOOD_DEFAULTS) $(CHEZMOI_FZF_TAB_DEFAULTS) $(CHEZMOI_REPO)

macos-init-fzf-tab-oneliner:  ## Install chezmoi via chezmoi.io/get, then init --apply with fzf-tab from GitHub
	@echo "\033[0;34mInstalling chezmoi via one-liner and running init --apply with fzf-tab (host: $(CHEZMOI_HOSTNAME))...\033[0m"
	sh -c "$$(curl -fsLS chezmoi.io/get)" -- init -R --debug -v --apply $(CHEZMOI_GOOD_DEFAULTS) $(CHEZMOI_FZF_TAB_DEFAULTS) $(CHEZMOI_REPO)

macos-init-fzf-tab-dry-run:  ## Preview good defaults + fzf-tab init from --source=. without changing anything
	@echo "\033[0;34mDry-running chezmoi init with fzf-tab from --source=. (host: $(CHEZMOI_HOSTNAME))...\033[0m"
	chezmoi init -R --debug -v --dry-run $(CHEZMOI_GOOD_DEFAULTS) $(CHEZMOI_FZF_TAB_DEFAULTS) --source=.

# ---------------------------------------------------------------------------
# Link checking (lychee)
#
# lychee scrapes github.com HTML unauthenticated by default, which rate-limits
# into spurious 404s. Passing a token makes lychee use the GitHub API instead.
# Falls back to `gh auth token`, then to empty (unauthenticated) if neither.
# ---------------------------------------------------------------------------
.PHONY: link-check link-check-verbose

link-check:  ## Check all links in markdown files using lychee
	@echo "\033[0;34mChecking all links in markdown files using lychee...\033[0m"
	@GITHUB_TOKEN="$${GITHUB_TOKEN:-$$(gh auth token 2>/dev/null)}" lychee --config lychee.toml '**/*.md'

link-check-verbose:  ## Check all links in markdown files with verbose output
	@echo "\033[0;34mChecking all links in markdown files with verbose output...\033[0m"
	@GITHUB_TOKEN="$${GITHUB_TOKEN:-$$(gh auth token 2>/dev/null)}" lychee --config lychee.toml --verbose debug '**/*.md'

.PHONY: doctor doctor-identity doctor-test smoke-doctor

DOCTOR := ./hack/doctor/doctor.py
DOCTOR_FIXTURE := hack/doctor/tests/fixtures/ci.yaml

doctor:  ## Run the convergence doctor against this machine
	@$(DOCTOR)

doctor-identity:  ## Probe every macOS hostname source (works with no profile)
	@$(DOCTOR) --identity

doctor-test:  ## Unit-test the doctor (layers 1-5; no real system access)
	@uv run --quiet --with pytest --with pyyaml --with jsonschema \
		pytest hack/doctor/tests -q

smoke-doctor:  ## Prove doctor.py runs from scratch and honours its exit codes
	@echo "\033[0;34mSmoke-testing hack/doctor/doctor.py...\033[0m"
	@$(DOCTOR) --validate
	@$(DOCTOR) --validate --format json >/dev/null
	@rc=0; $(DOCTOR) --config $(DOCTOR_FIXTURE) --profile fake --state target \
		>/dev/null 2>&1 || rc=$$?; \
		[ $$rc -eq 1 ] || { echo "expected exit 1 from the failing fixture, got $$rc"; exit 1; }
	@rc=0; $(DOCTOR) --profile nonesuch >/dev/null 2>&1 || rc=$$?; \
		[ $$rc -eq 3 ] || { echo "expected exit 3 for an unknown profile, got $$rc"; exit 1; }
	@$(DOCTOR) --identity --format json | python3 -m json.tool >/dev/null
	@echo "\033[0;32m✓ smoke-doctor passed\033[0m"
