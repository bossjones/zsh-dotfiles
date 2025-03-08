---
description: Greenfield Execution Best Practices
globs: *.py, *.js, *.ts, *.jsx, *.tsx, *.rs, *.go, *.cpp, *.java
alwaysApply: false
---
# Greenfield Execution Best Practices

Best practices for implementing code during the execution phase of Greenfield development.

<rule>
name: greenfield-execution-best-practices
description: Standards for implementing code with LLM assistance during the execution phase of Greenfield projects
filters:
  # Match code files
  - type: file_extension
    pattern: "\\.(py|js|ts|jsx|tsx|rs|go|cpp|java)$"
  # Match file creation and edit events
  - type: event
    pattern: "(file_create|file_edit)"

actions:
  - type: suggest
    message: |
      # Greenfield Execution Best Practices

      When implementing code during the execution phase of your Greenfield project:

      ## Initial Project Setup

      - Set up the project boilerplate before involving the LLM
      - Define coding standards and patterns upfront
      - Initialize version control (Git) with a clear branching strategy
      - Configure necessary development tools (linters, formatters, testing frameworks)
      - Set up CI/CD if applicable for the project

      ## Working with LLM-Generated Code

      - Review all generated code before committing - don't blindly accept
      - Break down implementation into small, manageable chunks
      - Test each chunk thoroughly before moving to the next
      - Keep track of your progress using todo.md
      - Document decisions and deviations from the original plan
      - Identify and correct hallucinated APIs or functions

      ## Testing Strategy

      - Write tests before or alongside implementation (TDD preferred)
      - Include unit tests for individual components
      - Add integration tests for component interactions
      - Consider end-to-end tests for critical user flows
      - Test edge cases and error handling thoroughly
      - Write tests even for LLM-generated code

      ## Code Quality and Maintenance

      - Ensure consistent code style across LLM-generated code
      - Add proper documentation and comments
      - Focus on making code readable and maintainable
      - Refactor early when patterns emerge or better solutions become clear
      - Keep dependencies updated and minimize their number
      - Review security implications of LLM-generated code

      ## Debugging and Problem-Solving

      - Use the LLM to help debug issues by providing error details
      - Take breaks when feeling "over your skis" with implementation complexity
      - Reference your spec.md and prompt_plan.md regularly to stay focused
      - Document workarounds and technical debt for future cleanup
      - Maintain a list of known issues or limitations

      ## Iteration Cycle

      1. Review the next task from your plan
      2. Craft a precise prompt for implementation
      3. Generate code with the LLM
      4. Review and modify the generated code
      5. Integrate the code into your project
      6. Test thoroughly
      7. Debug and fix issues
      8. Commit working code
      9. Update documentation and todo.md
      10. Proceed to the next task

examples:
  - input: |
      # Bad: Vague implementation prompt
      Build a user authentication system.

      # Good: Specific, context-rich implementation prompt
      Implement a user authentication system with the following requirements:
      1. Email/password registration and login
      2. JWT token-based authentication with 24-hour expiry
      3. Password reset functionality via email
      4. Input validation and secure password storage (bcrypt)
      5. Rate limiting for login attempts

      Here's the current project structure:
      - src/
        - models/
        - controllers/
        - routes/
        - services/
        - utils/

      Please implement the necessary components following RESTful API patterns.
    output: "Clear, detailed implementation prompt"

  - input: |
      # Bad: Implementing a large feature at once
      Create a complete e-commerce checkout flow with cart, payment processing, and order management.

      # Good: Breaking implementation into manageable steps
      Step 1: Create a shopping cart component that displays items, quantities, and totals.
      Step 2: Implement cart state management (add, remove, update quantity).
      Step 3: Build checkout form with shipping and billing information.
      Step 4: Add form validation and error handling.
      Step 5: Implement order creation service.
      Step 6: Connect payment processing integration.
    output: "Incremental implementation approach"

metadata:
  priority: high
  version: 1.0
  tags:
    - development
    - implementation
    - greenfield
    - best-practices
</rule>
