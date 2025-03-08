---
description: Best practices and reference for working with Chezmoi dotfile manager
globs: "home/*.tmpl, home/dot_*, home/executable_dot_*, home/private_dot_*, home/private_dot_bin/executable_*, home/private_dot_config/**/*.tmpl, home/dot_sheldon/*.tmpl, home/shell/**/*.zsh, .chezmoiroot, .chezmoiversion, .chezmoiignore, .chezmoiexternal.toml, .chezmoi.toml.tmpl, .chezmoi.yaml.tmpl"
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

      ## Core Configuration Files

      ### .chezmoiroot

      The `.chezmoiroot` file defines the root directory of your source state. This is particularly useful when:

      1. **Organizing Multiple Configurations**: Manage different sets of dotfiles in subdirectories
      2. **Supporting Different Environments**: Separate configurations for different types of machines
      3. **Modular Organization**: Break up your dotfiles into logical groups

      Example `.chezmoiroot` usage:

      ```
      .
      ├── .chezmoiroot        # Points to "home" directory
      ├── home/               # Main dotfiles directory
      │   ├── dot_config/     # .config files
      │   └── dot_zshrc      # .zshrc file
      ├── work/              # Work-specific configurations
      │   └── dot_gitconfig  # Work .gitconfig
      └── server/            # Server configurations
          └── dot_ssh/       # SSH configuration
      ```

      ```bash
      # .chezmoiroot content
      home
      ```

      This configuration tells chezmoi to use the `home` directory as the root for source state, allowing you to maintain separate configurations in parallel directories.

      ### .chezmoiversion

      The `.chezmoiversion` file specifies the minimum version of chezmoi required for your dotfiles. This ensures compatibility and prevents issues with older versions.

      Example `.chezmoiversion`:

      ```
      2.40.0
      ```

      Key features:
      1. **Version Enforcement**: Prevents running with incompatible chezmoi versions
      2. **Feature Compatibility**: Ensures required features are available
      3. **Smooth Updates**: Helps manage transitions to newer versions

      When chezmoi encounters a `.chezmoiversion` file:
      - Checks if the current version meets the requirement
      - Provides clear error messages if version is too old
      - Suggests updating chezmoi if needed

      ### .chezmoiignore

      The `.chezmoiignore` file specifies which files and directories should be ignored by chezmoi. It uses the same syntax as `.gitignore`.

      Example `.chezmoiignore`:

      ```gitignore
      # Ignore specific files
      README.md
      LICENSE

      # Ignore temporary files
      *.swp
      *~
      .DS_Store

      # Ignore directories
      .git/
      node_modules/
      tmp/

      # Ignore by pattern
      **/*.log
      **/.terraform/*

      # OS-specific ignores
      {{- if ne .chezmoi.os "darwin" }}
      # Ignore macOS-specific files on non-macOS systems
      Library/
      .Trash/
      {{- end }}

      # Machine-specific ignores
      {{- if ne .chezmoi.hostname "work-laptop" }}
      # Ignore work-specific configs on other machines
      .work-config/
      {{- end }}
      ```

      Key features:
      1. **Pattern Matching**: Supports glob patterns and directory-specific ignores
      2. **Template Support**: Can use chezmoi template syntax for conditional ignores
      3. **Nested Ignores**: Supports `.chezmoiignore` files in subdirectories
      4. **Comments**: Supports comments for better documentation

      Best practices:
      1. **Start Simple**: Begin with common ignore patterns
      2. **Use Comments**: Document why certain files are ignored
      3. **Group Related Patterns**: Organize patterns by category
      4. **Consider Templates**: Use templates for OS/machine-specific ignores
      5. **Review Regularly**: Update ignore patterns as your dotfiles evolve

      ## Repository Structure

      ```
      .
      ├── home/                    # Source state directory
      │   ├── dot_config/          # Configuration files (.config)
      │   ├── dot_local/           # Local files (.local)
      │   ├── private_dot_ssh/     # SSH configuration (private)
      │   ├── executable_scripts/  # Executable scripts
      │   └── run_once_setup.sh    # One-time setup script
      ├── .chezmoi.toml.tmpl      # Template for chezmoi configuration
      └── .chezmoiexternal.toml   # External file definitions
      ```

      ## Template Patterns and Best Practices

      ### 1. OS-Specific Configuration

      Use `.chezmoi.os` for OS-specific configurations:

      ```go
      {{- if eq .chezmoi.os "darwin" }}
      # macOS Configuration
      export HOMEBREW_PREFIX="/opt/homebrew"
      export PATH="$HOMEBREW_PREFIX/bin:$PATH"
      {{- else if eq .chezmoi.os "linux" }}
      # Linux Configuration
      export PATH="/usr/local/bin:$PATH"
      {{- end }}
      ```

      ### 2. Shell-Specific Templates

      Detect and configure based on shell type:

      ```go
      {{- if eq .chezmoi.shell "zsh" }}
      # ZSH specific settings
      source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
      {{- else if eq .chezmoi.shell "bash" }}
      # Bash specific settings
      source ~/.bashrc.d/aliases.bash
      {{- end }}
      ```

      ### 3. Machine-Specific Configuration

      Use hostname or custom variables for machine-specific settings:

      ```go
      {{- if eq .chezmoi.hostname "work-laptop" }}
      # Work environment settings
      export http_proxy="http://proxy.company.com:8080"
      {{- else }}
      # Personal environment settings
      unset http_proxy
      {{- end }}
      ```

      ### 4. External Dependencies

      Define external dependencies in `.chezmoiexternal.toml`:

      ```toml
      [".oh-my-zsh"]
        type = "archive"
        url = "https://github.com/ohmyzsh/ohmyzsh/archive/master.tar.gz"
        exact = true
        stripComponents = 1
        refreshPeriod = "168h"

      [".vim/pack/plugins/start/vim-go"]
        type = "git-repo"
        url = "https://github.com/fatih/vim-go.git"
        refreshPeriod = "168h"
      ```

      ### 5. Environment Variables and Secrets

      Handle sensitive data using environment variables or password managers:

      ```go
      {{- if env "WORK_MACHINE" }}
      # Work-specific configuration with secrets
      export API_KEY="{{ (onepassword "Work API Key").password }}"
      {{- else }}
      # Personal configuration
      export API_KEY="{{ (pass "personal/api-key") }}"
      {{- end }}
      ```

      ### 6. Directory Structure Templates

      Create consistent directory structures:

      ```go
      {{- $config := .chezmoi.homeDir }}/.config
      {{- $data := .chezmoi.homeDir }}/.local/share

      {{- $dirs := list
        (joinPath $config "nvim")
        (joinPath $config "tmux")
        (joinPath $data "zsh")
      -}}

      {{- range $dirs }}
      {{ . }} = "directory"
      {{- end }}
      ```

      ### 7. Conditional File Management

      Handle files based on conditions:

      ```go
      {{- if stat (joinPath .chezmoi.homeDir ".ssh/id_rsa") }}
      # SSH key exists, configure SSH agent
      eval "$(ssh-agent -s)"
      ssh-add ~/.ssh/id_rsa
      {{- end }}
      ```

      ### 8. Script Templates

      Create dynamic script templates:

      ```bash
      #!/bin/bash

      # Generated by chezmoi - DO NOT EDIT DIRECTLY

      {{- if eq .chezmoi.os "darwin" }}
      # Install macOS packages
      brew bundle --file=~/.Brewfile
      {{- else if eq .chezmoi.os "linux" }}
      # Install Linux packages
      {{- if lookPath "apt-get" }}
      sudo apt-get update && sudo apt-get install -y $(cat ~/.packages)
      {{- else if lookPath "yum" }}
      sudo yum install -y $(cat ~/.packages)
      {{- end }}
      {{- end }}
      ```

      ## Shell Organization and Structure

      Chezmoi excels at managing complex shell configurations with a modular approach. This section covers best practices for organizing shell configurations.

      ### 1. Modular Shell Configuration

      Organize shell configurations into a structured directory hierarchy for better maintainability:

      ```
      shell/
      ├── asdf/                # Tool-specific configuration
      │   ├── env.zsh          # Environment variables
      │   └── path.zsh         # Path configuration
      ├── brew/                # Homebrew configuration
      │   └── completion.zsh   # Completions
      ├── customs/             # Custom configurations
      │   └── aliases.zsh      # Custom aliases
      ├── env.zsh              # Global environment variables
      ├── init.zsh             # Main initialization script
      ├── path.zsh             # Global path configuration
      └── zsh_dot_d/           # ZSH-specific configurations
          ├── after/           # Loaded after core initialization
          │   ├── git_cu.zsh   # Git customizations
          │   └── tmux.zsh     # Tmux integration
          └── before/          # Loaded before core initialization
              ├── go.zsh       # Go configuration
              └── rust.zsh     # Rust configuration
      ```

      Key benefits:
      1. **Separation of Concerns**: Each file has a specific purpose
      2. **Easier Maintenance**: Modify specific components without affecting others
      3. **Better Organization**: Logical grouping of related configurations
      4. **Selective Loading**: Load only what's needed for specific environments

      ### 2. Before/After Loading Pattern

      Implement a sophisticated loading mechanism to control initialization order:

      ```bash
      # In your main .zshrc.tmpl

      # Load core environment
      source "${HOME}/shell/env.zsh"

      # Load "before" scripts
      for file in ${HOME}/shell/zsh_dot_d/before/*.zsh; do
        source "$file"
      done

      # Load main configuration
      source "${HOME}/shell/init.zsh"

      # Load "after" scripts
      for file in ${HOME}/shell/zsh_dot_d/after/*.zsh; do
        source "$file"
      done
      ```

      This pattern allows:
      1. **Dependency Management**: Ensure prerequisites are loaded first
      2. **Override Capability**: Override default settings with custom configurations
      3. **Plugin Integration**: Properly initialize plugins in the correct order
      4. **Conflict Resolution**: Resolve conflicts between different components

      ### 3. Tool-specific Configuration

      Organize tool-specific configurations in dedicated directories:

      ```
      shell/
      ├── asdf/                # ASDF version manager
      ├── brew/                # Homebrew package manager
      ├── direnv/              # Directory-specific environments
      ├── fzf/                 # Fuzzy finder
      ├── pyenv/               # Python version manager
      └── rust/                # Rust programming language
      ```

      Each tool directory typically contains:
      - `env.zsh`: Environment variables
      - `path.zsh`: Path configurations
      - `completion.zsh`: Shell completions
      - `aliases.zsh`: Tool-specific aliases
      - `custom.zsh`: Custom configurations

      Example tool configuration:

      ```bash
      # shell/fzf/env.zsh
      export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
      export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"

      # shell/fzf/completion.zsh
      if [[ -f "${HOME}/.fzf.zsh" ]]; then
        source "${HOME}/.fzf.zsh"
      fi

      # shell/fzf/keybinding.zsh
      bindkey '^T' fzf-file-widget
      bindkey '^R' fzf-history-widget
      ```

      ### 4. Environment-specific Configuration

      Handle different environments with dedicated configuration directories:

      ```
      shell/
      ├── centos/              # CentOS-specific settings
      │   ├── env.zsh
      │   └── path.zsh
      ├── darwin/              # macOS-specific settings
      │   ├── env.zsh
      │   └── path.zsh
      └── ubuntu/              # Ubuntu-specific settings
          ├── env.zsh
          └── path.zsh
      ```

      Load these configurations conditionally:

      ```bash
      # In your main .zshrc.tmpl

      {{- if eq .chezmoi.os "darwin" }}
      # Load macOS specific configuration
      source "${HOME}/shell/darwin/env.zsh"
      source "${HOME}/shell/darwin/path.zsh"
      {{- else if eq .chezmoi.os "linux" }}
      # Determine Linux distribution
      {{- if lookPath "apt-get" }}
      # Load Ubuntu specific configuration
      source "${HOME}/shell/ubuntu/env.zsh"
      source "${HOME}/shell/ubuntu/path.zsh"
      {{- else if lookPath "yum" }}
      # Load CentOS specific configuration
      source "${HOME}/shell/centos/env.zsh"
      source "${HOME}/shell/centos/path.zsh"
      {{- end }}
      {{- end }}
      ```

      ### 5. Shell Initialization Flow

      Implement a consistent initialization flow across different shell components:

      1. **Environment Variables** (`env.zsh`): Set up environment variables first
      2. **Path Configuration** (`path.zsh`): Configure PATH and related variables
      3. **Completions** (`completion.zsh`): Set up command completions
      4. **Key Bindings** (`keybinding.zsh`): Configure keyboard shortcuts
      5. **Aliases** (`aliases.zsh`): Define command aliases
      6. **Custom Functions** (`functions.zsh`): Define custom functions
      7. **Tool-specific Configurations**: Load tool-specific settings

      Example initialization script:

      ```bash
      # shell/init.zsh

      # Load global configurations
      source "${HOME}/shell/env.zsh"
      source "${HOME}/shell/path.zsh"
      source "${HOME}/shell/keybinding.zsh"

      # Load tool-specific configurations
      for tool in asdf brew fzf git pyenv; do
        if [[ -d "${HOME}/shell/${tool}" ]]; then
          [[ -f "${HOME}/shell/${tool}/env.zsh" ]] && source "${HOME}/shell/${tool}/env.zsh"
          [[ -f "${HOME}/shell/${tool}/path.zsh" ]] && source "${HOME}/shell/${tool}/path.zsh"
          [[ -f "${HOME}/shell/${tool}/completion.zsh" ]] && source "${HOME}/shell/${tool}/completion.zsh"
          [[ -f "${HOME}/shell/${tool}/aliases.zsh" ]] && source "${HOME}/shell/${tool}/aliases.zsh"
        fi
      done

      # Load custom configurations last
      source "${HOME}/shell/customs/aliases.zsh"
      ```

      This structured approach ensures:
      1. **Predictable Behavior**: Consistent initialization across environments
      2. **Modularity**: Easy to add or remove components
      3. **Maintainability**: Clear organization makes maintenance easier
      4. **Debugging**: Easier to identify and fix issues

      ## Plugin Management

      Managing shell plugins effectively is crucial for a well-organized dotfiles repository. This section covers integration with the Sheldon plugin manager and best practices for plugin configuration.

      ### 1. Sheldon Integration

      [Sheldon](https://github.com/rossmacarthur/sheldon) is a fast, configurable plugin manager for shells. It allows you to manage your shell plugins, themes, and scripts in a declarative way.

      #### Basic Setup

      Configure Sheldon with chezmoi using a template:

      ```toml
      # dot_sheldon/plugins.toml.tmpl
      shell = "zsh"

      [templates]
      PATH = 'export PATH="{{ dir }}/bin:$PATH"'
      SOURCE = 'source "{{ dir }}/{{ name }}.plugin.zsh"'
      DEFER = '{{ hooks?.pre | nl }}{% for file in files %}source "{{ file }}"{% if not loop.last %} # {{ loop.index }}{% endif %}{{ "\n" }}{% endfor %}{{ hooks?.post | nl }}'

      [plugins]

      [plugins.zsh-defer]
      github = "romkatv/zsh-defer"

      [plugins.zsh-autosuggestions]
      github = "zsh-users/zsh-autosuggestions"
      use = ["{{ name }}.zsh"]
      apply = ["source"]

      [plugins.zsh-completions]
      github = "zsh-users/zsh-completions"
      apply = ["fpath"]

      {{- if eq .chezmoi.os "darwin" }}
      # macOS-specific plugins
      [plugins.macos]
      local = "~/.sheldon/plugins/macos"
      apply = ["source"]
      {{- end }}
      ```

      #### Loading Sheldon in Your Shell

      Add this to your `.zshrc.tmpl`:

      ```bash
      # Initialize Sheldon plugin manager
      if command -v sheldon &> /dev/null; then
        eval "$(sheldon source)"
      fi
      ```

      ### 2. Plugin Configuration

      Structure your `plugins.toml.tmpl` file for maximum flexibility and organization:

      #### Template Section

      Define reusable templates for plugin loading:

      ```toml
      [templates]
      # Source a plugin
      SOURCE = 'source "{{ dir }}/{{ name }}.plugin.zsh"'

      # Add to fpath for completions
      FPATH = 'fpath=("{{ dir }}" $fpath)'

      # Deferred loading for performance
      DEFER = 'zsh-defer source "{{ dir }}/{{ name }}.plugin.zsh"'
      ```

      #### Plugin Sections

      Organize plugins by category:

      ```toml
      # Core plugins (always loaded)
      [plugins.zsh-defer]
      github = "romkatv/zsh-defer"

      # Completion plugins
      [plugins.zsh-completions]
      github = "zsh-users/zsh-completions"
      apply = ["fpath"]

      # Syntax highlighting
      [plugins.zsh-syntax-highlighting]
      github = "zsh-users/zsh-syntax-highlighting"
      apply = ["defer"]

      # Theme plugins
      [plugins.powerlevel10k]
      github = "romkatv/powerlevel10k"
      apply = ["source"]
      ```

      #### Conditional Plugins

      Use chezmoi templating to conditionally load plugins:

      ```toml
      {{- if eq .chezmoi.os "darwin" }}
      # macOS-specific plugins
      [plugins.macos]
      local = "~/.sheldon/plugins/macos"
      apply = ["source"]
      {{- end }}

      {{- if eq .chezmoi.hostname "work-laptop" }}
      # Work-specific plugins
      [plugins.work-tools]
      local = "~/.sheldon/plugins/work"
      apply = ["source"]
      {{- end }}
      ```

      ### 3. Plugin Loading Order

      Control the order in which plugins are loaded to avoid conflicts and ensure dependencies are satisfied:

      #### Using Dependencies

      ```toml
      [plugins.plugin-b]
      github = "user/plugin-b"
      apply = ["source"]
      dependencies = ["plugin-a"]  # Load plugin-a before plugin-b
      ```

      #### Using Hooks

      ```toml
      [plugins.complex-plugin]
      github = "user/complex-plugin"
      apply = ["source"]
      hooks.pre = 'export PLUGIN_CONFIG="custom-value"'
      hooks.post = 'setup_plugin_function'
      ```

      #### Deferred Loading

      Improve shell startup time by deferring non-critical plugins:

      ```toml
      [plugins.zsh-defer]
      github = "romkatv/zsh-defer"
      apply = ["source"]

      [plugins.slow-plugin]
      github = "user/slow-plugin"
      apply = ["defer"]  # Will be loaded after shell is interactive
      ```

      ### 4. Plugin Dependencies

      Manage dependencies between plugins effectively:

      #### Explicit Dependencies

      ```toml
      [plugins.theme-plugin]
      github = "user/theme-plugin"
      apply = ["source"]
      dependencies = ["color-plugin", "font-plugin"]
      ```

      #### Shared Configuration

      Create shared configuration for related plugins:

      ```toml
      [plugins.config-loader]
      local = "~/.sheldon/configs"
      apply = ["source"]

      [plugins.plugin-a]
      github = "user/plugin-a"
      apply = ["source"]
      dependencies = ["config-loader"]

      [plugins.plugin-b]
      github = "user/plugin-b"
      apply = ["source"]
      dependencies = ["config-loader"]
      ```

      #### Conflict Resolution

      Handle plugin conflicts with careful ordering and configuration:

      ```toml
      [plugins.plugin-a]
      github = "user/plugin-a"
      apply = ["source"]

      [plugins.plugin-b]
      github = "user/plugin-b"
      apply = ["source"]
      hooks.pre = 'OVERRIDE_CONFLICTING_FUNCTION=1'  # Set flag to avoid conflict
      dependencies = ["plugin-a"]  # Ensure plugin-a loads first
      ```

      ## Script Management

      Managing executable scripts effectively is essential for a well-organized dotfiles repository. This section covers best practices for organizing and maintaining scripts with chezmoi.

      ### 1. Executable Scripts Organization

      Organize executable scripts in a structured way to make them easy to find, use, and maintain:

      #### Directory Structure

      ```
      private_dot_bin/
      ├── executable_git-pull-recursive     # Git utilities
      ├── executable_git-status-recursive
      ├── executable_multi-git-status
      ├── executable_ffmpeg-all-batch       # FFmpeg utilities
      ├── executable_ffmpeg-batch-process
      ├── executable_ffmpeg-duration
      ├── executable_ffmpeg-fill-blur
      ├── executable_imagemagick-grid       # ImageMagick utilities
      ├── executable_imagemagick-ig-resize
      ├── executable_imagemagick-square
      ├── executable_fzf-drafts             # FZF utilities
      ├── executable_fzf-panes.tmux
      ├── executable_fzfp
      └── executable_post-install-chezmoi   # System utilities
      ```

      #### Organization Strategies

      1. **Functional Grouping**: Group scripts by their function or the tools they work with
      2. **Naming Conventions**: Use consistent prefixes to identify related scripts
      3. **Documentation**: Include comments at the top of each script explaining its purpose
      4. **Version Control**: Track all scripts in your chezmoi repository

      Example implementation:

      ```bash
      # In your .zshrc.tmpl or .bashrc.tmpl

      # Add private bin directory to PATH
      export PATH="$HOME/.bin:$PATH"

      # Load script-specific aliases
      if [[ -f "$HOME/.bin/aliases.sh" ]]; then
        source "$HOME/.bin/aliases.sh"
      fi
      ```

      ### 2. Script Naming Conventions

      Adopt consistent naming conventions for scripts to make them easier to find and understand:

      #### Prefix-based Naming

      Use tool-specific prefixes to group related scripts:

      ```
      ffmpeg-*        # FFmpeg video processing scripts
      imagemagick-*   # ImageMagick image processing scripts
      git-*           # Git-related utilities
      fzf-*           # Fuzzy finder utilities
      ```

      #### Function-based Naming

      Name scripts based on their function:

      ```
      *-batch         # Batch processing scripts
      *-recursive     # Scripts that operate recursively
      *-preview       # Preview generators
      *-resize        # Resizing utilities
      ```

      #### Verb-Noun Pattern

      Use verb-noun patterns for action-oriented scripts:

      ```
      create-silhouette.py
      check-valid-filename
      retry
      exponential-backoff
      ```

      ### 3. Script Categories

      Organize scripts into logical categories based on their purpose:

      #### Media Processing Scripts

      Scripts for processing images and videos:

      ```bash
      # private_dot_bin/executable_ffmpeg-batch-process
      #!/bin/bash

      # Process multiple video files with ffmpeg
      # Usage: ffmpeg-batch-process [options] [directory]

      set -e

      OPTIONS="-vf scale=1280:-1 -c:v libx264 -preset slow -crf 22 -c:a aac -b:a 128k"
      DIR="${1:-.}"

      for file in "$DIR"/*.{mp4,mov,avi}; do
        [[ -f "$file" ]] || continue
        echo "Processing $file..."
        output="${file%.*}_processed.mp4"
        ffmpeg -i "$file" $OPTIONS "$output"
      done
      ```

      #### Development Utilities

      Scripts for development workflows:

      ```bash
      # private_dot_bin/executable_git-status-recursive
      #!/bin/bash

      # Check git status recursively in all subdirectories
      # Usage: git-status-recursive [directory]

      DIR="${1:-.}"

      find "$DIR" -type d -name ".git" | while read gitdir; do
        repo=$(dirname "$gitdir")
        echo -e "\n\033[1;34m$repo\033[0m"
        git -C "$repo" status -s
      done
      ```

      #### System Utilities

      Scripts for system maintenance and configuration:

      ```bash
      # private_dot_bin/executable_post-install-chezmoi
      #!/bin/bash

      # Run after chezmoi install to set up additional components
      # Usage: post-install-chezmoi

      set -e

      echo "Setting up additional components..."

      # Install shell plugins
      if command -v sheldon &>/dev/null; then
        sheldon lock
        sheldon install
      fi

      # Set up SSH config permissions
      if [[ -d "$HOME/.ssh" ]]; then
        chmod 700 "$HOME/.ssh"
        chmod 600 "$HOME/.ssh/config"
      fi

      echo "Post-install setup complete!"
      ```

      ### 4. Script Dependencies

      Manage dependencies between scripts effectively:

      #### Shared Libraries

      Create shared libraries for common functions:

      ```bash
      # private_dot_bin/lib/utils.sh

      # Common utility functions for scripts

      # Log a message to stderr
      log() {
        echo "$@" >&2
      }

      # Check if a command exists
      command_exists() {
        command -v "$1" &>/dev/null
      }

      # Ensure required commands are available
      require_commands() {
        for cmd in "$@"; do
          if ! command_exists "$cmd"; then
            log "Error: Required command '$cmd' not found"
            exit 1
          fi
        done
      }
      ```

      Use the shared library in scripts:

      ```bash
      # private_dot_bin/executable_ffmpeg-batch-process
      #!/bin/bash

      # Source common utilities
      source "$HOME/.bin/lib/utils.sh"

      # Ensure required commands are available
      require_commands ffmpeg

      # Rest of the script...
      ```

      #### Dependency Documentation

      Document dependencies at the top of each script:

      ```bash
      #!/bin/bash

      # Script: ffmpeg-batch-process
      # Description: Process multiple video files with ffmpeg
      # Dependencies: ffmpeg, jq
      # Author: Your Name
      # Version: 1.0

      # Verify dependencies
      for cmd in ffmpeg jq; do
        if ! command -v "$cmd" &>/dev/null; then
          echo "Error: Required command '$cmd' not found" >&2
          exit 1
        fi
      done

      # Rest of the script...
      ```

      #### Script Wrappers

      Create wrapper scripts that handle dependencies:

      ```bash
      # private_dot_bin/executable_video-tools
      #!/bin/bash

      # Wrapper for video processing tools
      # Usage: video-tools [command] [options]

      COMMANDS=(
        "compress"
        "resize"
        "convert"
        "info"
      )

      if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: video-tools [command] [options]"
        echo "Available commands: ${COMMANDS[*]}"
        exit 0
      fi

      COMMAND="$1"
      shift

      case "$COMMAND" in
        compress)
          exec ffmpeg-batch-process "$@"
          ;;
        resize)
          exec ffmpeg-resize "$@"
          ;;
        convert)
          exec ffmpeg-convert "$@"
          ;;
        info)
          exec ffmpeg-duration "$@"
          ;;
        *)
          echo "Unknown command: $COMMAND" >&2
          echo "Available commands: ${COMMANDS[*]}" >&2
          exit 1
          ;;
      esac
      ```

      ## Common Operations

      ### 1. Adding New Files

      ```bash
      # Add a file as a template
      chezmoi add --template ~/.bashrc

      # Add a private file
      chezmoi add --encrypt ~/.ssh/id_rsa

      # Add a directory
      chezmoi add ~/.config/nvim
      ```

      ### 2. Applying Changes

      ```bash
      # Apply all changes
      chezmoi apply

      # Apply specific files
      chezmoi apply ~/.bashrc

      # Apply with debug information
      chezmoi apply -v
      ```

      ### 3. Managing Source Files

      ```bash
      # Edit a managed file
      chezmoi edit ~/.bashrc

      # View changes before applying
      chezmoi diff

      # Update from source repository
      chezmoi update
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
      export PATH="/opt/homebrew/bin:$PATH"
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
