---
description: Expert guidance for Sheldon shell plugin manager configuration and debugging
globs: *.toml, *.lock, .zshrc, .bashrc
alwaysApply: false
---

# Sheldon Configuration and Debugging Expert

Guidelines for configuring, troubleshooting, and optimizing Sheldon shell plugin manager.

<rule>
name: sheldon-expert
description: Expert guidance for Sheldon shell plugin manager configuration and debugging
filters:
  # Match Sheldon configuration files
  - type: file_path
    pattern: ".*plugins\\.toml$"
  # Match Sheldon lock files
  - type: file_path
    pattern: ".*plugins\\.lock$"
  # Match shell configuration files
  - type: file_path
    pattern: ".*\\.(zshrc|bashrc)$"
  # Match messages about Sheldon
  - type: message
    pattern: "(?i)(sheldon|shell plugin|zsh plugin|bash plugin)"

actions:
  - type: suggest
    message: |
      # Sheldon Shell Plugin Manager Expert

      ## Configuration Best Practices

      ### Basic Configuration Structure

      Sheldon uses a TOML-based configuration file (`plugins.toml`) with this structure:

      ```toml
      shell = "zsh" # or "bash"

      [plugins]

      [templates]
      ```

      ### Plugin Source Types

      Sheldon supports multiple plugin sources:

      1. **Git repositories**:
         ```toml
         [plugins.example-git]
         git = "https://github.com/username/repo.git"
         ```

      2. **GitHub repositories** (shorthand):
         ```toml
         [plugins.example-github]
         github = "username/repo"
         ```

      3. **GitHub Gists**:
         ```toml
         [plugins.example-gist]
         gist = "username/gist-id"
         ```

      4. **Remote files**:
         ```toml
         [plugins.example-remote]
         remote = "https://example.com/script.sh"
         ```

      5. **Local directories**:
         ```toml
         [plugins.example-local]
         local = "~/path/to/plugin"
         ```

      6. **Inline scripts**:
         ```toml
         [plugins.example-inline]
         inline = """
         # Your shell script here
         alias example="echo 'Hello, world!'"
         """
         ```

      ### Advanced Configuration Options

      #### Git References

      ```toml
      [plugins.example-git]
      git = "https://github.com/username/repo.git"
      branch = "main"  # or use tag = "v1.0.0" or rev = "commit-hash"
      ```

      #### File Matching

      ```toml
      [plugins.example]
      github = "username/repo"
      use = ["*.zsh", "*.sh"]  # Only use files matching these patterns
      ```

      #### Custom Templates

      ```toml
      [templates]
      path = 'source "{{ file }}"'

      [plugins.example]
      github = "username/repo"
      apply = ["path"]  # Apply the "path" template
      ```

      ## Common Commands

      ### Installation and Setup

      ```bash
      # Initialize a new configuration
      sheldon init

      # Add a new plugin
      sheldon add --github username/repo plugin-name

      # Lock plugins (install and generate lock file)
      sheldon lock

      # Generate source script
      sheldon source > ~/.sheldon/sheldon.zsh
      ```

      ### Maintenance

      ```bash
      # Edit configuration
      sheldon edit

      # Remove a plugin
      sheldon remove plugin-name

      # Update all plugins
      sheldon lock --update
      ```

      ## Troubleshooting

      ### Common Issues

      1. **Plugin Not Loading**:
         - Check if the plugin is correctly defined in `plugins.toml`
         - Verify that the plugin source exists and is accessible
         - Check if file matching patterns are correct
         - Ensure the template is properly applied

      2. **Lock File Issues**:
         - Delete `plugins.lock` and run `sheldon lock` to regenerate
         - Check for Git authentication issues if using private repositories
         - Verify network connectivity for remote sources

      3. **Shell Integration**:
         - Ensure your `.zshrc` or `.bashrc` contains:
           ```bash
           eval "$(sheldon source)"
           ```
         - Check that Sheldon is in your PATH

      4. **Performance Issues**:
         - Use `--profile` flag to identify slow plugins
         - Consider using local sources for frequently updated repositories
         - Minimize the number of plugins for better performance

      ### Debugging Commands

      ```bash
      # Verbose output
      sheldon --verbose lock

      # Debug output
      sheldon --debug source

      # Profile plugin loading
      sheldon source --profile
      ```

      ## Shell-Specific Configuration

      ### Zsh Configuration

      ```toml
      shell = "zsh"

      [plugins.zsh-syntax-highlighting]
      github = "zsh-users/zsh-syntax-highlighting"

      [plugins.zsh-autosuggestions]
      github = "zsh-users/zsh-autosuggestions"
      ```

      ### Bash Configuration

      ```toml
      shell = "bash"

      [plugins.bash-completion]
      github = "scop/bash-completion"

      [templates]
      completion = 'source "{{ file }}"'

      [plugins.bash-completion.apply]
      completion = ["bash_completion"]
      ```

      ## Advanced Usage

      ### Custom Templates with Handlebars

      ```toml
      [templates]
      fpath = 'fpath=("{{ dir }}" $fpath)'
      source = 'source "{{ file }}"'

      [plugins.example]
      github = "username/repo"
      apply = [
        { value = "fpath", each = "dir" },
        { value = "source", glob = "*.zsh" }
      ]
      ```

      ### Plugin Dependencies

      ```toml
      [plugins.dependency]
      github = "username/dependency-repo"

      [plugins.main-plugin]
      github = "username/main-repo"
      depends = ["dependency"]
      ```

