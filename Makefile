sync:
	@uv sync --all-extras
	uv run pre-commit install

pre-commit:
	uv run pre-commit run -a

test:
	py.test --tb=short --no-header --showlocals --reruns 6 test_dotfiles.py test_scripts_backup_dotfiles.py test_scripts_check_jsonc.py

test-pdb:
	py.test --pdb --pdbcls bpdb:BPdb --tb=short --no-header --showlocals test_dotfiles.py test_scripts_backup_dotfiles.py test_scripts_check_jsonc.py

uv-test:
	uv run pytest -vvvv --tb=short --no-header --showlocals --reruns 6 --durations-min=0.05 --durations=10 test_dotfiles.py test_scripts_backup_dotfiles.py test_scripts_check_jsonc.py

uv-test-pdb:
	uv run pytest --pdb --pdbcls bpdb:BPdb --tb=short --no-header --showlocals test_dotfiles.py test_scripts_backup_dotfiles.py test_scripts_check_jsonc.py

.PHONY: update-cursor-rules
update-cursor-rules:  ## Update cursor rules from prompts/drafts/cursor_rules
	# Create .cursor/rules directory if it doesn't exist.
	# Note: at the time of writing, cursor does not support generating .mdc files via Composer Agent.s
	mkdir -p .cursor/rules || true
	# Copy files from prompts/drafts/cursor_rules to .cursor/rules and change extension to .mdc
	# Exclude README.md files from being copied
	find hack/drafts/cursor_rules -type f -name "*.md" ! -name "README.md" -exec sh -c 'for file; do target=$${file%.md}; cp -a "$$file" ".cursor/rules/$$(basename "$$target")"; done' sh {} +

.PHONY: install-hooks
install-hooks:
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
