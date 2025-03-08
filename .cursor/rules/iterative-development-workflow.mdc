---
description: Structured workflow for incremental development in existing codebases
globs: *
alwaysApply: false
---
# Iterative Development Workflow

This rule provides a structured workflow for incremental development in existing codebases.

<rule>
name: iterative-development-workflow
description: Structured workflow for incremental development in existing codebases
filters:
  - type: message
    pattern: "(?i)(help me develop|implement feature|workflow|iterate|incrementally|step by step|non-greenfield)"
  - type: context
    pattern: "existing codebase|update|modify|extend|incrementally"

actions:
  - type: instructions
    message: |
      # Iterative Development Workflow for Existing Codebases

      When the user is working on an existing codebase and needs a structured workflow for incremental development:

      ## Phase 1: Understand and Plan

      1. **Get Context**:
         - Gather relevant code from the existing codebase
         - Understand the current architecture and patterns
         - Identify components that will be affected by the change

      2. **Plan the Task**:
         - Break down the task into small, manageable steps
         - Create a todo checklist for implementation
         - Prioritize steps based on dependencies and complexity

      3. **Define Acceptance Criteria**:
         - Establish clear criteria for when the task is complete
         - Identify what tests will be needed
         - Consider potential edge cases and error conditions

      ## Phase 2: Implement Incrementally

      1. **Start with Core Functionality**:
         - Implement the minimum viable change first
         - Focus on getting the basics working before adding complexity
         - Maintain consistency with existing code patterns

      2. **Test Early and Often**:
         - Write tests for each component as it's implemented
         - Run existing tests to ensure no regressions
         - Use test failures to guide implementation

      3. **Iterate in Small Steps**:
         - Complete one task from the checklist at a time
         - Verify each step works before moving to the next
         - Update the plan as needed based on what you learn

      ## Phase 3: Refine and Complete

      1. **Review and Refactor**:
         - Look for opportunities to improve the implementation
         - Ensure code follows project standards and patterns
         - Address any technical debt introduced during implementation

      2. **Complete Test Coverage**:
         - Fill in any missing tests
         - Test edge cases and error handling
         - Verify all acceptance criteria are met with tests

      3. **Documentation and Integration**:
         - Update documentation as needed
         - Ensure the new code integrates well with the existing system
         - Verify the change meets all requirements

      Follow this workflow for each development task to ensure consistent, high-quality incremental improvements to the codebase.

examples:
  - input: |
      I need to add a new payment method to our existing e-commerce system.
    output: |
      I'll help you implement this feature incrementally, following a structured workflow. Let's start by understanding the current system and planning our approach.

      ## Phase 1: Understand and Plan

      First, let's gather context about the existing payment system:

      I'll search for and analyze the current payment-related code to understand:
      - How existing payment methods are implemented
      - The payment processing flow
      - Integration points with the rest of the system

      Based on this analysis, I'll break down the task:

      **Todo Checklist:**
      1. [ ] Understand current payment gateway integration
      2. [ ] Identify required changes to the payment model/schema
      3. [ ] Plan UI changes for the new payment method
      4. [ ] Design the new payment method processing flow
      5. [ ] Update the payment gateway interface
      6. [ ] Implement backend processing for the new method
      7. [ ] Add UI components for the new payment method
      8. [ ] Write tests for all new functionality
      9. [ ] Update documentation

      **Acceptance Criteria:**
      - Users can select and use the new payment method at checkout
      - Payment processing works correctly with appropriate error handling
      - Payment records are properly stored in the database
      - The UI clearly presents the new payment option
      - All tests pass

      Let's start by examining the current payment system code to understand the architecture...

      [Agent would then proceed through the implementation phases, checking off items as they're completed]

metadata:
  priority: high
  version: 1.0
</rule>