examples:
  - input: |
      I'm having trouble with my Sheldon configuration. My zsh plugins aren't loading.
    output: |
      Let's troubleshoot your Sheldon configuration for zsh plugins:

      1. First, check your `plugins.toml` file structure:
         ```toml
         shell = "zsh"  # Make sure this is set to "zsh"

         [plugins]
         # Your plugins should be defined here
         ```

      2. Verify your shell integration in `.zshrc`:
         ```bash
         # This line should be in your .zshrc
         eval "$(sheldon source)"
         ```

      3. Check if the lock file is generated:
         ```bash
         # Run this to regenerate the lock file
         sheldon lock
         ```

      4. Debug the source generation:
         ```bash
         # See what's being generated
         sheldon source --verbose
         ```

      5. Common issues to check:
         - Are your plugin URLs correct?
         - Do you have the right branch/tag specified?
         - Are file matching patterns correct?
         - Do you have proper templates defined?

      Can you share your `plugins.toml` file so I can help identify specific issues?

  - input: |
      How do I set up a custom template for my Oh-My-Zsh plugins?
    output: |
      To set up a custom template for Oh-My-Zsh plugins in Sheldon:

      ```toml
      # In your plugins.toml file:

      shell = "zsh"

      [templates]
      # Template for Oh-My-Zsh plugins
      omz_plugin = '''
      export ZSH_CUSTOM="{{ dir }}"
      source "{{ file }}"
      '''

      # For Oh-My-Zsh core
      [plugins.oh-my-zsh]
      github = "ohmyzsh/ohmyzsh"

      # For a specific Oh-My-Zsh plugin
      [plugins.git]
      github = "ohmyzsh/ohmyzsh"
      dir = "plugins/git"
      apply = [{ value = "omz_plugin", glob = "*.plugin.zsh" }]

      # For another plugin
      [plugins.syntax-highlighting]
      github = "zsh-users/zsh-syntax-highlighting"
      apply = [{ value = "omz_plugin", glob = "*.zsh" }]
      ```

      This configuration:
      1. Creates a custom `omz_plugin` template that sets `ZSH_CUSTOM` and sources the plugin file
      2. Applies this template to Oh-My-Zsh plugins
      3. Works with both official Oh-My-Zsh plugins and third-party plugins

      You can customize the template further based on your specific needs.

metadata:
  priority: high
  version: 1.0
  tags:
    - sheldon
    - shell-plugins
    - zsh
    - bash
    - configuration
    - troubleshooting
</rule>
