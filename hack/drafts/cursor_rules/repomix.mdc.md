---
description: Repomix tool
globs: *
alwaysApply: false
---
# Repomix Project Layout

Rules for understanding and navigating the repomix project structure.

<rule>
name: project_layout_guide
description: Guide to the repomix project structure and organization
filters:
  # Match any file in the project
  - type: file_extension
    pattern: ".*"
  # Match project initialization events
  - type: event
    pattern: "file_create"

actions:
  - type: suggest
    message: |
      # Repomix Project Structure

      This repository implements a tool for code repository summarization and packaging for LLM consumption.

      ## Core Features

      - **Repository Summarization:** Extracts and summarizes code repositories
      - **Code Packaging:** Prepares code for LLM consumption
      - **Security Checks:** Validates file safety and filters untrusted files
      - **Multiple Output Formats:** Supports markdown, plain text, and XML output styles
      - **CLI Interface:** Command-line interface for easy usage
      - **Web Interface:** Browser-based interface for repository processing

      ## Directory Structure

      ```
      .
      ├── .cursor/                     # Active cursor rules directory
      │   └── rules/                   # Production cursor rules
      ├── bin/                         # Binary executables
      │   └── repomix.cjs              # Main executable
      ├── src/                         # Source code
      │   ├── cli/                     # Command-line interface
      │   │   ├── actions/             # CLI action implementations
      │   │   ├── cliPrint.ts          # CLI output utilities
      │   │   ├── cliRun.ts            # CLI execution logic
      │   │   ├── cliSpinner.ts        # CLI progress indicators
      │   │   └── types.ts             # CLI type definitions
      │   ├── config/                  # Configuration handling
      │   │   ├── configLoad.ts        # Config loading utilities
      │   │   ├── configSchema.ts      # Config validation schema
      │   │   ├── defaultIgnore.ts     # Default ignore patterns
      │   │   └── globalDirectory.ts   # Global directory management
      │   ├── core/                    # Core functionality
      │   │   ├── file/                # File operations
      │   │   ├── metrics/             # Metrics calculation
      │   │   ├── output/              # Output generation
      │   │   ├── packager/            # Output packaging
      │   │   ├── security/            # Security validation
      │   │   ├── tokenCount/          # Token counting utilities
      │   │   └── treeSitter/          # Code parsing with tree-sitter
      │   ├── index.ts                 # Main entry point
      │   └── shared/                  # Shared utilities
      │       ├── constants.ts         # Shared constants
      │       ├── errorHandle.ts       # Error handling
      │       ├── logger.ts            # Logging utilities
      │       ├── processConcurrency.ts # Concurrency management
      │       └── types.ts             # Shared type definitions
      ├── tests/                       # Test suites
      │   ├── cli/                     # CLI tests
      │   ├── config/                  # Configuration tests
      │   ├── core/                    # Core functionality tests
      │   ├── integration-tests/       # Integration tests
      │   ├── shared/                  # Shared utility tests
      │   └── testing/                 # Test utilities
      └── website/                     # Web interface
          ├── client/                  # Frontend application
          │   ├── components/          # Vue components
          │   └── src/                 # Frontend source code
          └── server/                  # Backend server
              └── src/                 # Server source code
      ```

      ## Primary Components

      ### Source Code (`src/`)
      Core TypeScript application code organized into modules:
      - `cli/`: Command-line interface implementation
      - `config/`: Configuration management
      - `core/`: Core functionality including file processing, security, and output generation
      - `shared/`: Shared utilities and types

      ### Tests (`tests/`)
      Comprehensive test suite including unit tests and integration tests for all components.

      ### Website (`website/`)
      Web interface for the application with client and server components:
      - `client/`: Vue-based frontend application
      - `server/`: Backend API server

      ### Binary (`bin/`)
      Executable files for running the application from the command line.

      ## Development Workflow

      ### Feature Development
      1. **Understand Requirements** - Review existing code and documentation
      2. **Implement Changes** - Add or modify code with appropriate tests
      3. **Test Thoroughly** - Run tests to ensure functionality
      4. **Document Changes** - Update documentation as needed

      ### Testing
      - Run unit tests: `npm test`
      - Run specific tests: `npm test -- <test-pattern>`
      - Run integration tests: `npm run test:integration`

      ### Building
      - Build the application: `npm run build`
      - Build the website: `cd website && npm run build`

