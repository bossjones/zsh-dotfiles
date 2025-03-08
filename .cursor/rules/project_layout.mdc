---
description: Documentation of the zsh-dotfiles project structure and organization
globs: **/*.md, **/*.py, **/*.mdc
alwaysApply: false
---
# zsh-dotfiles Project Layout

Rules for understanding and navigating the zsh-dotfiles repository structure.

<rule>
name: project_layout_guide
description: Guide to the zsh-dotfiles project structure and organization
filters:
  # Match any file in the project
  - type: file_extension
    pattern: ".*"
  # Match project initialization events
  - type: event
    pattern: "file_create"

actions:
  - type: suggest
    message: |
      # zsh-dotfiles Project Structure

      This repository implements a comprehensive dotfiles management system with AI-powered documentation and analysis capabilities.

      ## Core Features

      - **Dotfiles Management:** Organized ZSH configuration and customization
      - **AI Documentation:** Automated documentation generation and analysis
      - **Testing Framework:** Comprehensive test suite for utilities and functions
      - **Python Utilities:** Helper scripts and tools for repository management
      - **Documentation Standards:** Guidelines for maintaining clear documentation

      ## Directory Structure

      ```
      .
      ├── .cursor/                     # Active cursor rules directory
      │   └── rules/                   # Production cursor rules
      ├── Makefile                     # Build automation
      ├── README.md                    # Project overview and setup instructions
      ├── ai_docs/                     # AI-generated documentation
      │   ├── reports/                 # Analysis reports
      │   └── summaries/              # Code summaries
      ├── src/                         # Python source code
      │   └── goob_ai/                 # Core AI utilities
      ├── tests/                       # Test suites
      │   ├── integration/             # Integration tests
      │   └── unittests/               # Unit tests
      │       └── utils/               # Utility test modules
      └── zsh/                         # ZSH configuration files
          ├── aliases/                 # Shell aliases
          ├── functions/               # Shell functions
          └── plugins/                 # ZSH plugins
      ```

      ## Primary Components

      ### ZSH Configuration (`zsh/`)
      Core shell configuration files including aliases, functions, and plugin management.

      ### AI Documentation (`ai_docs/`)
      Generated documentation and analysis reports for the codebase:
      - `reports/`: Detailed analysis of repository components
      - `summaries/`: Code summaries and documentation

      ### Source Code (`src/`)
      Python utilities and AI-related tools for repository management.

      ### Tests (`tests/`)
      Comprehensive test suite using pytest for both unit and integration tests, with full type annotations and documentation.

      ## Development Workflow

      ### Documentation Generation
      - AI-powered analysis of repository components
      - Automated report generation
      - Documentation updates based on code changes

      ### Testing
      - Run unit tests: `pytest tests/unittests/`
      - Run integration tests: `pytest tests/integration/`
      - Generate test coverage reports

      ### Code Standards
      - Follow Python best practices with type hints and docstrings
      - Maintain consistent ZSH scripting style
      - Keep documentation up-to-date with code changes

examples:
  - input: |
      # I'm new to the project, where should I put my ZSH functions?
    output: |
      For ZSH functions, use the `zsh/functions/` directory. Follow the existing naming conventions and documentation patterns in that directory.

  - input: |
      # How do I add new tests?
    output: |
      For testing Python utilities:
      1. Create test files in `tests/unittests/` or `tests/integration/` as appropriate
      2. Follow pytest conventions with proper typing and docstrings
      3. Run tests using pytest to verify functionality

metadata:
  priority: high
  version: 1.0
  tags:
    - project-structure
    - organization
    - zsh-configuration
</rule>

<rule>
name: project_standards
description: Standards for code quality and organization in the zsh-dotfiles project
filters:
  # Match any file in the project
  - type: file_extension
    pattern: ".*"
  # Match project initialization events
  - type: event
    pattern: "file_create"

actions:
  - type: suggest
    message: |
      # zsh-dotfiles Project Standards

      ## Python Standards

      - **Code Style**: Follow PEP 8
      - **Type Hints**: Required for all functions and classes
      - **Docstrings**: PEP 257 format required
      - **Max Line Length**: 88 characters
      - **Testing**: pytest with type annotations

      ## Cursor Rules Standards

      - **Format**: MDC (Markdown Configuration)
      - **Required Sections**: frontmatter, rule definition, examples, metadata
      - **Development**: Create in `hack/drafts/cursor_rules/`
      - **Deployment**: Use `make update-cursor-rules` to deploy

      ## Workspace Package Standards

      - **Format**: src layout with pyproject.toml
      - **Required Sections**: name, version, dependencies, development dependencies
      - **Management**: UV workspace commands via Makefile
      - **Dependency Resolution**: Central requirements.lock
      - **Version Control**: Individual package versioning

      ## Validation Requirements

      - All Python code must have type hints
      - Each function and class must have PEP 257 docstrings
      - All code must have corresponding tests
      - Tests must have type annotations
      - Each major directory must have a README.md
      - Cursor rules must follow proper MDC format
      - Workspace packages must follow src layout

examples:
  - input: |
      # What are the requirements for Python code in this project?
    output: |
      Python code in this project must:
      1. Follow PEP 8 style guidelines
      2. Include comprehensive type hints for all functions and classes
      3. Have PEP 257 docstrings for all functions and classes
      4. Be accompanied by pytest tests with type annotations
      5. Follow the src layout for packages

  - input: |
      # How should I structure a new package?
    output: |
      New packages should follow the src layout:
      ```
      package-name/
      ├── pyproject.toml
      ├── src/
      │   └── package_name/
      │       ├── __init__.py
      │       └── module.py
      └── tests/
          └── test_module.py
      ```

      Use `make uv-workspace-init-package name=my-package` to create this structure automatically.

metadata:
  priority: high
  version: 1.0
  tags:
    - standards
    - code-quality
    - organization
</rule>
