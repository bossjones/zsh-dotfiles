---
description: Documentation Standards and Workflows for Codegen Lab
globs: *.md, mkdocs.yml, scripts/serve_docs.py
alwaysApply: false
---
# Documentation Standards and Workflows

Guidelines for creating, editing, and serving documentation for the Codegen Lab project.

<rule>
name: documentation_standards
description: Standards for documentation in markdown files
filters:
  # Match documentation files
  - type: file_extension
    pattern: "\\.md$"
  # Match MkDocs configuration
  - type: file_path
    pattern: "mkdocs\\.yml$"
  # Match documentation scripts
  - type: file_path
    pattern: "scripts/serve_docs\\.py$"

actions:
  - type: suggest
    message: |
      # Documentation Best Practices

      This project uses MkDocs with the Material theme for documentation. Follow these guidelines:

      ## Content Guidelines

      1. **Structure**:
         - Use consistent heading levels (# for title, ## for sections, etc.)
         - Keep paragraphs concise and focused
         - Use lists for steps or multiple related items

      2. **Formatting**:
         - Use **bold** for emphasis and UI elements
         - Use *italics* for introducing new terms
         - Use `code blocks` for commands, code snippets, or file paths

      3. **Code Samples**:
         - Use fenced code blocks with language specification
         ```python
         def example_function():
             """Example docstring."""
             return True
         ```

      4. **Admonitions**:
         - Use note, warning, tip, etc. for important callouts
         ```markdown
         !!! note
             Important information that users should know about.
         ```

      ## Local Development Workflow

      1. **Serving Documentation**:
         ```bash
         # Serve docs with local URL (http://127.0.0.1:8000/)
         make docs-serve
         ```

      2. **Building Only**:
         ```bash
         make docs-build
         ```

      3. **Important Notes**:
         - The `serve_docs.py` script automatically handles URL configuration
         - NEVER delete the `mkdocs.yml.bak` file - it's essential for deployment
         - The `.bak` file preserves GitHub Pages configuration
         - Changes to docs are hot-reloaded when served locally

examples:
  - input: |
      # Bad: Inconsistent formatting
      The project uses PYTHON for development.

      # Good: Proper formatting
      The project uses `Python` for development.

      # Using admonitions properly
      !!! warning
          Ensure all dependencies are installed before running this command.
    output: "Properly formatted documentation with consistent style"

  - input: |
      # Bad: Incorrect code block
      The command is:
      ```
      uv run python script.py
      ```

      # Good: Language-specific code block
      The command is:
      ```bash
      uv run python script.py
      ```
    output: "Proper use of language-specific code blocks"

metadata:
  priority: high
  version: 1.0
  tags:
    - documentation
    - markdown
    - mkdocs
</rule>

## MkDocs Configuration

The documentation is built using MkDocs with the Material theme. Key configuration:

```yaml
# Theme configuration
theme:
  name: material
  palette:
    primary: indigo
    accent: indigo
  features:
    - navigation.instant
    - navigation.tracking
    - navigation.expand
    - navigation.indexes
    - navigation.top
    - search.highlight
    - search.share
    - content.code.copy

# Extensions
markdown_extensions:
  - admonition
  - codehilite
  - toc:
      permalink: true
  - pymdownx.highlight
  - pymdownx.inlinehilite
  - pymdownx.snippets
  - pymdownx.superfences
```

## Documentation Structure

Follow this structure when adding new content:

```
docs/
├── index.md              # Main landing page
├── getting-started.md    # Getting started guide
├── user-guide/           # User guide directory
│   ├── installation.md   # Installation instructions
│   └── configuration.md  # Configuration guidelines
├── api-reference.md      # API documentation
├── troubleshooting.md    # Troubleshooting guide
├── contributing.md       # Contribution guidelines
└── changelog.md          # Version history
```

## URL Configuration Mechanism

The project uses a clever mechanism to handle two URL patterns:

1. **Local Development URL**: `http://127.0.0.1:8000/`
   - Makes local testing easier with simpler URLs
   - No `/codegen-lab/` path suffix in URLs
   - Enabled automatically with `make docs-serve`

2. **GitHub Pages URL**: `https://bossjones.github.io/codegen-lab/`
   - Required for production deployment
   - Includes the `/codegen-lab/` path suffix in URLs

### How the URL Switching Works:

The `serve_docs.py` script manages this process automatically:

1. When running with `--no-gh-deploy-url` flag:
   - Creates a backup of `mkdocs.yml` as `mkdocs.yml.bak`
   - Modifies the live `mkdocs.yml` to use `http://127.0.0.1:8000/` as `site_url`
   - This removes the `/codegen-lab/` path from all URLs

2. When the server stops (or if an error occurs):
   - Restores the original configuration from `mkdocs.yml.bak`
   - This ensures the GitHub Pages URL is ready for deployment

**Important:** Never delete the `.bak` file as it's essential for this workflow!

## Available Documentation Commands

The Makefile includes these documentation-related targets:

```makefile
# Documentation targets
.PHONY: docs-serve docs-build docs-deploy docs-clean

# Serve documentation locally (with local URL)
docs-serve:
	uv run python scripts/serve_docs.py --no-gh-deploy-url

# Build documentation without serving
docs-build:
	uv run python scripts/serve_docs.py --build-only

# Clean and build documentation
docs-clean-build:
	uv run python scripts/serve_docs.py --build-only --clean

# Deploy documentation to GitHub Pages
docs-deploy:
	uv run mkdocs gh-deploy --force

# Install documentation dependencies
docs-setup:
	uv add --dev mkdocs mkdocs-material

# Clean documentation build
docs-clean:
	rm -rf site/

# Test if documentation builds without errors
docs-test:
	uv run mkdocs build -s
```

## Common Documentation Tasks

### Adding a New Page

1. Create a markdown file in the appropriate directory
2. Add the file to `nav` section in `mkdocs.yml`
3. Follow the style guide for consistent formatting
4. Test locally with `make docs-serve`

### Adding Images

1. Place images in the `docs/assets/images/` directory
2. Reference in markdown with relative paths:
   ```markdown
   ![Alt text](../assets/images/example.png)
   ```

### Including Code Samples

Use fenced code blocks with appropriate language:

```markdown
```python
def example():
    """This is a docstring."""
    return True
```
```

## Troubleshooting

If you encounter issues with documentation:

1. Check terminal output for error messages
2. Ensure both `mkdocs.yml` and `mkdocs.yml.bak` exist
3. Verify URL behavior:
   - Local development should NOT have `/codegen-lab/` in URLs
   - GitHub Pages deployment SHOULD have `/codegen-lab/` in URLs
4. Use `make docs-clean-build` to rebuild from scratch
5. Check for missing files referenced in `mkdocs.yml` nav section

### Common Issues

1. **302 Redirects**:
   - This often happens if the URL configuration doesn't match the expected format
   - Check if the site is being served with or without the `/codegen-lab/` path

2. **Missing Pages in Navigation**:
   - Files exist in docs directory but aren't listed in the `nav` section
   - Add them to `mkdocs.yml` under the appropriate section

3. **File Conflicts**:
   - Having both `README.md` and `index.md` in the same directory
   - Rename or remove one of the conflicting files
