---
description: GitHub Actions with UV Package Manager Standards
globs: .github/workflows/*.yml
alwaysApply: false
---
# GitHub Actions with UV Standards

Guidelines for using UV package manager in GitHub Actions workflows.

<rule>
name: github-actions-uv
description: Standards for using UV in GitHub Actions workflows
filters:
  # Match GitHub Actions workflow files
  - type: file_path
    pattern: "\\.github/workflows/.*\\.yml$"
  # Match content related to Python package installation
  - type: content
    pattern: "(pip install|python -m pip|setup\\.py|requirements\\.txt|uv )"

actions:
  - type: suggest
    message: |
      # UV Best Practices for GitHub Actions

      When working with Python in GitHub Actions workflows, follow these UV standards:

      ## 1. Installing UV

      ### Preferred: Use the Official Action

      The official `astral-sh/setup-uv` action is recommended for installing UV:

      ```yaml
      - name: Install UV
        uses: astral-sh/setup-uv@v5
        with:
          # Pin to a specific version for stability
          version: "0.6.3"
      ```

      ### Alternative: Manual Installation

      If you prefer manual installation:

      ```yaml
      - name: Install UV
        run: |
          curl -LsSf https://astral.sh/uv/install.sh | sh
          echo "$HOME/.cargo/bin" >> $GITHUB_PATH
      ```

      ## 2. Setting Up Environment

      Create a virtual environment using UV:

      ```yaml
      - name: Create virtual environment
        run: |
          uv venv
      ```

      ## 3. Installing Dependencies

      ### Preferred: Use Makefile Targets

      ```yaml
      # For documentation dependencies
      - name: Install dependencies
        run: |
          # Set up a virtual environment
          uv venv
          # Install documentation dependencies using the Makefile target
          make docs-setup
      ```

      ### Alternative: Direct UV Commands

      If you must install packages directly (e.g., simple workflows), use `uv add` instead of `uv pip install`:

      ```yaml
      # NEVER DO THIS
      - name: Bad practice
        run: |
          uv pip install package-name

      # DO THIS INSTEAD
      - name: Good practice
        run: |
          uv add package-name
      ```

      ## 4. Running Python Code

      Always use `uv run` to execute Python code:

      ```yaml
      # NEVER DO THIS
      - name: Bad practice
        run: |
          python script.py
          pytest tests/

      # DO THIS INSTEAD
      - name: Good practice
        run: |
          uv run python script.py
          uv run pytest tests/
      ```

      ## 5. Using Existing Makefile Targets

      Prefer using existing Makefile targets when available:

      ```yaml
      # For running tests
      - name: Run tests
        run: |
          make test

      # For documentation
      - name: Build docs
        run: |
          make docs-build

      # For deployment
      - name: Deploy docs
        run: |
          make docs-deploy
      ```

      ## 6. Matrix Testing with Multiple Python Versions

      When testing against multiple Python versions, use a matrix strategy:

      ```yaml
      jobs:
        test:
          runs-on: ubuntu-latest
          strategy:
            matrix:
              python-version: ["3.9", "3.10", "3.11", "3.12"]

          steps:
            - uses: actions/checkout@v4

            - name: Set up Python ${{ matrix.python-version }}
              uses: actions/setup-python@v5
              with:
                python-version: ${{ matrix.python-version }}

            - name: Install UV
              uses: astral-sh/setup-uv@v5

            - name: Install dependencies
              run: |
                uv venv
                uv sync

            - name: Run tests
              run: |
                uv run pytest
      ```

      You can also use UV to install Python directly:

      ```yaml
      - name: Install Python with UV
        run: |
          uv python install ${{ matrix.python-version }}
      ```

examples:
  - input: |
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install mkdocs mkdocs-material

      - name: Deploy
        run: |
          mkdocs gh-deploy --force
    output: |
      This workflow should be updated to use UV instead of pip:

      ```yaml
      - name: Install UV
        run: |
          curl -LsSf https://astral.sh/uv/install.sh | sh
          echo "$HOME/.cargo/bin" >> $GITHUB_PATH

      - name: Install dependencies
        run: |
          uv venv
          make docs-setup

      - name: Deploy
        run: |
          make docs-deploy
      ```

  - input: |
      - name: Run tests
        run: |
          python -m pytest
    output: |
      This should be updated to use UV:

      ```yaml
      - name: Run tests
        run: |
          uv run pytest
      # Or preferably using the Makefile target:
      - name: Run tests
        run: |
          make test
      ```

metadata:
  priority: high
  version: 1.0
  tags:
    - github-actions
    - uv
    - package-management
    - python
    - ci-cd
</rule>

## Common GitHub Actions + UV Patterns

### Python Version Setup

```yaml
- name: Set up Python
  uses: actions/setup-python@v5
  with:
    python-version: '3.12'
    # NO CACHE: 'pip' PARAMETER - we use UV instead
```

### Documentation Workflow

```yaml
- name: Install UV
  run: |
    curl -LsSf https://astral.sh/uv/install.sh | sh
    echo "$HOME/.cargo/bin" >> $GITHUB_PATH

- name: Install dependencies
  run: |
    uv venv
    make docs-setup

- name: Deploy documentation
  run: |
    touch .nojekyll  # Disable Jekyll for GitHub Pages
    git config --global user.name "GitHub Actions"
    git config --global user.email "actions@github.com"
    make docs-deploy
```

### Python Testing Workflow

```yaml
- name: Install UV
  run: |
    curl -LsSf https://astral.sh/uv/install.sh | sh
    echo "$HOME/.cargo/bin" >> $GITHUB_PATH

- name: Install dependencies
  run: |
    uv venv
    uv sync --frozen

- name: Run tests
  run: |
    make test
```

### Dependency Caching

#### Preferred: Using setup-uv Built-in Caching

The `setup-uv` action has built-in caching:

```yaml
- name: Install UV with caching
  uses: astral-sh/setup-uv@v5
  with:
    cache: true
```

#### Alternative: Manual Caching

If you need more control over caching:

```yaml
- name: Cache UV data
  uses: actions/cache@v3
  with:
    path: |
      ~/.cache/uv
      ~/.cache/uv/installs
      ~/.cargo/bin/uv
    key: ${{ runner.os }}-uv-${{ hashFiles('**/pyproject.toml', '**/requirements.txt') }}
    restore-keys: |
      ${{ runner.os }}-uv-
