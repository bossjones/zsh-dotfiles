---
description: Guidance for debugging and fixing issues that arise during iterative development
globs: *
alwaysApply: false
---

# Iterative Debug and Fix

This rule provides guidance for debugging and fixing issues that arise during iterative development.

<rule>
name: iterative-debug-fix
description: Guidance for debugging and fixing issues that arise during iterative development
filters:
  - type: message
    pattern: "(?i)(debug|fix|error|not working|issue|problem|failed|doesn't work)"
  - type: context
    pattern: "error|exception|failure|bug|test failing|unexpected behavior"

actions:
  - type: instructions
    message: |
      # Debugging and Fixing Issues in Iterative Development

      When the user encounters issues or bugs during incremental development:

      ## Phase 1: Understand the Issue

      1. **Gather Error Information**:
         - Collect all error messages and stack traces
         - Identify where in the code the issue occurs
         - Understand the expected vs. actual behavior

      2. **Reproduce the Issue**:
         - Create a reliable reproduction scenario
         - Identify the minimal steps to trigger the issue
         - Isolate variables that affect the issue

      3. **Analyze the Context**:
         - Review the relevant code and its dependencies
         - Check recent changes that might have introduced the issue
         - Look for similar patterns in working parts of the codebase

      ## Phase 2: Diagnose the Root Cause

      1. **Systematic Investigation**:
         - Use debuggers, logging, or print statements to trace execution
         - Check variable values at key points
         - Validate assumptions about data flow and state

      2. **Test Hypotheses**:
         - Form theories about potential causes
         - Make targeted changes to test each hypothesis
         - Use test cases to verify understanding

      3. **Narrow Down the Problem**:
         - Eliminate possible causes through process of elimination
         - Focus on the specific component where the issue manifests
         - Identify interactions between components that might cause issues

      ## Phase 3: Implement and Verify Fix

      1. **Design the Fix**:
         - Plan minimal changes needed to address the root cause
         - Consider potential side effects of the proposed fix
         - Maintain consistency with the existing codebase

      2. **Implement Changes**:
         - Make focused, targeted changes to address the issue
         - Add comments explaining the fix and why it works
         - Avoid introducing new complexity

      3. **Verify the Solution**:
         - Test that the issue is resolved
         - Run regression tests to ensure no new issues were introduced
         - Verify edge cases and related functionality

      ## Phase 4: Learn and Prevent

      1. **Document the Issue and Solution**:
         - Keep notes on the problem and how it was resolved
         - Update documentation if needed

      2. **Add Tests**:
         - Add test cases that would have caught this issue
         - Ensure similar issues would be detected in the future

      3. **Reflect on Prevention**:
         - Consider what could have prevented this issue
         - Identify patterns to watch for in future development

examples:
  - input: |
      The user authentication we just implemented isn't working. Users can log in with any password.
    output: |
      I'll help you debug and fix this authentication issue. Let's follow a systematic approach to identify and resolve the problem.

      ## Phase 1: Understanding the Issue

      First, let's confirm we understand the exact problem:
      - Users can log in with any password, indicating the password verification is failing
      - Authentication should only succeed with the correct password
      - This suggests either the password check is being bypassed or it's not comparing correctly

      Let's gather context by examining the relevant authentication code:

      ```python
      # Example of what we might find in the login function
      def login(email, password):
          user = User.query.filter_by(email=email).first()
          if user:  # Problem: Missing password verification here!
              session['user_id'] = user.id
              return True
          return False
      ```

      I can see the issue - the function is checking if the user exists, but not verifying the password.

      ## Phase 2: Diagnosing the Root Cause

      The root cause appears to be either:
      1. Missing password verification code, or
      2. Incorrect password comparison logic

      Let's check how passwords are stored and how they should be verified:

      ```python
      # User model shows passwords are hashed
      class User(db.Model):
          # ... other fields
          password = db.Column(db.String(200), nullable=False)

          def __init__(self, email, password, name=None):
              self.email = email
              self.password = generate_password_hash(password)
              self.name = name
      ```

      Now we know passwords are hashed during user creation, so we should be using `check_password_hash` when verifying.

      ## Phase 3: Implementing and Verifying the Fix

      Let's implement the fix:

      ```python
      def login(email, password):
          user = User.query.filter_by(email=email).first()
          if user and check_password_hash(user.password, password):
              session['user_id'] = user.id
              return True
          return False
      ```

      The key change is adding the password verification with `check_password_hash(user.password, password)`.

      Let's also add tests to verify this works correctly:

      ```python
      def test_login_with_correct_password():
          # Setup user with known password
          user = create_test_user(password="correct_password")

          # Test login succeeds with correct password
          assert login(user.email, "correct_password") is True

      def test_login_with_incorrect_password():
          # Setup user with known password
          user = create_test_user(password="correct_password")

          # Test login fails with incorrect password
          assert login(user.email, "wrong_password") is False
      ```

      ## Phase 4: Learning and Prevention

      To prevent similar issues in the future:

      1. Add a comment to the login function explaining the importance of password verification
      2. Consider implementing authentication middleware that enforces security best practices
      3. Add additional test cases for authentication edge cases
      4. Review other security-critical code for similar issues

      This fix ensures that only users with the correct password can authenticate, resolving the security vulnerability.

metadata:
  priority: high
  version: 1.0
</rule>
