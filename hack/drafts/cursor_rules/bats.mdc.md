# BATS Testing Best Practices

Guidelines for writing and debugging BATS (Bash Automated Testing System) tests.

<rule>
name: bats_testing
description: Best practices for writing and debugging BATS tests
filters:
  # Match BATS test files
  - type: file_extension
    pattern: "\\.bats$"
  # Match BATS helper files
  - type: file_path
    pattern: ".*test_helpers\\.bash$"
  # Match BATS setup files
  - type: file_path
    pattern: ".*setup_suite\\.bash$"
  # Match when user is asking about BATS testing
  - type: message
    pattern: "(?i)(bats|bash automated testing|test bash|bash test)"

actions:
  - type: suggest
    message: |
      # BATS Testing Best Practices

      ## BATS Test Structure

      BATS (Bash Automated Testing System) tests follow this general structure:

      ```bash
      #!/usr/bin/env bats

      # Load test helpers
      load test_helpers

      # Setup runs before each test
      setup() {
        # Initialize test environment
      }

      # Teardown runs after each test
      teardown() {
        # Clean up test environment
      }

      # Test case
      @test "descriptive test name" {
        # Arrange - set up test conditions

        # Act - run the command being tested
        run command_to_test

        # Assert - verify the results
        [ "$status" -eq 0 ]
        [ "$output" = "expected output" ]
      }
      ```

      ## Key Components

      1. **Test Helpers**: Common utilities loaded with `load test_helpers`
      2. **Setup/Teardown**: Functions that run before/after each test
      3. **Test Cases**: Individual tests marked with `@test`
      4. **Run Command**: Use `run` to capture command output and status
      5. **Assertions**: Use `[ ]` for assertions (standard bash test syntax)

      ## Best Practices

      ### 1. Test Organization

      - **One Feature Per File**: Group related tests in a single file
      - **Descriptive Filenames**: Use `feature_command.bats` naming pattern
      - **Descriptive Test Names**: Make test names clear and descriptive
      - **Test Independence**: Each test should be independent and not rely on other tests

      ### 2. Setup and Teardown

      - **Clean Environment**: Reset environment between tests
      - **Isolated Directories**: Use temporary directories for file operations
      - **Mock External Dependencies**: Create fixtures for external systems
      - **Cleanup Resources**: Always clean up in teardown to prevent test interference

      ### 3. Test Assertions

      - **Check Exit Status**: Verify command exit status with `[ "$status" -eq 0 ]`
      - **Check Output**: Verify command output with `[ "$output" = "expected" ]`
      - **Check Partial Output**: Use `[[ "$output" =~ "pattern" ]]` for partial matches
      - **Check File Contents**: Verify file contents were created/modified correctly
      - **Multiple Assertions**: Include multiple assertions to fully verify behavior

      ### 4. Mocking and Fixtures

      - **Mock Commands**: Create mock versions of external commands
      - **Fixture Files**: Use fixture files for test data
      - **Mock Environment**: Set up a controlled environment for testing
      - **Git Repositories**: Initialize test git repositories with controlled state

      ### 5. Debugging Techniques

      - **Print Debug Info**: Use `echo "Debug: $variable" >&3` to print to console
      - **Inspect Variables**: Print variables with `echo "$variable" >&3`
      - **Trace Execution**: Use `set -x` for command tracing
      - **Examine Test Environment**: Print environment state for debugging
      - **Isolate Failures**: Run specific tests with `bats test_file.bats -f "test name"`

      ## Common Patterns

      ### Running Commands Under Test

      ```bash
      # Basic command execution
      run command arg1 arg2

      # With environment variables
      run env VAR=value command arg1

      # With input
      echo "input" | run command arg1
      ```

      ### Assertions

      ```bash
      # Check exit status
      [ "$status" -eq 0 ]  # Success
      [ "$status" -ne 0 ]  # Failure

      # Check output
      [ "$output" = "expected output" ]
      [[ "$output" =~ "pattern" ]]

      # Check output lines
      [ "${lines[0]}" = "first line" ]
      [ "${#lines[@]}" -eq 3 ]  # Check number of lines

      # Check file existence
      [ -f "path/to/file" ]
      [ -d "path/to/directory" ]

      # Check file contents
      [ "$(cat file.txt)" = "expected content" ]
      ```

      ### Skipping Tests

      ```bash
      @test "skip this test" {
        skip "Reason for skipping"
        # Test code (won't be executed)
      }

      @test "conditionally skip" {
        if [ some_condition ]; then
          skip "Skip when condition is true"
        fi
        # Test code
      }
      ```

      ## Advanced Techniques

      ### 1. Setup Suite and Teardown Suite

      For operations that should happen once per test file:

      ```bash
      # setup_suite.bash
      setup_suite() {
        # Global setup for all tests in the file
      }

      teardown_suite() {
        # Global teardown after all tests in the file
      }
      ```

      ### 2. Parameterized Tests

      ```bash
      for param in value1 value2 value3; do
        @test "test with $param" {
          run command "$param"
          [ "$status" -eq 0 ]
        }
      done
      ```

      ### 3. Testing Error Conditions

      ```bash
      @test "command fails with invalid input" {
        run command --invalid
        [ "$status" -ne 0 ]
        [[ "$output" =~ "error message" ]]
      }
      ```

      ### 4. Testing with Temporary Files

      ```bash
      @test "command processes file" {
        temp_file="$(mktemp)"
        echo "test data" > "$temp_file"

        run command "$temp_file"

        [ "$status" -eq 0 ]
        [ -f "$temp_file.processed" ]

        rm -f "$temp_file" "$temp_file.processed"
      }
      ```

      ### 5. Mocking External Commands

      ```bash
      @test "command uses curl" {
        # Create mock curl in PATH
        mock_dir="$(mktemp -d)"
        echo '#!/bin/bash
        echo "mocked response"
        exit 0' > "$mock_dir/curl"
        chmod +x "$mock_dir/curl"

        PATH="$mock_dir:$PATH"

        run command_that_uses_curl

        [ "$status" -eq 0 ]
        [[ "$output" =~ "mocked response" ]]

        rm -rf "$mock_dir"
      }
      ```

      ## Debugging Failed Tests

      When a test fails, try these approaches:

      1. **Run Single Test**: `bats test_file.bats -f "test name"`
      2. **Print Debug Info**: Add `echo "Debug: $variable" >&3` statements
      3. **Trace Execution**: Add `set -x` at the start of the test
      4. **Examine Environment**: Print relevant environment variables
      5. **Check File Contents**: Examine files created during the test
      6. **Simplify Test**: Temporarily simplify the test to isolate the issue
      7. **Manual Verification**: Run the commands manually to verify behavior

      ## BATS Command Line Options

      ```bash
      # Run all tests
      bats tests/

      # Run specific test file
      bats tests/specific_test.bats

      # Run tests matching pattern
      bats tests/ -f "pattern"

      # Print test output even for passing tests
      bats tests/ -p

      # Show timing information
      bats tests/ -T

      # Increase formatter output
      bats tests/ -v
      ```