```

#### Pruning the Cache

To keep your cache size manageable in CI:

```yaml
- name: Prune UV cache
  run: uv cache prune --ci
```

### Environment Variables

UV provides several environment variables to control behavior in CI:

```yaml
- name: Install and run with UV
  env:
    # Use project-specific environment settings
    UV_PROJECT_ENVIRONMENT: true
    # Avoid interactive prompts in CI
    UV_NO_PROMPT: 1
  run: |
    uv venv
    uv sync
    uv run pytest
```

### Cross-Platform Shell Handling

When your workflow needs to run on multiple operating systems (Linux, macOS), ensure proper shell configuration:

```yaml
jobs:
  deploy:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest]
        # Uncomment to run on multiple platforms:
        # os: [ubuntu-latest, macos-latest]
    steps:
      # ... other steps ...

      - name: Set shell path
        id: set-shell
        shell: bash
        run: |
          if [[ "$RUNNER_OS" == "macOS" ]]; then
            echo "SHELL_PATH=/opt/homebrew/bin/zsh" >> $GITHUB_ENV
          else
            echo "SHELL_PATH=/bin/bash" >> $GITHUB_ENV
          fi
          echo "Shell path set to: $SHELL_PATH"

      # Use the configured shell in steps that need it
      - name: Run command with OS-specific shell
        shell: ${{ env.SHELL_PATH }} -e {0}
        run: |
          # Your commands here
```

This approach:
- Automatically selects the appropriate shell for each platform
- Ensures macOS can use Homebrew's zsh when available
- Falls back to bash on Linux which is guaranteed to be available
- Maintains consistent shell behavior across steps

### Common Pitfalls to Avoid

1. **Don't use pip with UV**: Never mix `pip install` commands with UV commands
2. **Don't use `uv pip install`**: Always use `uv add` or Makefile targets instead
3. **Don't run Python directly**: Always use `uv run python` or `make` targets
4. **Don't specify caching mechanism for pip**: When using UV, don't use pip caching
5. **Avoid `--user` flag**: UV creates and manages its own environments

Remember to update existing workflows when they are modified, and ensure all new workflows follow these standards.

## Complete Workflow Example

Here's a complete workflow example that follows all best practices:

```yaml
name: Python Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest]
        python-version: ["3.9", "3.10", "3.11", "3.12"]

    steps:
    - uses: actions/checkout@v4

    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v5
      with:
        python-version: ${{ matrix.python-version }}

    - name: Set shell path
      id: set-shell
      shell: bash
      run: |
        if [[ "$RUNNER_OS" == "macOS" ]]; then
          echo "SHELL_PATH=/opt/homebrew/bin/zsh" >> $GITHUB_ENV
        else
          echo "SHELL_PATH=/bin/bash" >> $GITHUB_ENV
        fi
        echo "Shell path set to: $SHELL_PATH"

    - name: Install UV
      uses: astral-sh/setup-uv@v5
      with:
        cache: true
        version: "0.6.3"

    - name: Install dependencies
      env:
        UV_PROJECT_ENVIRONMENT: true
        UV_NO_PROMPT: 1
      shell: ${{ env.SHELL_PATH }} -e {0}
      run: |
        uv venv
        uv sync

    - name: Lint
      shell: ${{ env.SHELL_PATH }} -e {0}
      run: |
        uv run ruff check .
        uv run ruff format --check .

    - name: Type check
      shell: ${{ env.SHELL_PATH }} -e {0}
      run: |
        uv run mypy .

    - name: Run tests
      shell: ${{ env.SHELL_PATH }} -e {0}
      run: |
        uv run pytest --cov=./ --cov-report=xml

    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v4
      with:
        file: ./coverage.xml
        fail_ci_if_error: true

    - name: Prune cache
      shell: ${{ env.SHELL_PATH }} -e {0}
      run: uv cache prune --ci
```

This workflow demonstrates:
- Using the official setup-uv action with caching
- Matrix testing across multiple Python versions
- Using appropriate environment variables
- Following the sync and run pattern
- Cleaning up the cache with pruning
- Running all commands through UV
- Cross-platform shell handling
