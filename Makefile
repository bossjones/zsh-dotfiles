test:
	py.test --tb=short --no-header --showlocals --reruns 6 test_dotfiles.py

test-pdb:
	py.test --pdb --pdbcls bpdb:BPdb --tb=short --no-header --showlocals test_dotfiles.py

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

.PHONY: smoke smoke-lint smoke-build smoke-shell smoke-clean
smoke:  ## Run full smoke test in Docker (reproduces CI)
	@echo "\033[0;34mRunning smoke test in Docker...\033[0m"
	docker-compose up --build smoke

smoke-lint:  ## Run lint stage only in Docker
	@echo "\033[0;34mRunning lint stage in Docker...\033[0m"
	docker-compose run --rm smoke lint

smoke-build:  ## Run build stage only in Docker
	@echo "\033[0;34mRunning build stage in Docker...\033[0m"
	docker-compose run --rm smoke build

smoke-shell:  ## Start interactive shell for debugging smoke test failures
	@echo "\033[0;34mStarting interactive smoke test shell...\033[0m"
	docker-compose run --rm smoke-shell

smoke-clean:  ## Clean up smoke test Docker resources
	@echo "\033[0;34mCleaning up smoke test containers...\033[0m"
	docker-compose down --rmi local --volumes --remove-orphans
