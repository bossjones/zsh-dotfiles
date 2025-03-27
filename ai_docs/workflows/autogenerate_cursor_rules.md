# How to Auto-Generate Cursor Rules for Your Repository

This guide will walk you through the process of automatically generating custom cursor rules for your repository using AI. These steps are designed to be simple enough for anyone to follow.

## What You'll Need

- Cursor AI editor
- A GitHub repository you want to create cursor rules for
- Access to the prompt_library and sequentialthinking MCP servers

## Step 1: Generate a Repository Report

First, we need to analyze your repository to understand its structure and technologies.

1. Open your repository in Cursor AI
2. Ask Cursor to analyze your repository using the repo_analyzer cursor rule

**Example prompt:**
```
Can you analyze this repository and create a comprehensive report about its structure, technologies, and patterns? Please use the @repo_analyzer.mdc cursor rule to guide your analysis.
```

### Detailed Example: Analyzing a ZSH Dotfiles Repository

> **Note:** The following zsh-dotfiles repository analysis is provided as a reference example only. You should adapt these approaches to your specific repository and its technologies. The specific files, directories, and technologies mentioned are unique to this example repository.

Here's a real example of how to analyze a repository step by step:

**Initial request:**
```
Please analyze the `zsh-dotfiles` repository and generate a report named `zsh_dotfiles_report.md`, which will detail the technologies used in the repository.
```

Cursor will begin by examining the repository structure. You can help it by suggesting specific approaches:

```
Let's start by visualizing the directory structure using the `tree` command while excluding specific file types and directories.
```

As Cursor analyzes the repository, it will:

1. Retrieve and analyze key files like:
   - `Makefile`
   - `.pre-commit-config.yaml`
   - `requirements-test.txt`
   - `README.md`
   - Configuration files (`.zshrc`, `.chezmoi.yaml.tmpl`, etc.)
   - Test files (`test_dotfiles.py`, `conftest.py`)

2. Examine specific configuration directories:
   - `home/dot_sheldon` for plugin management
   - `home/shell/config.zsh` for ZSH settings
   - `home/shell/customs/aliases.zsh` for custom functions

3. Check installation scripts:
   - `home/.chezmoiscripts/run_onchange_before_02-macos-install-sheldon.sh.tmpl`
   - `home/.chezmoiscripts/run_onchange_before_01-ubuntu-install-packages.sh.tmpl`

The final report will include:
- Overview of the repository
- Repository structure
- Core technologies used (Chezmoi, Sheldon, ASDF, etc.)
- ZSH configuration details
- Installation scripts
- Custom aliases and functions
- External dependencies
- Configuration features
- Cross-platform support
- Security considerations

3. Save this report to a file, for example: `zsh_dotfiles_report.md`

The report will look something like this:
```markdown
# ZSH Dotfiles Repository Analysis

## Overview
The [zsh-dotfiles](https://github.com/bossjones/zsh-dotfiles) repository is a comprehensive dotfiles management system created by Malcolm Jones (bossjones). It uses [chezmoi](https://www.chezmoi.io/) as the primary dotfile management tool to maintain consistent shell environments across different machines and operating systems.

## Repository Structure
The repository follows a structured approach with the following key components:
- **home/**: The main directory containing all dotfiles that will be managed by chezmoi
  - **.chezmoiscripts/**: Contains installation and setup scripts that run during chezmoi apply
  - **shell/**: Contains ZSH configuration files and custom scripts
  - **dot_sheldon/**: Contains configuration for the Sheldon plugin manager
  - **private_dot_bin/**: Contains executable scripts and utilities

## Core Technologies
[Detailed breakdown of technologies used]
...
```

> **Important:** Your repository analysis will differ based on your project's specific structure and technologies. Use the above example as a template for the type of information to gather, but customize your approach to your repository's unique characteristics.

## Step 2: Ensure Required MCP Servers are Configured

Before proceeding, make sure both the prompt_library and sequentialthinking MCP servers are properly configured:

1. Check your `.cursor/mcp.json` file to ensure both servers are enabled
2. The configuration should look something like this:

```json
{
  "mcpServers": {
    "memory": {
      "command": "env",
      "args": [
        "MEMORY_FILE_PATH=./ai_docs/memory.json",
        "npx",
        "-y",
        "@modelcontextprotocol/server-memory"
      ]
    },
    "prompt_library": {
      "command": "uv",
      "args": [
        "run",
        "--with",
        "mcp[cli]",
        "mcp",
        "run",
        "/Users/malcolm/dev/bossjones/codegen-lab/src/codegen_lab/prompt_library.py"
      ]
    },
    "sequentialthinking": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-sequential-thinking"
      ]
    }
  }
}
```

