---
description: Get Context for LLM
globs: **/*.py, **/*.js, **/*.ts, **/*.jsx, **/*.tsx, **/*.rs, **/*.go, **/*.cpp, **/*.java, **/*.md
alwaysApply: false
---
# Get Context for LLM

Automation for generating codebase context for LLMs using repomix and taskfile.

<rule>
name: get-context-for-llm
description: Automate context generation for LLMs based on Harper Reed's workflow
filters:
  # Match code files with common extensions
  - type: file_extension
    pattern: "\\.(py|js|ts|jsx|tsx|rs|go|cpp|java|md)$"
  # Match file creation or edit events
  - type: event
    pattern: "(file_create|file_edit)"

actions:
  - type: suggest
    message: |
      ## LLM Context Generation Workflows

      Need to share your codebase with an LLM? Use the following workflows to generate context:

      ### Quick Context Generation:

      ```bash
      # 1. Generate a bundle of your codebase
      task llm:generate_bundle

      # 2. Copy the generated context to your clipboard
      task llm:copy_buffer_bundle

      # 3. Paste into your LLM prompt
      ```

      ### Customizing Context Generation:

      To manage token limits, customize ignored files in `.repomixrc.json` before generating.

      ### Task-Specific Commands:

      - Generate missing tests: `task llm:generate_missing_tests`
      - Get a code review: `task llm:generate_code_review`
      - Generate GitHub issues: `task llm:generate_github_issues`

      ### Workflow Tips:

      1. Be specific about what you're asking the LLM to do
      2. Use headings in your prompt to separate context from instructions
      3. For large codebases, focus only on relevant files using `.repomixrc.json`

examples:
  - input: |
      # Generating context for debugging

      I need to fix a bug in my codebase and want to share context with Claude.
    output: |
      Run the following:
      ```bash
      task llm:generate_bundle
      task llm:copy_buffer_bundle
      ```
      Then paste the context into your LLM prompt with clear instructions about the bug.

metadata:
  priority: medium
  version: 1.0
  deployment: "Use 'make update-cursor-rules' to deploy to .cursor/rules/"
</rule>
