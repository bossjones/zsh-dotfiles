---
description: Greenfield Documentation Standards
globs: spec.md, prompt_plan.md, todo.md
alwaysApply: false
---
# Greenfield Documentation Standards

Standards for maintaining documentation artifacts created during the Greenfield development process.

<rule>
name: greenfield-documentation-standards
description: Standards for maintaining spec.md, prompt_plan.md, and todo.md in Greenfield projects
filters:
  # Match Greenfield documentation files
  - type: file_name
    pattern: "(spec|prompt_plan|todo)\\.md$"
  # Match edit events on these files
  - type: event
    pattern: "file_edit"

actions:
  - type: suggest
    message: |
      # Greenfield Documentation Standards

      When working with documentation for Greenfield projects, follow these standards:

      ## spec.md

      This document represents your comprehensive project specification:

      - Keep the spec document updated as requirements evolve
      - Structure with clear sections (Requirements, Architecture, Data Model, etc.)
      - Include diagrams where helpful (can be added after initial generation)
      - Reference this document when implementing new features
      - Don't modify the spec arbitrarily; update it only when requirements genuinely change

      ## prompt_plan.md

      This document contains your implementation plan:

      - Maintain the sequential nature of the prompts
      - Mark completed prompts/sections to track progress
      - Add notes about implementation challenges or discoveries
      - Use this as a reference when communicating with the LLM during implementation
      - Add new prompts at the end when extending functionality

      ## todo.md

      This is your progress tracking document:

      - Check off items as they are completed
      - Add new items for discovered tasks
      - Group related tasks together
      - Add notes about implementation details or challenges
      - Use priority markers for urgent tasks (e.g., (P1), (P2), etc.)
      - Include links to relevant files or resources when appropriate

      ## General Documentation Guidelines

      - Commit documentation changes alongside code changes
      - Review documentation regularly for accuracy
      - Use consistent formatting and style
      - Date major updates to track evolution of the project
      - Reference specific sections in commit messages when relevant

examples:
  - input: |
      # Bad: Inconsistent spec.md structure
      Random thoughts about the project...
      We need a user login.
      Probably use PostgreSQL.

      # Good: Well-structured spec.md
      # Project Specification

      ## Overview
      Brief description of the project purpose and goals.

      ## Requirements
      - User authentication with email/password
      - Product catalog with search functionality
      - Shopping cart with persistent storage

      ## Architecture
      Three-tier architecture with React frontend, Node.js backend, and PostgreSQL database.

      ## Data Models
      Detailed schema information for User, Product, Order, etc.
    output: "Properly structured specification document"

  - input: |
      # Bad: Messy todo.md
      - add login
      - fix bugs
      - make it pretty

      # Good: Well-structured todo.md
      # Project Todo List

      ## User Authentication
      - [x] Set up basic auth routes
      - [x] Implement user registration
      - [ ] Add password reset functionality
      - [ ] Implement OAuth integration

      ## Product Management
      - [x] Create product model
      - [x] Build product listing page
      - [ ] Implement search functionality (P1)
      - [ ] Add filtering options
    output: "Organized and trackable todo list"

metadata:
  priority: medium
  version: 1.0
  tags:
    - documentation
    - greenfield
    - process
</rule>