3. Make sure both servers are running (you may need to start them if they're not already running)
4. The sequentialthinking server is particularly important for breaking down complex analysis tasks and generating high-quality cursor rules

## Step 3: Generate Custom Cursor Rules

Now we'll use the repository report to generate custom cursor rules:

1. Open a new chat with Cursor AI
2. Ask Cursor to recommend cursor rules based on your repository report

**Example prompt:**
```
Using the prompt_library and sequentialthinking mcp servers, help me recommend cursor rules for this project based on @your_repository_report.md
```

3. Cursor will analyze the report and suggest appropriate cursor rules for your repository

The response will look something like this:
```
Based on the analysis of your repository, I'll recommend several cursor rules that would be beneficial for this project:

### 1. [Rule Name]
[Rule content in markdown format]

### 2. [Rule Name]
[Rule content in markdown format]

...
```

## Step 4: Save the Generated Cursor Rules

Now you need to save the generated rules:

1. Create a directory for your cursor rules if it doesn't exist:
   ```bash
   mkdir -p .cursor/rules
   ```

2. Save each rule as a separate file in the `.cursor/rules` directory with a `.mdc` extension:
   - `.cursor/rules/rule-name-1.mdc`
   - `.cursor/rules/rule-name-2.mdc`
   - etc.

3. You can either:
   - Copy and paste each rule manually
   - Ask Cursor to create these files for you with a prompt like:
     ```
     Please save this cursor rule as .cursor/rules/rule-name.mdc
     ```

## Step 5: Test Your New Cursor Rules

After saving your cursor rules:

1. Restart Cursor or reload the window
2. Open a file that should trigger one of your new rules
3. Cursor should now provide suggestions based on your custom rules

## Example Workflow Results

Here's what the entire process looks like in practice:

> **Note:** The following example is based on the zsh-dotfiles repository and is provided for reference only. Your specific questions and analysis should be tailored to your repository's technologies and structure.

1. **Repository Analysis Request:**
   ```
   Please analyze the `zsh-dotfiles` repository and generate a report named `zsh_dotfiles_report.md`, which will detail the technologies used in the repository.
   ```

2. **Specific Analysis Questions:**
   ```
   Let's check the ZSH configuration by examining the `home/shell/config.zsh` file to understand its settings and configurations.
   ```

   ```
   Let's check the Sheldon configuration to understand the plugin management.
   ```

   ```
   Let's check the `home/dot_zshrc.tmpl` file to understand the ZSH configuration.
   ```

   ```
   Let's check the `home/shell/init.zsh` file to understand the initialization process.
   ```

   ```
   Let's check the `home/shell/customs/aliases.zsh` file to understand the custom aliases defined by the user.
   ```

   ```
   Let's check the `.chezmoi.yaml.tmpl` file to understand the chezmoi configuration.
   ```

   ```
   Let's check the `.chezmoiexternal.yaml` file to understand external dependencies related to the configuration.
   ```

   ```
   Let's check one of the installation scripts to understand how the dotfiles are set up, specifically looking at the file located at `home/.chezmoiscripts/run_onchange_before_02-macos-install-sheldon.sh.tmpl`.
   ```

3. **Generated Repository Report:**
   A detailed markdown file (`zsh_dotfiles_report.md`) describing the repository structure, technologies, and patterns.

4. **Cursor Rules Generation Request:**
   ```
   Using the prompt_library and sequentialthinking mcp servers, help me recommend cursor rules for this project based on @zsh_dotfiles_report.md
   ```

5. **Generated Cursor Rules:**
   ```markdown
   # Chezmoi Template Best Practices

   Guidelines for working with Chezmoi templates in the zsh-dotfiles repository.

   <rule>
   name: chezmoi-templates
   description: Best practices for Chezmoi template files
   filters:
     # Match Chezmoi template files
     - type: file_extension
       pattern: "\\.tmpl$"
     # Match Chezmoi configuration files
     - type: file_path
       pattern: "\\.chezmoi.*"

   actions:
     - type: suggest
       message: |
         # Chezmoi Template Best Practices
         ...
   ```

6. **Saved Rules:**
   Multiple `.mdc` files in the `.cursor/rules` directory, each containing a custom rule tailored to your repository.

## Key Insights from Repository Analysis

When analyzing a repository for cursor rule generation, focus on:

1. **Configuration Patterns**: Look for template files, configuration formats, and conditional logic
2. **Directory Structure**: Understand how the repository organizes its files and components
3. **Technology Stack**: Identify the main technologies, tools, and frameworks used
4. **Custom Scripts**: Examine installation scripts, utility functions, and automation tools
5. **Cross-Platform Support**: Note how the repository handles different operating systems
6. **Security Practices**: Identify patterns for handling sensitive data

For a dotfiles repository like the example above, pay special attention to:
- Template systems (like Chezmoi's `.tmpl` files)
- Plugin management (like Sheldon's configuration)
- Shell customizations (aliases, functions, options)
- Installation scripts for different platforms
- External dependencies and their management

> **Remember:** The zsh-dotfiles example is just one type of repository. Your analysis should focus on the specific technologies and patterns in your own repository. For example, a React application would focus on component structure, state management, and routing, while a Python data science project would focus on data processing pipelines, model training, and visualization tools.

## Benefits of Custom Cursor Rules

- **Consistency:** Ensures all team members follow the same coding standards
- **Efficiency:** Provides contextual suggestions specific to your project
- **Knowledge Sharing:** Captures project-specific best practices
- **Onboarding:** Helps new team members understand project conventions
- **Documentation:** Serves as interactive documentation for project patterns

## Advanced Tips

- **Iterative Refinement**: After generating initial rules, test them and refine based on usage
- **Combine with Documentation**: Link cursor rules to more detailed documentation
- **Team Collaboration**: Have team members contribute to rule development
- **Version Control**: Keep cursor rules in version control to track changes
- **Regular Updates**: Update rules as project patterns evolve

By following this workflow, you can create custom cursor rules that are specifically tailored to your repository's unique structure and technologies.
