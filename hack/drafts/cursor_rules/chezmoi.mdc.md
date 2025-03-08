---
description: Best practices and reference for working with Chezmoi dotfile manager
globs: *.go, *.toml, *.tmpl
alwaysApply: false
---
# Chezmoi Dotfile Manager

Guidelines for working with the Chezmoi dotfile management tool and its codebase.


<rule>
name: chezmoi_dotfile_manager
description: Guidelines for working with Chezmoi dotfile management tool
filters:
  # Match Go files
  - type: file_extension
    pattern: "\\.go$"
  # Match template files
  - type: file_extension
    pattern: "\\.tmpl$"
  # Match TOML configuration files
  - type: file_extension
    pattern: "\\.toml$"
  # Match chezmoi-related content
  - type: content
    pattern: "(?i)(chezmoi|dotfiles|source state|target state)"

actions:
  - type: suggest
    message: |
      # Chezmoi Dotfile Manager

      Chezmoi is a powerful dotfile management tool written in Go that helps users manage their configuration files across multiple machines securely.

      ## Core Concepts

      1. **Source State**: The desired state of your dotfiles, stored in `~/.local/share/chezmoi` by default.
      2. **Destination Directory**: The directory that chezmoi manages, usually your home directory (`~`).
      3. **Target State**: The computed desired state for the destination directory, based on the source state, configuration, and templates.
      4. **Config File**: Contains machine-specific data, stored in `~/.config/chezmoi/chezmoi.toml` by default.

      ## Repository Structure

      ```
      .
      ├── assets/                  # Assets for documentation, scripts, and templates
      │   ├── chezmoi.io/          # Documentation website content
      │   ├── cosign/              # Signing keys
      │   ├── docker/              # Docker configurations
      │   ├── scripts/             # Installation and utility scripts
      │   ├── templates/           # Templates for various files
      │   └── vagrant/             # Vagrant configurations for testing
      ├── completions/             # Shell completion scripts
      ├── internal/                # Internal commands and utilities
      ├── pkg/                     # Core packages
      │   ├── archivetest/         # Archive testing utilities
      │   ├── chezmoi/             # Core chezmoi functionality
      │   ├── chezmoibubbles/      # Terminal UI components
      │   ├── chezmoilog/          # Logging utilities
      │   ├── chezmoitest/         # Testing utilities
      │   ├── cmd/                 # Command implementations
      │   ├── git/                 # Git integration
      │   └── shell/               # Shell integration
      ├── main.go                  # Application entry point
      └── main_test.go             # Main package tests
      ```

      ## Key Features

      ### 1. Template System

      Chezmoi uses Go's `text/template` to handle machine-specific differences in configuration files:

      ```go
      // Example template
      {{- if eq .chezmoi.os "darwin" -}}
      # macOS-specific configuration
      {{- else if eq .chezmoi.os "linux" -}}
      # Linux-specific configuration
      {{- end -}}
      ```

      ### 2. Secret Management

      Chezmoi integrates with various password managers and secret storage solutions:

      ```go
      // Example of retrieving a secret
      {{ (bitwarden "item" "example.com").password }}
      {{ (onepassword "item" "example.com").password }}
      {{ (pass "example.com") }}
      ```

      ### 3. File Operations

      Chezmoi supports various file operations through special prefixes:

      - `dot_` - Files that should be prefixed with a dot in the destination
      - `executable_` - Files that should be executable
      - `private_` - Files that should be private (0600 permissions)
      - `readonly_` - Files that should be read-only
      - `symlink_` - Symbolic links
      - `encrypted_` - Encrypted files
      - `exact_` - Exact directories (no partial updates)
      - `empty_` - Empty files
      - `modify_` - Scripts that modify existing files
      - `remove_` - Files to be removed
      - `run_` - Scripts to be run
      - `once_` - Scripts to be run only once
      - `onchange_` - Scripts to be run when their content changes

      ### 4. Command Structure

      Chezmoi uses the Cobra library for command-line interface, with commands organized in the `pkg/cmd` package:

      ```go
      // Example command structure
      cmd := &cobra.Command{
          Use:     "add [path...]",
          Short:   "Add an existing file, directory, or symlink to the source state",
          Long:    mustLongHelp("add"),
          Example: example("add"),
          RunE:    config.runAddCmd,
      }
      ```

      ## Best Practices

      ### Working with Templates

      1. Use conditional logic based on hostname, operating system, or other variables:
         ```go
         {{- if eq .chezmoi.hostname "work-laptop" -}}
         # Work-specific configuration
         {{- else -}}
         # Personal configuration
         {{- end -}}
         ```

      2. Use template functions for dynamic content:
         ```go
         {{- $files := list "file1" "file2" "file3" -}}
         {{- range $files -}}
         {{ . }}
         {{- end -}}
         ```

      3. Include external files:
         ```go
         {{ include "path/to/file" }}
         ```

      ### Managing Secrets

      1. Use integrated password managers:
         ```go
         {{ (keepassxc "example.com").password }}
         ```

      2. Use age encryption for sensitive files:
         ```bash
         chezmoi add --encrypt ~/.ssh/id_rsa
         ```

      ### Version Control

      1. Initialize from a remote repository:
         ```bash
         chezmoi init https://github.com/username/dotfiles.git
         ```

      2. Commit and push changes:
         ```bash
         chezmoi git add .
         chezmoi git commit -m "Update dotfiles"
         chezmoi git push
         ```

