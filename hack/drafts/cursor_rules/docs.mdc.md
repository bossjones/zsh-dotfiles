---
description: Documentation Standards for Chezmoi Dotfiles
globs: *.md, *.tmpl, .chezmoi*
alwaysApply: false
---
# Chezmoi Dotfiles Documentation Standards

Guidelines for creating and maintaining documentation for the zsh-dotfiles repository managed with chezmoi.

<rule>
name: chezmoi_documentation_standards
description: Standards for documenting chezmoi-managed dotfiles
filters:
  # Match documentation files
  - type: file_extension
    pattern: "\\.md$"
  # Match chezmoi template files
  - type: file_path
    pattern: "\\.chezmoi.*"
  - type: file_extension
    pattern: "\\.tmpl$"

actions:
  - type: suggest
    message: |
      # Dotfiles Documentation Best Practices

      This project uses chezmoi to manage dotfiles with templating. Follow these guidelines for documentation:

      ## Content Guidelines

      1. **Structure**:
         - Use consistent heading levels (# for title, ## for sections, etc.)
         - Keep paragraphs concise and focused
         - Use tables to compare original templates and rendered files

      2. **Formatting**:
         - Use **bold** for emphasis and UI elements
         - Use *italics* for introducing new terms
         - Use `code blocks` for commands, code snippets, or file paths

      3. **Code Samples**:
         - Use fenced code blocks with language specification
         ```bash
         # Example chezmoi command
         chezmoi apply
         ```

      4. **Template Transformation Tables**:
         - Document template transformations using tables
         - Include the original template and the rendered result
         - Explain the variables and logic used in the transformation

         Example:

         | Original Template | Rendered Result | Description |
         |-------------------|-----------------|-------------|
         | `{{ if eq .chezmoi.os "darwin" }}alias ls="ls -G"{{ else }}alias ls="ls --color=auto"{{ end }}` | `alias ls="ls -G"` (on macOS) or `alias ls="ls --color=auto"` (on Linux) | Sets the appropriate color flag for the ls command based on the operating system |

      5. **Variable Documentation**:
         - Document all chezmoi variables used in templates
         - Explain their purpose and possible values
         - Group related variables together

      ## Chezmoi Workflow Documentation

      1. **Installation**:
         ```bash
         # Install chezmoi and dotfiles
         sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply bossjones
         ```

      2. **Updating**:
         ```bash
         # Update dotfiles
         chezmoi update
         ```

      3. **Important Notes**:
         - Document any system-specific configurations
         - Explain how to customize dotfiles for different environments
         - Provide troubleshooting guidance for common issues

examples:
  - input: |
      # Bad: No explanation of template transformation
      ```
      {{ if eq .chezmoi.os "darwin" }}
      export PATH="/opt/homebrew/bin:$PATH"
      {{ else }}
      export PATH="/usr/local/bin:$PATH"
      {{ end }}
      ```

      # Good: Clear explanation with table
      | Original Template | Rendered Result | Description |
      |-------------------|-----------------|-------------|
      | `{{ if eq .chezmoi.os "darwin" }}export PATH="/opt/homebrew/bin:$PATH"{{ else }}export PATH="/usr/local/bin:$PATH"{{ end }}` | `export PATH="/opt/homebrew/bin:$PATH"` (on macOS) or `export PATH="/usr/local/bin:$PATH"` (on Linux) | Sets the appropriate Homebrew path based on the operating system |
    output: "Properly documented template transformation with table"

  - input: |
      # Bad: Missing variable documentation
      The template uses `.chezmoi.os` to determine the configuration.

      # Good: Complete variable documentation
      | Variable | Description | Example Values |
      |----------|-------------|----------------|
      | `.chezmoi.os` | Operating system name | "darwin", "linux", "windows" |
      | `.chezmoi.arch` | CPU architecture | "amd64", "arm64" |
      | `.chezmoi.hostname` | Host name | "macbook-pro", "work-desktop" |
    output: "Comprehensive variable documentation with examples"

metadata:
  priority: high
  version: 1.0
  tags:
    - documentation
    - chezmoi
    - dotfiles
    - zsh
</rule>

## Chezmoi Template System

Chezmoi uses Go's text/template system to transform template files into actual configuration files. This allows for dynamic configuration based on the system environment.

### Template Syntax

```
{{ if condition }}
  # content for when condition is true
{{ else }}
  # content for when condition is false
{{ end }}
```

### Common Variables

| Variable | Description |
|----------|-------------|
| `.chezmoi.os` | Operating system (e.g., "darwin", "linux", "windows") |
| `.chezmoi.arch` | Architecture (e.g., "amd64", "arm64") |
| `.chezmoi.hostname` | Host name |
| `.chezmoi.username` | User name |
| `.chezmoi.homeDir` | Home directory |
| `.chezmoi.sourceDir` | Source directory |

### Template Functions

Chezmoi provides several built-in functions for use in templates:

| Function | Description | Example |
|----------|-------------|---------|
| `eq` | Equal comparison | `{{ if eq .chezmoi.os "darwin" }}...{{ end }}` |
| `ne` | Not equal comparison | `{{ if ne .chezmoi.os "windows" }}...{{ end }}` |
| `lookPath` | Check if a command exists | `{{ if lookPath "brew" }}...{{ end }}` |
| `joinPath` | Join path components | `{{ joinPath .chezmoi.homeDir ".config" }}` |
| `include` | Include the contents of another file | `{{ include "path/to/file" }}` |

## Documentation Examples

### Example 1: Shell Configuration

| Original Template (.zshrc.tmpl) | Rendered Result (.zshrc) | Description |
|----------------------------------|--------------------------|-------------|
| `{{ if eq .chezmoi.os "darwin" }}source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh{{ else }}source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh{{ end }}` | `source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh` (on macOS) | Loads zsh-autosuggestions from the appropriate location based on OS |

### Example 2: Git Configuration

| Original Template (.gitconfig.tmpl) | Rendered Result (.gitconfig) | Description |
|-------------------------------------|------------------------------|-------------|
| `name = {{ .name }}`<br>`email = {{ .email }}` | `name = John Doe`<br>`email = john@example.com` | Sets Git user name and email based on chezmoi data values |

### Example 3: Conditional Configuration

| Original Template (.tmux.conf.tmpl) | Rendered Result (.tmux.conf) | Description |
|-------------------------------------|------------------------------|-------------|
| `set -g default-terminal "screen-256color"`<br>`{{ if eq .chezmoi.os "darwin" }}set -g default-command "reattach-to-user-namespace -l $SHELL"{{ end }}` | `set -g default-terminal "screen-256color"`<br>`set -g default-command "reattach-to-user-namespace -l $SHELL"` (on macOS only) | Adds macOS-specific tmux configuration |

## Creating Documentation for New Templates

When adding a new template file to the repository, follow these steps to document it:

1. Create a markdown file in the `docs/` directory with the same name as the template
2. Include a description of the file's purpose
3. Document all variables used in the template
4. Create a table showing the original template and possible rendered results
5. Explain any conditional logic or complex transformations
6. Include examples of how to customize the template

## Troubleshooting

If you encounter issues with template rendering:

1. Use `chezmoi execute-template` to test template rendering:
   ```bash
   chezmoi execute-template < ~/.local/share/chezmoi/dot_zshrc.tmpl
   ```

2. Check the values of variables:
   ```bash
   chezmoi data
   ```

3. Verify template syntax:
   ```bash
   chezmoi doctor
   ```
