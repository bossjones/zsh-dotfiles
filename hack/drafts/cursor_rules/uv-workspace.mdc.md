---
description: UV Workspace Configuration
globs: pyproject.toml
alwaysApply: false
---
# UV Workspace Configuration

Rules for analyzing an existing repository and reconfiguring it to support workspaces using UV.

<rule>
name: uv_workspace_analysis
description: Analyzes existing repositories and provides guidance for converting to UV workspaces
filters:
  # Match pyproject.toml files
  - type: file_extension
    pattern: "\\.toml$"
  # Match files that look like Python project definitions
  - type: content
    pattern: "\\[project\\]"
  # Focus on repo structure analysis
  - type: event
    pattern: "file_analyze|file_create|file_update"

actions:
  - type: analyze_repo
    description: "Analyze repository structure for workspace conversion"

    # Identify potential workspace members
    conditions:
      - pattern: "^.*?pyproject\\.toml$"

    script: |
      // This is a placeholder for a more complex analysis
      // In a real implementation, this would scan the entire repo structure
      let foundProjects = [];
      let workspaceStructure = {
        root: null,
        members: [],
        structure: {}
      };

      // Check if this repo already has workspace configuration
      const hasWorkspace = content.includes("[tool.uv.workspace]");

      return {
        hasWorkspace,
        foundProjects,
        workspaceStructure
      };

  - type: suggest
    conditions:
      - pattern: "\\[project\\]"
        negated: false
      - pattern: "\\[tool\\.uv\\.workspace\\]"
        negated: true
    message: |
      # UV Workspace Configuration Recommendation

      This repository appears to contain Python projects but is not configured for UV workspaces.

      ## Benefits of UV Workspaces

      UV workspaces allow you to:
      - Organize large codebases by splitting them into multiple packages
      - Share a single lockfile for consistent dependencies
      - Manage interdependent Python packages in the same repository
      - Run commands on specific packages from any workspace directory

      ## Recommended Steps for Conversion

      1. **Identify your workspace root**:
         - Choose a main project as your workspace root
         - Add the `[tool.uv.workspace]` table to its `pyproject.toml`

      2. **Configure workspace members**:
         ```toml
         [tool.uv.workspace]
         members = ["packages/*"]  # Adjust pattern to match your structure
         exclude = []  # Optional: exclude certain directories
         ```

      3. **Set up dependencies between workspace members**:
         ```toml
         [project]
         dependencies = ["your-package-name"]

         [tool.uv.sources]
         your-package-name = { workspace = true }
         ```

      4. **Run UV commands**:
         - `uv lock` - Update the lockfile for the whole workspace
         - `uv sync` - Install dependencies for the workspace root
         - `uv run --package package-name command` - Run a command in a specific package

  - type: suggest
    conditions:
      - pattern: "\\[tool\\.uv\\.workspace\\]"
        negated: false
      - pattern: "\\[tool\\.uv\\.sources\\]"
        negated: true
    message: |
      # UV Workspace Inter-Dependency Configuration

      Your project is configured as a UV workspace but doesn't define workspace sources.

      ## Recommended Configuration

      To properly link dependencies between workspace members:

      ```toml
      [project]
      # Make sure dependencies list includes your workspace packages
      dependencies = ["your-workspace-package"]

      [tool.uv.sources]
      # Define workspace sources for each internal dependency
      your-workspace-package = { workspace = true }
      ```

      This ensures that dependencies between workspace members are editable and properly linked.

  - type: suggest
    conditions:
      - pattern: "\\[tool\\.uv\\.workspace\\]\\s*\\n\\s*members\\s*=\\s*\\["
        negated: false
    message: |
      # UV Workspace Structure Recommendation

      Your workspace configuration includes the members key. Consider organizing your repository with this recommended structure:

      ```
      your-project-root/
      ├── packages/
      │   ├── package1/
      │   │   ├── pyproject.toml
      │   │   └── src/
      │   │       └── package1/
      │   │           ├── __init__.py
      │   │           └── ...
      │   └── package2/
      │       ├── pyproject.toml
      │       └── src/
      │           └── package2/
      │               ├── __init__.py
      │               └── ...
      ├── pyproject.toml  # Workspace root
      ├── uv.lock
      └── src/
          └── your_project_root/
              └── ...
      ```

      This structure follows the best practices for UV workspaces with clear separation between packages.

