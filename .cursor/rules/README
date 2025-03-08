# Non-Greenfield Iterative Development Cursor Rules

This collection of cursor rules implements Harper Reed's non-greenfield iteration workflow as described in [their blog post](https://harper.blog/2025/02/16/my-llm-codegen-workflow-atm/). The rules are designed to help you automatically follow this workflow using Cursor's agent mode.

## Workflow Overview

Harper's non-greenfield iteration workflow involves:

1. **Getting context** from the existing codebase
2. **Planning per task** rather than for the entire project
3. **Implementing incrementally** with constant testing and feedback
4. **Debugging and fixing issues** as they arise

## Rules in this Collection

This collection contains the following cursor rules:

1. **[incremental-task-planner.mdc.md](incremental-task-planner.mdc.md)** - Breaks down a development task into smaller, manageable steps for incremental implementation
2. **[code-context-gatherer.mdc.md](code-context-gatherer.mdc.md)** - Efficiently gathers code context from the codebase for LLM consumption
3. **[test-generator.mdc.md](test-generator.mdc.md)** - Identifies missing tests and generates appropriate test cases for the codebase
4. **[iterative-debug-fix.mdc.md](iterative-debug-fix.mdc.md)** - Provides guidance for debugging and fixing issues that arise during iterative development
5. **[iterative-development-workflow.mdc.md](iterative-development-workflow.mdc.md)** - Master rule that provides a structured workflow for incremental development in existing codebases

## How to Use These Rules

To use these rules in your project:

1. These are draft rules that need to be moved to your `.cursor/rules/` directory for Cursor to apply them
2. Copy the `.mdc.md` files to `.cursor/rules/` in your project
3. Cursor's agent mode will automatically apply these rules based on your queries

## Sample Usage Flow

Here's how you might use these rules in a typical development session:

1. **Start with the workflow**: "Help me implement a feature using the iterative development workflow"
2. **Gather context**: "Help me understand the current authentication system"
3. **Plan your task**: "Break down the task of adding two-factor authentication"
4. **Implement incrementally**: "Help me implement the first step of the 2FA feature"
5. **Add tests**: "Generate tests for the 2FA authentication code"
6. **Debug issues**: "The 2FA verification isn't working, help me debug it"

## Installation

To install these rules in your project:

```bash
mkdir -p .cursor/rules
cp hack/drafts/cursor_rules/*.mdc.md .cursor/rules/
```

## Credits

These rules are based on Harper Reed's blog post ["My LLM codegen workflow atm"](https://harper.blog/2025/02/16/my-llm-codegen-workflow-atm/) which describes an effective iterative development workflow using LLMs.
