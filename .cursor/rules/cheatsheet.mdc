---
description: Cheatsheet Creation Best Practices
globs: *.cheat, **/*.cheat
alwaysApply: false
---
# Cheatsheet Creation Expert

Guidelines for creating well-structured command cheatsheets following best practices for documentation.

<rule>
name: cheatsheet-expert
description: Standards and best practices for creating command cheatsheets
filters:
  # Match cheatsheet files
  - type: file_extension
    pattern: "\\.cheat$"
  # Match markdown files that might be cheatsheets
  - type: file_extension
    pattern: "\\.md$"
  # Match content that looks like a command reference
  - type: content
    pattern: "(?s)(```sh|```bash|command|usage:)"
  # Match file creation events
  - type: event
    pattern: "file_create"

actions:
  - type: suggest
    message: |
      # 📝 Cheatsheet Creation Best Practices

      When creating a command cheatsheet, follow these guidelines for clarity and consistency:

      ## 📋 Structure Guidelines

      1. **Header Format**:
         - Use YAML frontmatter at the beginning (optional but recommended)
         - Include syntax highlighting type and relevant tags
         ```yaml
         ---
         syntax: bash
         tags: [ networking, linux, administration ]
         description: "Brief description of the command's purpose"
         ---
         ```

      2. **Command Format**:
         - Start with the command name as a heading
         - Provide a brief description of its purpose
         - Group similar operations under subheadings
         - Use code blocks with proper syntax highlighting

      3. **Example Format**:
         - Show the basic command syntax first
         - Follow with common usage examples
         - Include explanations for complex options
         - Use comments to explain what each part does

      4. **Organization**:
         - Group related commands together
         - Arrange options from basic to advanced
         - Include common flags and their meanings
         - Add troubleshooting tips for common issues

      ## 🌟 Example Template

      ```markdown
      ---
      syntax: bash
      tags: [ database, administration ]
      description: "PostgreSQL command line client"
      ---
      # psql

      PostgreSQL interactive terminal.

      ## Basic Connection

      # Connect to a specific database
      psql -d database_name

      # Connect with a specific user
      psql -d database_name -U user_name

      # Connect to a remote host
      psql -h hostname -d database_name -U username

      ## Common Operations

      # List all databases
      \l

      # Connect to another database
      \c database_name

      # List all tables
      \dt

      # Describe a table
      \d table_name

      # Execute SQL from a file
      \i filename.sql

      ## Advanced Usage

      # Export query results to a CSV file
      \copy (SELECT * FROM table_name) TO 'output.csv' WITH CSV HEADER

      # Set output format
      \x on  # Expanded display
      \x off # Normal display
      ```

      ## 📊 Naming Conventions

      1. **File Names**:
         - Use the command name as the file name
         - For subcommands, use a directory structure:
           ```
           git/
           ├── clone.cheat
           ├── commit.cheat
           └── push.cheat
           ```

      2. **Organization**:
         - Create subdirectories for categories
         - Use lowercase for all filenames
         - Be consistent in your organization scheme

      ## 🔍 Additional Tips

      - Include the most common use cases first
      - Add examples for both simple and complex scenarios
      - Use comments to explain what commands do
      - Include any necessary warnings or prerequisites
      - Add reference links to official documentation when helpful
      - Consider including related commands at the bottom
      - Use proper indentation in code blocks for readability
      - Test your examples to ensure they work as expected

examples:
  - input: |
      # Bad: Poorly structured cheatsheet
      ssh commands
      ssh user@host
      scp file user@host:/path
      ssh-keygen

      # Good: Well-structured cheatsheet
      ---
      syntax: bash
      tags: [ networking, ssh, security ]
      description: "Secure Shell client for remote connections"
      ---
      # ssh

      Secure Shell client for remote login and secure network communication.

      ## Basic Connections

      # Connect to a remote server
      ssh username@hostname

      # Connect with a specific port
      ssh -p 2222 username@hostname

      # Connect with a specific identity file
      ssh -i ~/.ssh/id_rsa username@hostname
    output: "Properly structured SSH cheatsheet with clear sections and examples"

  - input: |
      # Bad: Missing code blocks and explanations
      tar
      tar -xzf file.tar.gz
      tar -czf archive.tar.gz directory/

      # Good: Proper code blocks and explanations
      ---
      syntax: bash
      tags: [ archive, compression, unix ]
      description: "Tape Archive utility for file compression and archiving"
      ---
      # tar

      Tape Archive utility for compressing and extracting files.

      ## Extracting Archives

      # Extract a .tar.gz archive
      tar -xzf archive.tar.gz

      # Extract to a specific directory
      tar -xzf archive.tar.gz -C /target/directory

      ## Creating Archives

      # Create a .tar.gz archive from a directory
      tar -czf archive.tar.gz directory/

      # Create a .tar.bz2 archive (better compression, slower)
      tar -cjf archive.tar.bz2 directory/
    output: "Well-structured tar cheatsheet with properly formatted commands and explanations"

metadata:
  priority: high
  version: 1.0
  tags:
    - documentation
    - cheatsheet
    - command-line
</rule>