examples:
  - input: |
      # Before: Single project structure
      pyproject.toml (with no workspace config)
      src/myproject/...

      # After: Workspace structure
      pyproject.toml (root with workspace config)
      packages/
        lib1/
          pyproject.toml
          src/lib1/...
        lib2/
          pyproject.toml
          src/lib2/...
      src/myproject/...
    output: "Repository correctly configured for UV workspaces"

  - input: |
      # pyproject.toml without workspace configuration
      [project]
      name = "myproject"
      version = "0.1.0"
      requires-python = ">=3.8"
      dependencies = ["packageA", "packageB"]

      # After: With workspace configuration
      [project]
      name = "myproject"
      version = "0.1.0"
      requires-python = ">=3.8"
      dependencies = ["packageA", "packageB"]

      [tool.uv.sources]
      packageA = { workspace = true }

      [tool.uv.workspace]
      members = ["packages/*"]
    output: "Added proper UV workspace configuration to pyproject.toml"

metadata:
  priority: high
  version: 1.0
  language: python
  scope: project-structure
</rule>

<rule>
name: uv_workspace_compliance
description: Ensures proper compliance with UV workspace requirements
filters:
  # Match pyproject.toml files
  - type: file_extension
    pattern: "\\.toml$"
  # Match files that are configured as UV workspaces
  - type: content
    pattern: "\\[tool\\.uv\\.workspace\\]"

actions:
  - type: check
    description: "Verify requires-python compatibility across workspace"
    conditions:
      - pattern: "\\[project\\]\\s*[\\s\\S]*?requires-python\\s*=\\s*\"([^\"]*)\"[\\s\\S]*?\\[tool\\.uv\\.workspace\\]"
    message: |
      Ensure all workspace members have compatible `requires-python` settings.

      UV workspaces enforce a single `requires-python` for the entire workspace,
      taking the intersection of all members' `requires-python` values.

      Current value: {{match.1}}

      This will be enforced across all workspace members.

  - type: check
    description: "Verify workspace members configuration"
    conditions:
      - pattern: "\\[tool\\.uv\\.workspace\\]\\s*[\\s\\S]*?members\\s*=\\s*\\[([^\\]]*)\\]"
        negated: false
    message: |
      Workspace members configuration found: {{match.1}}

      Ensure each directory matched by the patterns contains a valid `pyproject.toml` file.
      Every workspace member must be either an application or a library.

  - type: check
    description: "Verify workspace root configuration"
    conditions:
      - pattern: "\\[project\\]\\s*[\\s\\S]*?name\\s*=\\s*\"([^\"]*)\"[\\s\\S]*?\\[tool\\.uv\\.workspace\\]"
        negated: false
    message: |
      Workspace root identified as "{{match.1}}".

      By default, `uv run` and `uv sync` operate on the workspace root.

      To run commands in specific packages, use:
      ```
      uv run --package package-name command
      ```

examples:
  - input: |
      [project]
      name = "myproject"
      version = "0.1.0"
      requires-python = ">=3.9"

      [tool.uv.workspace]
      members = ["packages/*"]

      # Another package with incompatible Python version
      # packages/lib1/pyproject.toml:
      # [project]
      # requires-python = ">=3.10"
    output: "Warning: workspace members have incompatible requires-python values"

  - input: |
      [project]
      name = "myproject"
      version = "0.1.0"

      [tool.uv.workspace]
      members = ["packages/*"]

      # Missing pyproject.toml in packages/lib1
    output: "Error: workspace member packages/lib1 missing pyproject.toml"

metadata:
  priority: high
  version: 1.0
  language: python
  scope: project-configuration
</rule>