examples:
  - input: |
      # I'm new to the project, where should I put my code for a new CLI command?
    output: |
      For a new CLI command, you should:

      1. Create a new action file in `src/cli/actions/` (e.g., `myNewAction.ts`)
      2. Implement the action following the pattern of existing actions
      3. Add appropriate tests in `tests/cli/actions/`
      4. Update the CLI command registration in the main CLI runner

      Look at existing action files like `defaultAction.ts` or `initAction.ts` for examples of the structure.

  - input: |
      # How is the code parsing functionality organized?
    output: |
      The code parsing functionality is in the `src/core/treeSitter/` directory:

      - `ext2Lang.ts`: Maps file extensions to language types
      - `lang2Query.ts`: Maps languages to appropriate queries
      - `languageParser.ts`: Core parsing functionality
      - `loadLanguage.ts`: Loads language grammars
      - `parseFile.ts`: Main file parsing entry point
      - `parseStrategies/`: Language-specific parsing strategies
      - `queries/`: Tree-sitter queries for different languages

      This module uses tree-sitter to parse code files and extract meaningful information.

metadata:
  priority: high
  version: 1.0
  tags:
    - project-structure
    - organization
    - development-workflow
</rule>

<rule>
name: project_standards
description: Standards for code quality and organization in the repomix project
filters:
  # Match any file in the project
  - type: file_extension
    pattern: ".*"
  # Match project initialization events
  - type: event
    pattern: "file_create"

actions:
  - type: suggest
    message: |
      # Repomix Project Standards

      ## TypeScript Standards

      - **Code Style**: Follow the project's biome.json configuration
      - **Type Safety**: Strong typing for all functions and classes
      - **Documentation**: JSDoc comments for public APIs
      - **Testing**: Comprehensive test coverage with vitest

      ## Project Structure Standards

      - **Module Organization**: Functionality grouped by domain (cli, core, config)
      - **Component Isolation**: Clear separation of concerns between modules
      - **Worker Architecture**: CPU-intensive tasks use worker threads
      - **Error Handling**: Consistent error handling patterns

      ## Web Interface Standards

      - **Frontend**: Vue.js components with TypeScript
      - **Backend**: Node.js API with TypeScript
      - **Internationalization**: Support for multiple languages
      - **Responsive Design**: Mobile and desktop friendly UI

      ## Security Standards

      - **Input Validation**: Validate all user inputs
      - **File Safety**: Check files for potential security issues
      - **Permission Checks**: Verify file access permissions
      - **Rate Limiting**: Prevent abuse of API endpoints

      ## Validation Requirements

      - All code must have appropriate type annotations
      - All public APIs must have documentation comments
      - All code must have corresponding tests
      - All UI components must support internationalization
      - Security checks must be applied to all file operations

examples:
  - input: |
      # What are the requirements for TypeScript code in this project?
    output: |
      TypeScript code in this project must:
      1. Follow the code style defined in biome.json
      2. Use strong typing for all functions, variables, and classes
      3. Include JSDoc comments for public APIs
      4. Be accompanied by comprehensive tests
      5. Follow the module organization pattern (cli, core, config, etc.)
      6. Implement proper error handling

  - input: |
      # How should I structure a new feature?
    output: |
      When adding a new feature:

      1. Identify the appropriate module (cli, core, config, etc.)
      2. Create new files following the existing naming patterns
      3. Implement the feature with proper typing and documentation
      4. Add comprehensive tests in the corresponding test directory
      5. Update any relevant documentation
      6. Ensure the feature follows security standards if handling files or user input

metadata:
  priority: high
  version: 1.0
  tags:
    - standards
    - code-quality
    - organization
</rule>

<rule>
name: repomix_context_extraction
description: Guide for using repomix to extract focused context from repositories
filters:
  - type: message
    pattern: "(?i)(extract context|code context|repository context|repomix extract|code explanation|understand code)"
  - type: context
    pattern: "explain code|understand repository|extract code|code extraction"

