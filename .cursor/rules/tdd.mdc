---
description: Implement Test-Driven Development (TDD) for AI-generated code to ensure quality, reliability, and correctness
globs: **/*.py, **/*.js, **/*.ts, **/*.java, **/*.c, **/*.cpp
alwaysApply: false
---
# Test-Driven Development for AI Code

Use TDD principles when working with AI coding assistants to ensure generated code is not just fast, but also correct, reliable, and maintainable.

<rule>
name: test-driven-development-for-ai
description: Implement Test-Driven Development practices when using AI to generate code to ensure proper validation, edge case handling, and maintainability
filters:
  # Match code files in various languages
  - type: file_name
    pattern: "\\.(py|js|ts|java|c|cpp)$"
  # Match when using AI assistants for code generation
  - type: event
    pattern: "ai_code_generation"

actions:
  - type: suggest
    message: |
      When using AI to generate code, follow Test-Driven Development (TDD) principles:

      1. First Action - Write Tests Before Code:
         ```
         # Define test cases before requesting code from AI
         # Include both base cases and edge cases
         # Example for a factorial function:
         test_factorial_zero()  # Base case: 0! = 1
         test_factorial_one()   # Base case: 1! = 1
         test_factorial_small() # Normal case: 5! = 120
         test_factorial_large() # Large input: tests scalability
         test_factorial_negative() # Edge case: handling negative numbers
         ```

      2. Red-Green-Refactor Cycle:
         - **Red**: Write failing tests first
         - **Green**: Get AI to generate code that passes tests
         - **Refactor**: Improve AI code without changing functionality

      3. Guidelines:
         - Specify explicit requirements before generating code
         - Test edge cases (e.g., empty inputs, large values, negative numbers)
         - Verify error handling and input validation
         - Test performance limits
         - Maintain code-to-test balance for maintainability
         - Cross-check AI solutions with expected behavior

         Stack Overflow Prevention:
         - Test recursive functions with large inputs
         - Include validation for recursive base cases
         - Test for potential infinite loops
         - Add proper exception handling

         Security Considerations:
         - Test for SQL injection vulnerabilities
         - Verify sanitization of user inputs
         - Test permissions and access controls
         - Validate data handling

         Refactoring Guidelines:
         - Ensure tests remain green after refactoring
         - Apply language-specific best practices
         - Optimize performance while maintaining readability
         - Document code behavior and edge cases

      4. Implementation Process:
         a. Define Requirements with Tests:
            - Start by writing comprehensive tests
            - Document expected behavior
            - Include normal use cases and edge cases
            - Example:
              ```python
              def test_factorial_negative():
                  # Test that factorial raises ValueError for negative inputs
                  with pytest.raises(ValueError):
                      factorial(-1)
              ```

         b. Generate Initial AI Solution:
            - Provide test cases to AI assistant
            - Request implementation that should pass tests
            - Review initial solution critically
            - Run tests to identify failures

         c. Iterative Improvement:
            - Address failing tests one by one
            - Ask AI to fix specific issues
            - Guide AI with more context when needed
            - Example fix request:
              "The factorial function fails for large inputs due to recursion depth.
               Please modify it to use an iterative approach instead."

         d. Refactor for Quality:
            - Once all tests pass, optimize the solution
            - Request code simplification where appropriate
            - Add proper documentation
            - Ensure maintainability

         e. Verify Final Solution:
            - Run all tests to confirm they still pass
            - Review code for potential issues
            - Consider adding performance tests
            - Document any limitations

examples:
  - input: |
      # Bad: Generating code without tests
      def factorial(n):
          if n == 0 or n == 1:
              return 1
          return n * factorial(n-1)
    output: "Recursive factorial without tests for edge cases"

  - input: |
      # Good: TDD approach for factorial function

      # Step 1: Define tests first
      import pytest

      def test_factorial_zero():
          assert factorial(0) == 1

      def test_factorial_one():
          assert factorial(1) == 1

      def test_factorial_small():
          assert factorial(5) == 120

      def test_factorial_large():
          # Test with a large number to ensure it computes without stack overflow
          assert factorial(100) > 0  # Just verify it computes a positive value

      def test_factorial_negative():
          with pytest.raises(ValueError):
              factorial(-1)

      # Step 2: Generate initial code (it will fail some tests)
      def factorial(n):
          if n == 0 or n == 1:
              return 1
          return n * factorial(n-1)

      # Step 3: Refactor to fix failing tests
      def factorial(n):
          if not isinstance(n, int):
              raise TypeError("Input must be an integer")
          if n < 0:
              raise ValueError("Factorial not defined for negative numbers")
          if n == 0:
              return 1

          result = 1
          for i in range(2, n + 1):
              result *= i
          return result
    output: "Complete TDD approach with tests and iterative improvement"

  - input: |
      # Example of Test-Driven Generation (TDG) with AI

      # Step 1: Write the test first
      def test_is_even():
          assert is_even(2) == True
          assert is_even(3) == False
          assert is_even(0) == True
          assert is_even(-4) == True
          assert is_even(-7) == False

      # Step 2: Ask AI to implement the function to pass tests
      def is_even(n):
          return n % 2 == 0

      # Tests now pass, providing confidence in the solution
    output: "Test-Driven Generation with AI"

metadata:
  priority: high
  version: 1.0
  tags:
    - testing
    - code-quality
    - ai-best-practices
    - tdd
    - test-driven-development
    - edge-cases
    - error-handling
    - scalability
</rule>