<rule>
name: uv_workspace_migration
description: Helps migrate existing repositories to UV workspaces
filters:
  # Match Python projects (any Python file)
  - type: file_extension
    pattern: "\\.py$"
  # Match potential package structure
  - type: path
    pattern: "src/.*/__init__\\.py"

actions:
  - type: analyze
    description: "Identify potential package structure for workspace conversion"
    conditions:
      - pattern: "src/([^/]+)/__init__\\.py"
    script: |
      // This would analyze package structure
      const packageName = match[1];
      return { packageName };

  - type: suggest
    message: |
      # UV Workspace Migration Plan

      Your repository structure appears to contain Python packages that could benefit from UV workspaces.

      ## Recommended Migration Steps

      1. **Create workspace root**:
         In the repository root `pyproject.toml`:
         ```toml
         [tool.uv.workspace]
         members = ["packages/*"]
         ```

      2. **Refactor directory structure**:
         ```
         # Before
         /repo
         ├── src/
         │   ├── package1/
         │   │   └── __init__.py
         │   └── package2/
         │       └── __init__.py
         └── pyproject.toml

         # After
         /repo
         ├── packages/
         │   ├── package1/
         │   │   ├── pyproject.toml
         │   │   └── src/
         │   │       └── package1/
         │   │           └── __init__.py
         │   └── package2/
         │       ├── pyproject.toml
         │       └── src/
         │           └── package2/
         │               └── __init__.py
         ├── src/  # For the root package (optional)
         └── pyproject.toml  # Workspace root
         ```

      3. **Configure each package**:
         Create a `pyproject.toml` for each package with appropriate metadata.

      4. **Set up dependencies**:
         Configure inter-package dependencies using workspace sources:
         ```toml
         [tool.uv.sources]
         package1 = { workspace = true }
         ```

      5. **Generate lockfile**:
         Run `uv lock` in the workspace root to create a single lockfile for the workspace.

examples:
  - input: |
      # Current structure:
      src/package1/__init__.py
      src/package2/__init__.py
      pyproject.toml (no workspace config)
    output: "Identified 2 potential workspace members: package1, package2"

metadata:
  priority: medium
  version: 1.0
  language: python
  scope: project-migration
</rule>

<rule>
name: uv_workspace_lockfile
description: Manages UV workspace lockfile
filters:
  # Match UV lockfiles
  - type: file_name
    pattern: "uv\\.lock"
  # Match pyproject.toml with workspace configuration
  - type: related_file
    pattern: "pyproject\\.toml"
    content_pattern: "\\[tool\\.uv\\.workspace\\]"

actions:
  - type: check
    description: "Verify lockfile consistency"
    message: |
      # UV Workspace Lockfile

      In UV workspaces, a single lockfile is shared across all workspace members.

      ## Best Practices

      1. **Always commit the lockfile**:
         The `uv.lock` file should be committed to version control.

      2. **Update with `uv lock`**:
         Run `uv lock` from the workspace root to update the lockfile for all workspace members.

      3. **Apply changes with `uv sync`**:
         After updating the lockfile, run `uv sync` to install dependencies.

      4. **Troubleshooting**:
         If you encounter lockfile conflicts, try:
         - Removing the lockfile and regenerating with `uv lock`
         - Checking for incompatible dependency specifications across workspace members
         - Ensuring all workspace members have compatible `requires-python` values

  - type: suggest
    message: |
      Consider adding these commands to your project's documentation or README:

      ```
      # Update lockfile for the entire workspace
      uv lock

      # Install dependencies for the workspace root
      uv sync

      # Install dependencies for a specific package
      uv sync --package package-name

      # Run a command in a specific package
      uv run --package package-name command
      ```

      These commands will help developers work effectively with your UV workspace.

examples:
  - input: |
      # UV lockfile present but not committed
      .gitignore: uv.lock
    output: "Warning: UV lockfile should be committed to version control"

metadata:
  priority: medium
  version: 1.0
  language: python
  scope: dependency-management
</rule>