examples:
  - input: |
      I need to write a BATS test for my command that installs a tool.
    output: |
      Here's a template for testing an installation command with BATS:

      ```bash
      #!/usr/bin/env bats

      # Load test helpers if you have them
      load test_helpers

      setup() {
        # Create a temporary directory for testing
        TEST_DIR="$(mktemp -d)"

        # Set up any environment variables needed
        export INSTALL_DIR="$TEST_DIR/installs"
        mkdir -p "$INSTALL_DIR"

        # Save original PATH
        OLD_PATH="$PATH"

        # Add test directory to PATH if needed
        PATH="$TEST_DIR/bin:$PATH"
      }

      teardown() {
        # Restore original PATH
        PATH="$OLD_PATH"

        # Clean up test directory
        rm -rf "$TEST_DIR"
      }

      @test "install command installs the tool successfully" {
        # Arrange - prepare any necessary files or state
        echo "1.2.3" > "$TEST_DIR/version.txt"

        # Act - run the installation command
        run my-tool install --version 1.2.3 --dir "$INSTALL_DIR"

        # Assert - verify the command succeeded
        [ "$status" -eq 0 ]
        [ -d "$INSTALL_DIR/1.2.3" ]
        [ -f "$INSTALL_DIR/1.2.3/bin/tool-executable" ]
        [ -x "$INSTALL_DIR/1.2.3/bin/tool-executable" ]

        # Verify the installed tool works
        run "$INSTALL_DIR/1.2.3/bin/tool-executable" --version
        [ "$status" -eq 0 ]
        [ "$output" = "1.2.3" ]
      }

      @test "install command fails with invalid version" {
        # Act - run with invalid version
        run my-tool install --version invalid-version --dir "$INSTALL_DIR"

        # Assert - verify the command failed appropriately
        [ "$status" -ne 0 ]
        [[ "$output" =~ "Invalid version" ]]
        [ ! -d "$INSTALL_DIR/invalid-version" ]
      }

      @test "install command creates shims" {
        # Arrange
        SHIM_DIR="$TEST_DIR/shims"
        mkdir -p "$SHIM_DIR"

        # Act
        run my-tool install --version 1.2.3 --dir "$INSTALL_DIR" --shim-dir "$SHIM_DIR"

        # Assert
        [ "$status" -eq 0 ]
        [ -f "$SHIM_DIR/tool-executable" ]
        [ -x "$SHIM_DIR/tool-executable" ]

        # Verify shim works
        run "$SHIM_DIR/tool-executable" --version
        [ "$status" -eq 0 ]
        [ "$output" = "1.2.3" ]
      }
      ```

      This template includes:
      1. Setup and teardown for test isolation
      2. Tests for successful installation
      3. Tests for error handling
      4. Tests for additional features (shims)

      Adapt this to your specific tool's installation process and requirements.

  - input: |
      How do I debug a failing BATS test?
    output: |
      # Debugging Failing BATS Tests

      When you have a failing BATS test, follow these steps to diagnose and fix the issue:

      ## 1. Isolate the Failing Test

      Run only the failing test:

      ```bash
      # Run a specific test file
      bats path/to/failing_test.bats

      # Run a specific test by name pattern
      bats path/to/failing_test.bats -f "test name pattern"
      ```

      ## 2. Add Debug Output

      BATS redirects stdout and stderr to capture them for assertions. To print debug information:

      ```bash
      @test "failing test" {
        # Print debug info to the console (file descriptor 3)
        echo "Debug: Starting test" >&3

        # Show variable values
        echo "Debug: PATH=$PATH" >&3

        run command_that_fails

        # Print command results
        echo "Debug: status=$status" >&3
        echo "Debug: output=$output" >&3

        # Print file contents if relevant
        echo "Debug: File contents:" >&3
        cat some_file >&3

        # Original assertions
        [ "$status" -eq 0 ]
      }
      ```

      ## 3. Use Bash Tracing

      Add `set -x` to see each command as it executes:

      ```bash
      @test "failing test" {
        # Enable command tracing
        set -x

        run command_that_fails

        # Disable tracing if desired
        set +x

        [ "$status" -eq 0 ]
      }
      ```

      ## 4. Examine the Test Environment

      Check the state of the test environment:

      ```bash
      @test "failing test" {
        # Print directory contents
        echo "Debug: Directory contents:" >&3
        ls -la >&3

        # Print environment variables
        echo "Debug: Environment:" >&3
        env | sort >&3

        run command_that_fails

        [ "$status" -eq 0 ]
      }
      ```

      ## 5. Run Commands Manually

      Try running the failing command manually outside of BATS:

      ```bash
      # Set up the same environment as in the test
      export VAR=value
      cd /path/to/test/dir

      # Run the command directly
      command_that_fails

      # Check the exit status
      echo $?
      ```

      ## 6. Check for Race Conditions

      If tests pass individually but fail when run together, look for:
      - Shared resources between tests
      - Missing cleanup in teardown
      - Timing issues

      ## 7. Simplify the Test

      Temporarily simplify the test to isolate the issue:

      ```bash
      @test "simplified failing test" {
        # Comment out parts of the test to isolate the issue
        # run setup_command

        run command_that_fails

        # Print raw output for inspection
        echo "Full output:" >&3
        echo "$output" >&3

        # Simplify assertions
        [ "$status" -eq 0 ]
        # [ "$output" = "expected" ]
      }
      ```

      ## 8. Check for Common Issues

      - **Path issues**: Is the command in PATH?
      - **Permission issues**: Are files executable?
      - **Environment variables**: Are required variables set?
      - **File existence**: Do required files exist?
      - **Timing issues**: Does the test need a sleep or wait?
      - **Quoting issues**: Are variables properly quoted?

      ## 9. Use BATS Verbose Mode

      Run BATS with verbose output:

      ```bash
      bats -v path/to/failing_test.bats
      ```

      Remember that BATS tests should be deterministic and isolated. Each test should set up its own environment and clean up after itself.

metadata:
  priority: high
  version: 1.0
  tags:
    - testing
    - bash
    - bats
    - shell-scripting
</rule>
