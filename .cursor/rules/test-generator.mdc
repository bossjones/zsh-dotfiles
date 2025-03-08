---
description: Identify missing tests and generate appropriate test cases for the codebase
globs: *
alwaysApply: false
---

# Test Generator

This rule helps identify missing tests and generate appropriate test cases for the codebase.

<rule>
name: test-generator
description: Identify missing tests and generate appropriate test cases for the codebase
filters:
  - type: message
    pattern: "(?i)(missing tests|test coverage|generate tests|test suite|no tests|write tests|add tests)"
  - type: context
    pattern: "test|coverage|pytest|unittest|spec|verification"

actions:
  - type: instructions
    message: |
      # Test Generation for Existing Codebase

      When the user needs to identify and generate missing tests:

      1. **Analyze Test Coverage**:
         - Identify code components without adequate test coverage
         - Prioritize core functionality and business logic
         - Consider edge cases and error handling paths

      2. **Determine Test Types**:
         - Unit tests for individual functions and methods
         - Integration tests for component interactions
         - End-to-end tests for critical user workflows
         - Property-based tests for invariant verification when appropriate

      3. **Follow Project Testing Patterns**:
         - Match existing test structure and naming conventions
         - Use the same testing framework and assertion style
         - Maintain consistency with the current test suite

      4. **Generate Test Cases**:
         - Create comprehensive test cases for each component
         - Include happy path, edge cases, and error conditions
         - Write clear test descriptions that document behavior

      5. **Implement Tests Incrementally**:
         - Start with simple cases and expand coverage
         - Group related tests appropriately
         - Add proper typing and documentation to test files

      Remember to:
      - Create `__init__.py` files in test directories if needed
      - Use pytest fixtures for common setup/teardown
      - Add proper typing annotations to all test functions
      - Include docstrings explaining test purpose and behavior
      - Import appropriate testing tools (monkeypatch, fixtures, etc.)

examples:
  - input: |
      We need to add tests for our user service module.
    output: |
      I'll help you generate tests for the user service module. Let me analyze the code to understand what tests we need to create.

      Based on my analysis of the user service module, here are the tests we should implement:

      ```python
      # tests/services/test_user_service.py
      from typing import TYPE_CHECKING, Dict, Any, List
      import pytest
      from datetime import datetime, timedelta

      from app.services.user_service import UserService
      from app.models.user import User
      from app.exceptions import UserNotFoundError, ValidationError

      if TYPE_CHECKING:
          from _pytest.fixtures import FixtureRequest
          from _pytest.monkeypatch import MonkeyPatch
          from pytest_mock.plugin import MockerFixture

      @pytest.fixture
      def user_service(db_session) -> UserService:
          """
          Create a UserService instance with a test database session.

          Args:
              db_session: The test database session fixture

          Returns:
              UserService: An initialized user service for testing
          """
          return UserService(db_session=db_session)

      @pytest.fixture
      def sample_user_data() -> Dict[str, Any]:
          """
          Provide sample user data for testing.

          Returns:
              Dict[str, Any]: A dictionary containing sample user data
          """
          return {
              "email": "test@example.com",
              "name": "Test User",
              "password": "securepassword123"
          }

      class TestUserCreation:
          """Tests for user creation functionality."""

          def test_create_user_success(
              self,
              user_service: UserService,
              sample_user_data: Dict[str, Any]
          ) -> None:
              """
              Test successful user creation with valid data.

              Args:
                  user_service: The user service fixture
                  sample_user_data: Sample user data fixture
              """
              user = user_service.create_user(**sample_user_data)

              assert user is not None
              assert user.email == sample_user_data["email"]
              assert user.name == sample_user_data["name"]
              # Password should be hashed, not stored as plaintext
              assert user.password != sample_user_data["password"]

          def test_create_user_duplicate_email(
              self,
              user_service: UserService,
              sample_user_data: Dict[str, Any]
          ) -> None:
              """
              Test user creation fails with duplicate email.

              Args:
                  user_service: The user service fixture
                  sample_user_data: Sample user data fixture
              """
              # Create user first time
              user_service.create_user(**sample_user_data)

              # Attempt to create user with same email
              with pytest.raises(ValidationError) as excinfo:
                  user_service.create_user(**sample_user_data)

              assert "email already exists" in str(excinfo.value).lower()

      class TestUserRetrieval:
          """Tests for user retrieval functionality."""

          def test_get_user_by_id_success(
              self,
              user_service: UserService,
              sample_user_data: Dict[str, Any]
          ) -> None:
              """
              Test successful user retrieval by ID.

              Args:
                  user_service: The user service fixture
                  sample_user_data: Sample user data fixture
              """
              created_user = user_service.create_user(**sample_user_data)

              retrieved_user = user_service.get_user_by_id(created_user.id)

              assert retrieved_user is not None
              assert retrieved_user.id == created_user.id
              assert retrieved_user.email == sample_user_data["email"]

          def test_get_user_by_id_not_found(
              self,
              user_service: UserService
          ) -> None:
              """
              Test user retrieval with non-existent ID.

              Args:
                  user_service: The user service fixture
              """
              with pytest.raises(UserNotFoundError):
                  user_service.get_user_by_id(999)

      # Add more test classes for other functionality
      # - TestUserUpdate for testing update operations
      # - TestUserDeletion for testing deletion operations
      # - TestUserAuthentication for testing authentication methods
      ```

      These tests cover the basic CRUD operations for the user service. They follow the project's testing patterns and include appropriate fixtures, typing, and docstrings.

      Would you like me to implement any of the additional test classes mentioned at the end of the file?

metadata:
  priority: high
  version: 1.0
</rule>