actions:
  - type: suggest
    message: |
      # Repomix Context Extraction Guide

      Repomix is a powerful tool for extracting and summarizing code repositories for LLM consumption. This guide focuses on using repomix to extract only the necessary context to explain how specific functionality works.

      ## Core Principles for Effective Context Extraction

      - **Focused Selection**: Only include files/folders directly relevant to the functionality
      - **Complete Understanding**: Ensure all dependencies are included for a complete explanation
      - **XML Output**: Use XML format for structured representation of code
      - **Minimal Context**: Avoid including unnecessary files that add noise
      - **Consistent Ignore Patterns**: Use standard ignore patterns for common build artifacts and dependencies

      ## Command Structure

      ```bash
      repomix extract /path/to/repository --style xml --include "path/to/relevant/files/**" --exclude "tests/**" --ignore "**/node_modules,**/dist,**/build" --output output.xml
      ```

      ## Key Parameters

      - `--style xml`: Output in XML format for structured representation
      - `--include`: Specify patterns for files to include (supports glob patterns)
      - `--exclude`: Specify patterns for files to exclude
      - `--ignore`: Specify patterns for files to ignore (build artifacts, dependencies)
      - `--output`: Specify the output file
      - `--output-show-line-numbers`: Include line numbers in the output (helpful for reference)
      - `--max-tokens`: Limit the total token count (optional)
      - `--depth`: Control the depth of directory traversal (optional)

      ## Standard Ignore Patterns

      Always include these standard ignore patterns to avoid including unnecessary files:

      ```bash
      --ignore "**/uv.lock,**/package-lock.json,**/.env,**/Cargo.lock,**/node_modules,**/target,**/dist,**/build,**/output.txt,**/yarn.lock"
      ```

      ## Best Practices

      ### 1. Identify Core Components

      Before extraction, identify the core components needed to explain the functionality:

      - Entry point files
      - Core implementation files
      - Essential utility functions
      - Type definitions and interfaces
      - Configuration files directly related to the functionality

      ### 2. Use Precise Include Patterns

      ```bash
      # Example: Extract authentication system
      repomix extract ./repo --style xml --include "src/auth/**" --include "src/models/User.js" --include "src/config/auth.js" --ignore "**/node_modules,**/dist,**/build,**/package-lock.json" --output-show-line-numbers --output auth-context.xml
      ```

      ### 3. Exclude Unnecessary Files

      ```bash
      # Exclude tests, documentation, and build artifacts
      repomix extract ./repo --style xml --exclude "**/*.test.js" --exclude "**/*.spec.js" --exclude "docs/**" --ignore "**/uv.lock,**/package-lock.json,**/.env,**/Cargo.lock,**/node_modules,**/target,**/dist,**/build,**/output.txt,**/yarn.lock" --output-show-line-numbers --output clean-context.xml
      ```

      ### 4. Combine With Search When Needed

      For complex functionality spanning multiple directories:

      ```bash
      # First find relevant files
      find ./repo -type f -name "*.js" | grep -E "auth|user|permission" > relevant_files.txt

      # Then use the list with repomix
      cat relevant_files.txt | xargs -I{} echo "--include {}" | xargs repomix extract ./repo --style xml --ignore "**/node_modules,**/dist,**/build" --output-show-line-numbers --output auth-system.xml
      ```

      ### 5. Focus on Interfaces Over Implementation Details

      When explaining how something works, prioritize interface files and core logic over detailed implementations:

      ```bash
      repomix extract ./repo --style xml --include "src/api/**/*.interface.ts" --include "src/core/**/*.ts" --exclude "**/*.impl.ts" --ignore "**/uv.lock,**/package-lock.json,**/.env,**/Cargo.lock,**/node_modules,**/target,**/dist,**/build,**/output.txt,**/yarn.lock" --output-show-line-numbers --output system-overview.xml
      ```

      ## Example Scenarios

      ### Extracting a Feature Implementation

      ```bash
      # Extract everything related to the search feature
      repomix extract ./repo --style xml --include "src/**/search/**" --include "src/models/SearchIndex.js" --include "src/utils/searchHelpers.js" --ignore "**/uv.lock,**/package-lock.json,**/.env,**/Cargo.lock,**/node_modules,**/target,**/dist,**/build,**/output.txt,**/yarn.lock" --output-show-line-numbers --output search-feature.xml
      ```

      ### Extracting an API Endpoint Flow

      ```bash
      # Extract files related to the user registration flow
      repomix extract ./repo --style xml --include "src/controllers/UserController.js" --include "src/services/UserService.js" --include "src/models/User.js" --include "src/validators/userValidation.js" --ignore "**/node_modules,**/dist,**/build" --output-show-line-numbers --output user-registration.xml
      ```

      ### Extracting Architecture Overview

      ```bash
      # Extract core architectural files
      repomix extract ./repo --style xml --include "src/core/**/*.ts" --include "src/types/**/*.ts" --include "src/config/**/*.ts" --exclude "**/*.test.ts" --ignore "**/uv.lock,**/package-lock.json,**/.env,**/Cargo.lock,**/node_modules,**/target,**/dist,**/build,**/output.txt,**/yarn.lock" --output-show-line-numbers --output architecture.xml
      ```

      ### Quick Repository Summary

      ```bash
      # Generate a quick summary of the entire repository
      npx repomix --style xml --output-show-line-numbers --output output.txt --ignore "**/uv.lock,**/package-lock.json,**/.env,**/Cargo.lock,**/node_modules,**/target,**/dist,**/build,**/output.txt,**/yarn.lock"
      ```