examples:
  - input: |
      # Adding a new dotfile to chezmoi
      I want to add my .bashrc file to chezmoi
    output: |
      To add your .bashrc file to chezmoi, use the `add` command:

      ```bash
      chezmoi add ~/.bashrc
      ```

      This will copy the file to your source directory (typically `~/.local/share/chezmoi`) with the appropriate prefix (`dot_bashrc`).

      If you want to edit it immediately after adding:

      ```bash
      chezmoi add --template ~/.bashrc
      chezmoi edit ~/.bashrc
      ```

      The `--template` flag will convert the file to a template, allowing you to use template directives for machine-specific configurations.

  - input: |
      # Creating a template with OS-specific configuration
      I need different configurations for Linux and macOS
    output: |
      You can use Go's template system to create OS-specific configurations:

      ```bash
      chezmoi edit ~/.bashrc
      ```

      Then add conditional logic based on the operating system:

      ```bash
      # Common configuration

      {{- if eq .chezmoi.os "darwin" }}
      # macOS specific configuration
      export PATH="/usr/local/bin:$PATH"
      alias ls="ls -G"
      {{- else if eq .chezmoi.os "linux" }}
      # Linux specific configuration
      export PATH="/usr/bin:$PATH"
      alias ls="ls --color=auto"
      {{- end }}

      # More common configuration
      ```

      This template will generate different content based on whether you're on macOS or Linux when you run `chezmoi apply`.

  - input: |
      # Managing secrets with chezmoi
      How do I store my API keys securely?
    output: |
      Chezmoi offers several ways to manage secrets:

      1. Using a password manager (recommended):

      ```bash
      # Store your API key in your password manager first, then:
      chezmoi edit ~/.config/service/config.yaml
      ```

      In the file, use template directives to retrieve the secret:

      ```yaml
      api_key: {{ (bitwarden "item" "My API Key").notes }}
      # Or with 1Password:
      api_key: {{ (onepassword "item" "My API Key").password }}
      ```

      2. Using age encryption:

      ```bash
      # First, set up age encryption:
      chezmoi init --apply
      chezmoi age setup

      # Then add your file with encryption:
      chezmoi add --encrypt ~/.config/service/config.yaml
      ```

      This will encrypt the file in your source state, and decrypt it when applying.

metadata:
  priority: high
  version: 1.0
  tags:
    - dotfiles
    - configuration-management
    - go
    - templates
    - secrets
</rule>
