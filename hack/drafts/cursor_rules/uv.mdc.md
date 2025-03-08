---
description: UV Package Manager and Environment Management Guidelines
globs: *.py, pyproject.toml, Makefile, *.mk
alwaysApply: false
---
# UV Package Manager Guidelines

Guidelines for using UV as the primary package manager and Python environment tool in this repository.

<rule>
name: uv
description: Standards for UV usage across the project
filters:
  # Match Python files and dependency files
  - type: file_extension
    pattern: "\\.(py|toml)$"
  # Match Makefiles
  - type: file_path
    pattern: "(Makefile|.*\\.mk)$"
  # Match package installation code
  - type: content
    pattern: "(pip install|requirements\\.txt|uv )"

actions:
  - type: suggest
    message: |
      # UV Best Practices

      This project uses UV as the primary package manager and Python environment management tool.

      ## Key Guidelines

      1. **Never use `uv pip install`**, instead:
         - Use `uv add` for adding individual packages
         - Use `uv sync` for installing from pyproject.toml/lockfile

      2. **Environment Setup**:
         ```bash
         # Create a virtual environment with specific Python version
         uv venv --python 3.12.0

         # Install dependencies using lockfile
         uv sync --frozen
         ```

      3. **Dependency Management**:
         ```bash
         # Add a development dependency
         uv add --dev pytest

         # Add a production dependency
         uv add fastapi

         # Sync dependencies from lockfile
         uv sync --frozen
         ```

      4. **Make Tasks**:
         - Use `make uv-sync-all` for syncing all dependencies
         - Use `make uv-sync-dev` for syncing development dependencies
         - Use `make uv-upgrade-package package=name` to upgrade a specific package

      5. **Running Code**:
         ```bash
         # Run Python code
         uv run python script.py

         # Run modules
         uv run python -m module_name

         # Run tests
         uv run pytest tests/
         ```

examples:
  - input: |
      # Bad: Using pip install
      pip install requests

      # Bad: Using UV with pip install
      uv pip install requests

      # Good: Using UV properly
      uv add requests
      uv sync --frozen
    output: "Properly using UV for package management"

  - input: |
      # Bad: Running Python directly
      python -m pytest tests/

      # Good: Using UV to run Python
      uv run pytest tests/

      # Good: Using make targets
      make local-unittest
    output: "Correctly using UV for running Python code"

metadata:
  priority: high
  version: 1.0
  tags:
    - development
    - package-management
    - python
</rule>

## Make Tasks for UV

Add the following targets to your Makefile to streamline UV operations:

```makefile
# UV Package Management
.PHONY: uv-sync-all uv-sync-dev uv-check-lock uv-verify uv-verify-dry-run uv-upgrade-all uv-upgrade-package uv-reinstall-all uv-reinstall-package uv-outdated uv-clean-cache uv-export-requirements

# Sync all dependencies with frozen lockfile
uv-sync-all:
	uv sync --frozen

# Sync only development dependencies
uv-sync-dev:
	uv sync --frozen --dev

# Sync dependencies for a specific group
uv-sync-group:
	uv sync --frozen --group $(group)

# Check lockfile consistency (prevents updates)
uv-check-lock:
	uv pip compile --check-lock pyproject.toml

# Verify lockfile is up to date
uv-verify:
	uv pip compile pyproject.toml

# Verify lockfile (dry run)
uv-verify-dry-run:
	uv pip compile --dry-run pyproject.toml

# Preview potential upgrades (dry run)
uv-upgrade-dry-run:
	uv pip compile --upgrade --dry-run pyproject.toml

# Upgrade all dependencies
uv-upgrade-all:
	uv pip compile --upgrade pyproject.toml

# Upgrade specific package
uv-upgrade-package:
	uv pip compile --upgrade-package $(package) pyproject.toml

# Reinstall all packages
uv-reinstall-all:
	uv sync --reinstall --frozen

# Reinstall specific package
uv-reinstall-package:
	uv sync --reinstall-package $(package) --frozen

# List outdated packages
uv-outdated:
	uv pip list --outdated

# Clean UV cache
uv-clean-cache:
	uv cache clean

# Export requirements without hashes
uv-export-requirements:
	uv pip export --without-hashes pyproject.toml -o requirements.txt

# Export with specific resolution strategy
uv-export-requirements-resolution:
	uv pip export --without-hashes --resolution $(strategy) pyproject.toml -o requirements.txt
```

## Python Environment Management

UV can install and manage Python interpreters directly:

```bash
# Install specific Python versions
uv python install 3.10 3.11 3.12

# Create a virtual environment with a specific Python version
uv venv --python 3.12.0

# Pin a specific Python version for the project
uv python pin 3.12.0
```

## Common Issues and Solutions

### Environment Activation Check

```bash
if [ -z "$VIRTUAL_ENV" ] && [ -z "$CONDA_PREFIX" ]; then
    echo "Error: Not running in a virtual environment or conda environment."
    echo "Please activate your environment first."
    echo "For UV: source .venv/bin/activate"
    exit 1
fi
```