examples:
  - input: |
      How can I use repomix to extract just the authentication system from my repository?
    output: |
      To extract just the authentication system from your repository using repomix with XML output:

      ```bash
      repomix extract ./your-repo --style xml \
        --include "src/**/auth/**" \
        --include "src/**/user/**" \
        --include "src/models/User.*" \
        --include "src/middleware/auth.*" \
        --include "src/config/auth.*" \
        --exclude "**/*.test.*" \
        --exclude "**/*.spec.*" \
        --ignore "**/uv.lock,**/package-lock.json,**/.env,**/Cargo.lock,**/node_modules,**/target,**/dist,**/build,**/output.txt,**/yarn.lock" \
        --output-show-line-numbers \
        --output auth-system.xml
      ```

      This command:
      1. Targets all auth-related files and directories
      2. Includes user-related files that are typically part of authentication
      3. Includes specific model, middleware, and config files related to auth
      4. Excludes test files to keep the output focused
      5. Ignores common build artifacts and dependencies
      6. Includes line numbers for easier reference
      7. Outputs in XML format for structured representation

      If you need to be even more selective, first identify the exact files involved:

      ```bash
      find ./your-repo -type f -name "*.js" | grep -E "auth|login|register|user|permission|role" | less
      ```

      Then use those specific files in your include patterns.

  - input: |
      I need to extract context to explain how the data processing pipeline works in my repo.
    output: |
      To extract context that explains how a data processing pipeline works:

      ```bash
      repomix extract ./your-repo --style xml \
        --include "src/**/pipeline/**" \
        --include "src/**/processors/**" \
        --include "src/models/DataModel.*" \
        --include "src/utils/dataUtils.*" \
        --include "src/config/pipeline.*" \
        --include "src/types/data.*" \
        --exclude "**/*.test.*" \
        --exclude "**/mock*" \
        --ignore "**/uv.lock,**/package-lock.json,**/.env,**/Cargo.lock,**/node_modules,**/target,**/dist,**/build,**/output.txt,**/yarn.lock" \
        --output-show-line-numbers \
        --output data-pipeline.xml
      ```

      This approach:
      1. Focuses on pipeline and processor directories
      2. Includes relevant data models and utilities
      3. Includes pipeline configuration
      4. Includes type definitions for data structures
      5. Excludes tests and mock data
      6. Ignores common build artifacts and dependencies
      7. Includes line numbers for easier reference

      For a more comprehensive understanding, you might want to include the entry points:

      ```bash
      repomix extract ./your-repo --style xml \
        --include "src/index.*" \
        --include "src/**/pipeline/**" \
        --include "src/**/processors/**" \
        --include "src/models/DataModel.*" \
        --include "src/utils/dataUtils.*" \
        --include "src/config/pipeline.*" \
        --include "src/types/data.*" \
        --exclude "**/*.test.*" \
        --exclude "**/mock*" \
        --ignore "**/uv.lock,**/package-lock.json,**/.env,**/Cargo.lock,**/node_modules,**/target,**/dist,**/build,**/output.txt,**/yarn.lock" \
        --output-show-line-numbers \
        --output data-pipeline-with-entry.xml
      ```

      This ensures you capture how the pipeline is initialized and triggered.

  - input: |
      How do I create a quick summary of my entire repository for an LLM?
    output: |
      For a quick summary of your entire repository optimized for LLM consumption:

      ```bash
      npx repomix --style xml --output-show-line-numbers --output output.txt --ignore "**/uv.lock,**/package-lock.json,**/.env,**/Cargo.lock,**/node_modules,**/target,**/dist,**/build,**/output.txt,**/yarn.lock"
      ```

      This command:
      1. Uses repomix to process your repository
      2. Outputs in XML format for structured representation
      3. Includes line numbers for easier reference
      4. Ignores common build artifacts and dependencies
      5. Creates an output.txt file with the repository summary

      If you want to focus on specific aspects while still getting a broad overview:

      ```bash
      npx repomix --style xml --include "src/**/*.ts" --include "src/**/*.js" --exclude "**/*.test.*" --ignore "**/uv.lock,**/package-lock.json,**/.env,**/Cargo.lock,**/node_modules,**/target,**/dist,**/build,**/output.txt,**/yarn.lock" --output-show-line-numbers --output repo-summary.xml
      ```

      This will include all TypeScript and JavaScript files while excluding tests and common artifacts.

metadata:
  priority: high
  version: 1.0
  tags:
    - context-extraction
    - code-understanding
    - repomix-usage
</rule>
