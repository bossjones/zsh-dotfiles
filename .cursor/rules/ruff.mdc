---
description: Ruff linting configuration and usage guidelines
globs: *.py
alwaysApply: false
---
# Ruff Configuration Guide

When you have questions about Ruff linting configuration, need help with linting rules, or want to run Ruff commands in this project, I can provide guidance based on the project's configuration.

## Running Ruff Commands

```bash
# Check linting issues in a file or directory
uv run ruff check path/to/file_or_dir

# Fix auto-fixable issues
uv run ruff check --fix path/to/file_or_dir

# Format code using Ruff formatter
uv run ruff format path/to/file_or_dir
```

## Project Configuration Overview

This project uses Ruff with the following configuration:

### Basic Settings
- Target Python version: 3.12
- Line length: 120 characters
- Includes Python files (`.py`, `.pyi`) and Jupyter notebooks (`.ipynb`)
- Respects `.gitignore` for excluding files

### Selected Rule Categories
- `D`: pydocstyle (PEP257 convention)
- `E`: pycodestyle
- `F`: Pyflakes
- `UP`: pyupgrade
- `B`: flake8-bugbear
- `I`: isort
- `S`: bandit (security)
- `YTT`: flake8-2020
- `A`: flake8-builtins
- `C4`: flake8-comprehensions
- `T10`: flake8-debugger
- `SIM`: flake8-simplify
- `C90`: mccabe (complexity checking)
- `W`: pycodestyle warnings
- `PGH`: pygrep-hooks
- `RUF`: ruff-specific rules

### Major Ignore Rules
- `B008`: Function calls in default arguments
- `D417`: Not requiring documentation for every function parameter
- `E501`: Line length limitations
- `UP006/UP007`: Type annotation format rules
- `S101`: Allows `assert` statements
- `F401`: Unused imports in certain files
- `N812`: Lowercase imported as non-lowercase
- Many more rules listed in the configuration

### Special Configurations
- isort configuration with custom section ordering
- flake8-type-checking with runtime-evaluated settings for Pydantic
- Per-file ignores for specific file types
- Different mccabe complexity levels

### Per-file Ignores
Special ignore configurations are applied to:
- `__init__.py` files: `["F401", "E402"]`
- Test files: `["D", "C410", "S311", "S103"]`
- Type stub files: `["D", "E501", "E701", "I002"]`
- Documentation and example files: `["D"]`

## Using Ruff with Editor Integration

Most modern code editors provide Ruff integration:

### VS Code
Install the Ruff extension and add to settings.json:
```json
{
    "editor.formatOnSave": true,
    "ruff.enable": true,
    "ruff.format.args": ["--preview"],
    "[python]": {
        "editor.defaultFormatter": "charliermarsh.ruff",
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
            "source.fixAll.ruff": "explicit",
            "source.organizeImports.ruff": "explicit"
        }
    }
}
```

## Troubleshooting Common Issues

If you encounter linting errors, I can help you understand and fix them by:
1. Identifying which rule is triggering
2. Explaining the purpose of the rule
3. Suggesting ways to fix the issue or properly ignore it
4. Explaining when to use per-file ignores vs. inline ignores

## Ignore Strategies

### Inline Ignores
```python
# Example of inline ignore for a single rule
my_long_line = "..." # noqa: E501

# Example of inline ignore for multiple rules
from module import unused_import  # noqa: F401, E501
```

### File-level Ignores
Add to pyproject.toml:
```toml
[tool.ruff.lint.per-file-ignores]
"your/file/path.py" = ["E501", "F401"]
"tests/**/*.py" = ["D", "S101"]
```

### Global Ignores
To globally ignore rules in pyproject.toml:
```toml
[tool.ruff.lint]
ignore = ["E501", "B008"]
```

## Modern Ruff Configuration Structure

The latest Ruff configuration structure separates linting and formatting settings:

```toml
[tool.ruff]
# Basic settings
target-version = "py312"
line-length = 120
# Files to include
include = ["*.py", "*.pyi", "*.ipynb"]
exclude = [
    ".bzr",
    ".direnv",
    ".eggs",
    ".git",
    ".git-rewrite",
    ".hg",
    ".mypy_cache",
    ".nox",
    ".pants.d",
    ".pyenv",
    ".pytest_cache",
    ".pytype",
    ".ruff_cache",
    ".svn",
    ".tox",
    ".venv",
    ".vscode",
    "__pypackages__",
    "_build",
    "buck-out",
    "build",
    "dist",
    "node_modules",
    "venv",
]
# Allow imports relative to the "src" and "test" directories
src = ["src", "tests"]
# Allow unused variables when underscore-prefixed
dummy-variable-rgx = "^(_+|(_+[a-zA-Z0-9_]*[a-zA-Z0-9]+?))$"

# Linting-specific settings
[tool.ruff.lint]
select = [
    "D",    # pydocstyle (PEP257)
    "E",    # pycodestyle errors
    "F",    # pyflakes
    "UP",   # pyupgrade
    "B",    # flake8-bugbear
    "I",    # isort
    "S",    # bandit (security)
    "YTT",  # flake8-2020
    "A",    # flake8-builtins
    "C4",   # flake8-comprehensions
    "T10",  # flake8-debugger
    "SIM",  # flake8-simplify
    "C90",  # mccabe (complexity)
    "W",    # pycodestyle warnings
    "PGH",  # pygrep-hooks
    "RUF",  # ruff-specific rules
]
ignore = [
    "B008",  # Function calls in default arguments
    "D417",  # Missing argument descriptions in docstrings
    "E501",  # Line too long (handled by formatter)
    "UP006", # Type annotation format
    "UP007", # Type annotation format
    "S101",  # Use of assert detected
    "N812",  # Lowercase imported as non-lowercase
]
# Allow all rules to be auto-fixed
fixable = ["ALL"]
unfixable = []

# Maximum McCabe complexity allowed
[tool.ruff.lint.mccabe]
max-complexity = 10

# Pydocstyle configuration
[tool.ruff.lint.pydocstyle]
convention = "pep257"

# Flake8-type-checking configuration
[tool.ruff.lint.flake8-type-checking]
runtime-evaluated-decorators = [
    "pydantic.computed_field",
    "pydantic.model_validator"
]

# isort settings
[tool.ruff.lint.isort]
case-sensitive = true
force-single-line = false
force-sort-within-sections = true
known-first-party = ["codegen_lab"]
required-imports = ["from __future__ import annotations"]
combine-as-imports = true
split-on-trailing-comma = false
# Define sections for imports
sections = [
    "future",
    "standard-library",
    "third-party",
    "pytest",
    "first-party",
    "local-folder",
]
# Define known third-party libraries
known-third-party = [
    "better_exceptions",
    "fastapi",
    "pydantic",
    "rich",
    "tenacity",
    "uvicorn",
]
# Known pytest modules for the pytest section
known-pytest = ["pytest", "_pytest"]

# Per-file ignores
[tool.ruff.lint.per-file-ignores]
# Ignore unused imports and import order in __init__.py files
"__init__.py" = ["F401", "E402"]
# Ignore missing docstrings and some other rules in tests
"tests/**/*.py" = ["D", "C410", "S311", "S103"]
# Ignore missing docstrings and line length in type stubs
"**/*.pyi" = ["D", "E501", "E701", "I002"]
# Ignore missing docstrings in docs and examples
"docs/**/*.py" = ["D"]
"examples/**/*.py" = ["D"]

# Formatting settings (commented out in this project but included for completeness)
[tool.ruff.format]
quote-style = "double"
indent-style = "space"
line-ending = "auto"
docstring-code-format = false
```

## Import Organization with isort

The project uses the following isort configuration via Ruff:

```toml
[tool.ruff.lint.isort]
case-sensitive = true
force-single-line = false
force-sort-within-sections = true
known-first-party = ["codegen_lab"]
required-imports = ["from __future__ import annotations"]
combine-as-imports = true
split-on-trailing-comma = false
# Define sections for imports
sections = [
    "future",
    "standard-library",
    "third-party",
    "pytest",
    "first-party",
    "local-folder",
]
# Define known third-party libraries
known-third-party = [
    "better_exceptions",
    "fastapi",
    "pydantic",
    "rich",
    "tenacity",
    "uvicorn",
]
# Known pytest modules for the pytest section
known-pytest = ["pytest", "_pytest"]
