---
description: Comprehensive Python development rules and standards for the Codegen Lab project
globs: **/*.py
alwaysApply: false
---
# Python Development Standards

Comprehensive rules and best practices for Python development in the Codegen Lab project, covering code organization, typing, documentation, testing, performance, and security.

<rule>
name: python_development_standards
description: Standards for Python code development including typing, docstrings, and testing
filters:
  # Match Python files
  - type: file_extension
    pattern: "\\.py$"
  # Match Python code
  - type: content
    pattern: "def |class "

actions:
  - type: suggest
    message: |
      # Python Development Standards

      This project follows strict Python development standards:

      ## Type Annotations

      All Python code must include comprehensive type hints:

      ```python
      def process_data(input_data: list[str], max_items: int = 10) -> dict[str, Any]:
          """Process the input data and return results."""
          # Implementation
      ```

      ## Docstrings

      Follow PEP 257 for docstrings:

      ```python
      def calculate_total(items: list[Item]) -> float:
          """Calculate the total value of all items.

          Args:
              items: List of Item objects to process

          Returns:
              The total calculated value

          Raises:
              ValueError: If any item has a negative value
          """
          # Implementation
      ```

      ## Testing

      All code must have corresponding pytest tests:

      ```python
      def test_calculate_total() -> None:
          """Test that calculate_total correctly sums item values."""
          items = [Item(value=10.0), Item(value=20.0)]
          result = calculate_total(items)
          assert result == 30.0
      ```

      ## Code Organization

      - Follow PEP 8 style guidelines
      - Use consistent import ordering (standard library, third-party, local)
      - Organize code into logical modules
      - Keep functions and methods focused on a single responsibility

      ## Package Structure

      For workspace packages, follow the src layout:

      ```
      package-name/
      ├── pyproject.toml
      ├── src/
      │   └── package_name/
      │       ├── __init__.py
      │       └── module.py
      └── tests/
          └── test_module.py
      ```

      ## Integration with UV Workspace

      This project uses UV workspace for package management.

      @uv-workspace.mdc

examples:
  - input: |
      # Bad: No type hints or proper docstrings
      def process_data(data, limit=100):
          # Process the data
          return {"result": processed}

      # Good: Complete type hints and docstrings
      def process_data(data: list[dict[str, Any]], limit: int = 100) -> dict[str, Any]:
          """Process the input data and return results.

          Args:
              data: List of data dictionaries to process
              limit: Maximum number of items to process

          Returns:
              Dictionary containing processed results

          Raises:
              ValueError: If data is empty or contains invalid entries
          """
          # Process the data
          return {"result": processed}
    output: "Properly formatted Python function with type hints and docstrings"

  - input: |
      # Bad: Test without type hints or docstrings
      def test_process_data():
          data = [{"key": "value"}]
          result = process_data(data)
          assert "result" in result

      # Good: Test with type hints and docstrings
      def test_process_data() -> None:
          """Test that process_data correctly handles valid input data."""
          data = [{"key": "value"}]
          result = process_data(data)
          assert "result" in result
          assert isinstance(result["result"], list)
    output: "Properly formatted test function with type hints and docstrings"

metadata:
  priority: high
  version: 1.0
  tags:
    - python
    - type-hints
    - docstrings
    - testing
</rule>

<rule>
name: python_imports_organization
description: Standards for organizing imports in Python files
filters:
  # Match Python files
  - type: file_extension
    pattern: "\\.py$"
  # Match import statements
  - type: content
    pattern: "import |from "

actions:
  - type: suggest
    message: |
      # Python Import Organization

      Organize imports in this order:

      1. **Future imports** (if any)
         ```python
         from __future__ import annotations
         ```

      2. **Standard library imports**
         ```python
         import os
         import sys
         from typing import Any, Dict, List, Optional, Union
         ```

      3. **Third-party library imports**
         ```python
         import numpy as np
         import pandas as pd
         from pydantic import BaseModel
         ```

      4. **Local application imports**
         ```python
         from myapp.models import User
         from myapp.utils import format_data
         ```

      5. **Type checking imports** (if needed)
         ```python
         from typing import TYPE_CHECKING

         if TYPE_CHECKING:
             from _pytest.capture import CaptureFixture
             from _pytest.fixtures import FixtureRequest
             from _pytest.logging import LogCaptureFixture
             from _pytest.monkeypatch import MonkeyPatch
             from pytest_mock.plugin import MockerFixture
         ```

      Each group should be separated by a blank line.

      ## Import Style

      **Always use absolute imports, not relative imports.**

      ```python
      # Good: Absolute imports
      from myapp.utils import helper
      from myapp.models import User

      # Bad: Relative imports
      from ..utils import helper
      from .models import User
      ```

      Absolute imports make code more maintainable, explicit, and easier to understand, especially when refactoring or moving files.

      ## Example:

      ```python
      from __future__ import annotations

      import os
      import sys
      from typing import Any, Dict, List, Optional, Union

      import numpy as np
      import pandas as pd
      from pydantic import BaseModel

      from myapp.models import User
      from myapp.utils import format_data

      from typing import TYPE_CHECKING

      if TYPE_CHECKING:
          from _pytest.capture import CaptureFixture
          from _pytest.fixtures import FixtureRequest
          from _pytest.logging import LogCaptureFixture
          from _pytest.monkeypatch import MonkeyPatch
          from pytest_mock.plugin import MockerFixture
      ```

examples:
  - input: |
      # Bad: Mixed import order
      import pandas as pd
      import os
      from myapp.utils import helper
      import sys
      from typing import List, Dict

      # Good: Organized imports
      from __future__ import annotations

      import os
      import sys
      from typing import Dict, List

      import pandas as pd

      from myapp.utils import helper

      from typing import TYPE_CHECKING

      if TYPE_CHECKING:
          from _pytest.capture import CaptureFixture
          from pytest_mock.plugin import MockerFixture
    output: "Properly organized imports following the standard convention"

metadata:
  priority: medium
  version: 1.0
  tags:
    - python
    - imports
    - organization
</rule>

<rule>
name: python_security_practices
description: Security best practices for Python development
filters:
  - type: file_extension
    pattern: "\\.py$"
  - type: content
    pattern: "import |def |class "

actions:
  - type: suggest
    message: |
      # Python Security Best Practices

      ## Common Vulnerabilities and Prevention

      * **SQL Injection:** Use parameterized queries or ORMs to prevent SQL injection attacks
      * **Command Injection:** Avoid executing arbitrary commands based on user input
      * **Path Traversal:** Validate file paths to prevent path traversal attacks
      * **Pickle Deserialization:** Avoid using `pickle` to deserialize untrusted data
      * **Hardcoded Secrets:** Never hardcode secrets (passwords, API keys) in code

      ## Input Validation Best Practices

      * **Whitelisting:** Validate input against a whitelist of allowed values
      * **Data Type Validation:** Ensure input data types are correct
      * **Sanitization:** Remove or escape potentially harmful characters from input
      * **Use validation libraries:** `pydantic`


examples:
  - input: |
      # Bad: Vulnerable to SQL injection
      def get_user(username):
          query = f"SELECT * FROM users WHERE username = '{username}'"
          return db.execute(query)

      # Good: Using parameterized query
      def get_user(username):
          query = "SELECT * FROM users WHERE username = ?"
          return db.execute(query, (username,))
    output: "Secure code using parameterized queries to prevent SQL injection"

  - input: |
      # Bad: Hardcoded secrets
      API_KEY = "1234567890abcdef"

      # Good: Load from environment or secure configuration
      import os
      from decouple import config

      API_KEY = os.environ.get("API_KEY") or config("API_KEY")
    output: "Secure handling of sensitive configuration data"

metadata:
  priority: high
  version: 1.0
  tags:
    - python
    - security
    - vulnerabilities
    - authentication
</rule>

<rule>
name: python_performance_optimization
description: Performance optimization techniques for Python code
filters:
  - type: file_extension
    pattern: "\\.py$"

actions:
  - type: suggest
    message: |
      # Python Performance Optimization

      ## Key Performance Techniques

      * **Data Structures:** Choose appropriate data structures (e.g., `set` for membership testing)
      * **Comprehensions:** Use list/dict comprehensions and generator expressions for efficiency
      * **Vectorization:** Use NumPy for numerical computations when possible
      * **Caching:** Use `functools.lru_cache` for expensive function calls
      * **String Operations:** Use `"".join(iterable)` for efficient string concatenation
      * **JIT Compilation:** Consider Numba for performance-critical numerical code

      ## Memory Management

      * **Generators:** Use generators for processing large datasets without loading into memory
      * **`__slots__`:** Use `__slots__` to reduce memory footprint of classes with many instances
      * **Memory Profiling:** Use tools like `memory_profiler` to identify memory leaks
      * **Circular References:** Be mindful of circular references that can prevent garbage collection

      ## Lazy Loading

      * Use `importlib.import_module()` to load modules on demand
      * Load large datasets only when needed
      * Consider using lazy properties with the `@property` decorator

examples:
  - input: |
      # Bad: Inefficient string concatenation
      def build_report(items):
          report = ""
          for item in items:
              report += f"{item.name}: {item.value}\n"
          return report

      # Good: Efficient string concatenation
      def build_report(items):
          return "".join(f"{item.name}: {item.value}\n" for item in items)
    output: "Efficient string concatenation using join method"

  - input: |
      # Bad: Repetitive expensive calculations
      def fibonacci(n):
          if n <= 1:
              return n
          return fibonacci(n-1) + fibonacci(n-2)

      # Good: Cached expensive calculations
      from functools import lru_cache

      @lru_cache(maxsize=None)
      def fibonacci(n):
          if n <= 1:
              return n
          return fibonacci(n-1) + fibonacci(n-2)
    output: "Optimized recursive function using lru_cache"

metadata:
  priority: medium
  version: 1.0
  tags:
    - python
    - performance
    - optimization
    - memory-management
</rule>

<rule>
name: python_code_organization
description: Best practices for organizing Python code and project structure
filters:
  - type: file_extension
    pattern: "\\.py$"

actions:
  - type: suggest
    message: |
      # Python Code and Project Organization

      ## Directory Structure

      * Follow the src layout for Python packages:
        ```
        project_name/
        ├── src/
        │   ├── package_name/
        │   │   ├── __init__.py
        │   │   ├── module1.py
        │   ├── main.py  # Entry point
        ├── tests/
        │   ├── test_module1.py
        ├── docs/
        ├── pyproject.toml
        ├── README.md
        ```

      * Keep tests in a separate `tests` directory that mirrors the source structure
      * Group related functionality into packages and modules

      ## File Naming Conventions

      * Modules: Lowercase with underscores (e.g., `my_module.py`)
      * Packages: Lowercase (e.g., `my_package`)
      * Tests: Prefix with `test_` (e.g., `test_my_module.py`)

      ## Component Architecture

      * Follow Single Responsibility Principle for modules and classes
      * Consider layered architecture for larger applications
      * Use dependency injection to improve testability

      ## Module Organization

      * Each module should have a clear purpose
      * Define module-level constants in uppercase
      * Use `__all__` to define the public API
      * Follow the import order: standard library, third-party, local

examples:
  - input: |
      # Bad: Poorly organized module with mixed responsibilities
      # users.py
      import random

      def get_user(user_id):
          # Implementation

      def calculate_statistics(data):
          # Implementation that doesn't belong in a users module

      def send_email(user, message):
          # Implementation that doesn't belong in a users module

      # Good: Focused module with clear responsibility
      # users.py
      import random
      from typing import Dict, Any, Optional

      __all__ = ['get_user', 'create_user', 'update_user', 'delete_user']

      def get_user(user_id: int) -> Optional[Dict[str, Any]]:
          # Implementation

      def create_user(user_data: Dict[str, Any]) -> int:
          # Implementation

      def update_user(user_id: int, user_data: Dict[str, Any]) -> bool:
          # Implementation

      def delete_user(user_id: int) -> bool:
          # Implementation
    output: "Well-organized module with clear responsibility and defined public API"

metadata:
  priority: high
  version: 1.0
  tags:
    - python
    - organization
    - architecture
    - project-structure
</rule>

<rule>
name: python_error_handling
description: Best practices for error handling in Python
filters:
  - type: file_extension
    pattern: "\\.py$"
  - type: content
    pattern: "try|except|raise|finally"

actions:
  - type: suggest
    message: |
      # Python Error Handling Best Practices

      ## General Guidelines

      * Catch specific exceptions rather than broad `Exception` or `BaseException`
      * Use `finally` to ensure cleanup code is always executed
      * Use context managers (`with` statement) for resource management
      * Log exceptions with complete traceback information
      * Raise exceptions with informative error messages
      * Create custom exception classes for specific error conditions
      * Avoid using exceptions for control flow

      ## Exception Handling Patterns

      ```python
      # Specific exception handling
      try:
          value = int(user_input)
      except ValueError as e:
          # Handle specific error
          log.error(f"Invalid input: {e}")
          raise ValidationError(f"Please enter a valid number") from e

      # Resource management with context managers
      with open(file_path, 'r') as file:
          data = file.read()

      # Custom exceptions
      class ValidationError(Exception):
          """Raised when input validation fails."""
          pass
      ```

      ## Error Propagation

      * Re-raise exceptions with `raise` to propagate them up the call stack
      * Use `raise ... from e` to preserve the exception chain
      * Consider using error codes or status objects for expected error states

examples:
  - input: |
      # Bad: Catching too broad an exception
      try:
          process_data(data)
      except Exception:
          # Swallowing all exceptions is dangerous
          pass

      # Good: Catching specific exceptions
      try:
          process_data(data)
      except ValueError as e:
          # Handle specific error
          log.error(f"Invalid data format: {e}")
          return {"error": "Invalid data format"}
      except IOError as e:
          # Handle another specific error
          log.error(f"I/O error: {e}")
          return {"error": "Error accessing data source"}
    output: "Proper exception handling with specific exception types"

metadata:
  priority: medium
  version: 1.0
  tags:
    - python
    - error-handling
    - exceptions
</rule>

<rule>
name: python_testing_practices
description: Comprehensive testing practices for Python code
filters:
  - type: file_extension
    pattern: "\\.py$"
  - type: content
    pattern: "test_|pytest|unittest"

actions:
  - type: suggest
    message: |
      # Python Testing Best Practices

      ## Testing Framework

      * Use pytest EXCLUSIVELY for all testing
      * NEVER use the unittest module or unittest.mock - this is STRICTLY PROHIBITED
      * Always include proper type annotations in test functions
      * Write descriptive docstrings for all test functions

      ## Unit Testing

      * Test individual functions, classes, or modules in isolation
      * Follow Test-Driven Development (TDD) when possible
      * Use appropriate assertion methods for clarity

      ## Integration Testing

      * Test interactions between different modules or components
      * Test database interactions and API endpoints
      * Mock external services during integration tests
      * Focus on key workflows

      ## Test Organization

      * Keep tests in a separate `tests` directory that mirrors the source structure:
        ```
        tests/
        ├── unittests/      # Unit tests
        │   └── module_dir/
        │       └── test_module.py
        ├── integration/    # Integration tests
        │   └── test_integration.py
        └── e2e/            # End-to-end tests
            └── test_workflow.py
        ```
      * Create `__init__.py` files in all test directories
      * Use descriptive test names that indicate what is being tested

      ## Mocking and Fixtures

      * Use `pytest-mock` for mocking dependencies
      * NEVER use unittest.mock directly
      * Use pytest fixtures for setup and teardown
      * Make tests independent and stateless
      * Use dependency injection to improve testability

      ## Type Checking in Tests

      * Always include TYPE_CHECKING imports in test files:

      ```python
      from typing import TYPE_CHECKING

      if TYPE_CHECKING:
          from _pytest.capture import CaptureFixture
          from _pytest.fixtures import FixtureRequest
          from _pytest.logging import LogCaptureFixture
          from _pytest.monkeypatch import MonkeyPatch
          from pytest_mock.plugin import MockerFixture
      ```

      ## Example:

      ```python
      import pytest
      from typing import Dict, Any, TYPE_CHECKING

      if TYPE_CHECKING:
          from _pytest.capture import CaptureFixture
          from _pytest.fixtures import FixtureRequest
          from _pytest.logging import LogCaptureFixture
          from _pytest.monkeypatch import MonkeyPatch
          from pytest_mock.plugin import MockerFixture

      from myapp.users import get_user_by_id

      @pytest.fixture
      def mock_database(mocker: "MockerFixture") -> Any:
          """Fixture providing a mock database connection.

          Args:
              mocker: Pytest fixture for mocking dependencies.

          Returns:
              Mock database connection object.
          """
          mock_db = mocker.MagicMock()
          mock_db.query.return_value = {"id": 1, "name": "Test User"}
          return mock_db

      def test_get_user_by_id(mock_database: Any, mocker: "MockerFixture") -> None:
          """Test that get_user_by_id correctly retrieves a user.

          Args:
              mock_database: Fixture providing a mock database.
              mocker: Pytest fixture for mocking dependencies.
          """
          # Arrange
          user_id = 1

          # Act
          mocker.patch('myapp.users.get_db_connection', return_value=mock_database)
          result = get_user_by_id(user_id)

          # Assert
          assert result["id"] == user_id
          assert result["name"] == "Test User"
          mock_database.query.assert_called_once()
      ```

examples:
  - input: |
      # Bad: Using unittest module
      import unittest

      class TestUser(unittest.TestCase):
          def test_user_creation(self):
              user = create_user("test@example.com", "password123")
              self.assertIsNotNone(user.id)

      # Bad: Using unittest.mock
      from unittest.mock import MagicMock

      def test_with_unittest_mock():
          mock_db = MagicMock()
          # Test implementation

      # Good: Using pytest with proper typing and documentation
      import pytest
      from typing import TYPE_CHECKING

      if TYPE_CHECKING:
          from pytest_mock.plugin import MockerFixture

      def test_user_creation(mocker: "MockerFixture") -> None:
          """Test that user creation works correctly with valid credentials.

          Args:
              mocker: Pytest fixture for mocking dependencies.
          """
          # Arrange
          email = "test@example.com"
          password = "password123"

          # Act
          user = create_user(email, password)

          # Assert
          assert user.id is not None
          assert user.email == email
          assert user.is_active is True
          assert user.verify_password(password) is True
    output: "Properly structured pytest test avoiding unittest module"

  - input: |
      # Bad: Missing type annotations and proper setup
      def test_api_request():
          response = make_api_request("endpoint")
          assert response.status_code == 200

      # Good: Complete test with fixture, typing, and documentation
      import pytest
      from typing import TYPE_CHECKING, Dict, Any

      if TYPE_CHECKING:
          from _pytest.fixtures import FixtureRequest
          from pytest_mock.plugin import MockerFixture

      @pytest.fixture
      def mock_api_client(mocker: "MockerFixture") -> Any:
          """Create a mock API client for testing.

          Args:
              mocker: Pytest fixture for mocking.

          Returns:
              Mock API client configured for testing.
          """
          mock_client = mocker.MagicMock()
          mock_response = mocker.MagicMock()
          mock_response.status_code = 200
          mock_response.json.return_value = {"success": True}
          mock_client.request.return_value = mock_response
          return mock_client

      def test_api_request(mock_api_client: Any, mocker: "MockerFixture") -> None:
          """Test that API requests are properly formed and processed.

          Args:
              mock_api_client: Mock API client fixture.
              mocker: Pytest fixture for mocking.
          """
          # Arrange
          endpoint = "test_endpoint"
          mocker.patch("myapp.api.get_client", return_value=mock_api_client)

          # Act
          response = make_api_request(endpoint)

          # Assert
          assert response.status_code == 200
          assert response.json()["success"] is True
          mock_api_client.request.assert_called_once_with("GET", endpoint)
    output: "Well-structured test with proper typing and documentation"

metadata:
  priority: high
  version: 1.0
  tags:
    - python
    - testing
    - unit-tests
    - integration-tests
</rule>
