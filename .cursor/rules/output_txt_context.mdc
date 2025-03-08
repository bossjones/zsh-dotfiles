---
description: Guidelines for extracting context from output.txt files
globs: **/output.txt
alwaysApply: false
---
# Extracting Context from output.txt Files

This rule provides systematic guidance for efficiently searching through and extracting relevant context from `output.txt` files, which are packed representations of repository contents designed for AI systems.

<rule>
name: output_txt_context
description: Expert guidelines for efficiently working with output.txt files

filters:
  - type: path
    pattern: ".*output\\.txt$"

actions:
  - type: suggest
    message: |
      # Guidelines for Working with output.txt Files

      ## Understanding output.txt Files

      `output.txt` files are packed representations of repository contents designed specifically for AI systems to process. They typically:

      1. Contain file contents preceded by path tags (`<file path="...">`)
      2. Include both code and documentation from the repository
      3. May contain sensitive information not meant for public exposure
      4. Follow a structured format for easy parsing

      ## Efficient Search Techniques

      When working with `output.txt` files, use these techniques to efficiently locate and extract information:

      ### 1. Finding Specific Files

      ```python
      # Use grep_search to locate specific file paths
      grep_search(query="<file path=\"desired/path/to/file.py\">")

      # Note the line number where the file content begins
      # Then read that section of the file
      read_file(
          relative_workspace_path="output.txt",
          start_line_one_indexed=FOUND_LINE_NUMBER,
          end_line_one_indexed_inclusive=FOUND_LINE_NUMBER + 100  # Adjust as needed
      )
      ```

      ### 2. Directory Exploration

      ```python
      # Find all files in a specific directory
      grep_search(query="<file path=\"desired/directory/")

      # This returns all files within that directory structure
      ```

      ### 3. Content-Based Search

      ```python
      # Search for specific content across all files
      grep_search(query="specific function or class name")

      # This can help locate implementation details across the repository
      ```

      ## Reading Strategy

      Once you've identified a relevant section:

      1. **Start with headers/metadata**: Read the file path and any surrounding context
      2. **Scan imports/dependencies**: Understand what the file depends on
      3. **Identify core functionality**: Focus on classes, functions, and their docstrings
      4. **Look for examples**: Many files contain example usage that demonstrates functionality
      5. **Find related files**: Use imports and references to build a mental map of related components

      ## Interpreting File Content

      When reading file content from `output.txt`:

      1. **Respect file boundaries**: Different sections represent different files
      2. **Preserve context**: Associate code with its original file location
      3. **Handle truncation**: Some files may be truncated; look for continuation indicators
      4. **Mind the format**: Content might have special characters for AI parsing that differ from the actual source code
      5. **Verify completeness**: Check if you're seeing the entire file or just a portion

      ## Common Patterns

      ### Python Files

      ```
      <file path="examples/module/file.py">
      """
      Docstring describing the file's purpose
      """

      import statements...

      class/function definitions...
      </file>
      ```

      ### Configuration Files

      ```
      <file path="config/settings.json">
      {
          "configuration": "values",
          "settings": {...}
      }
      </file>
      ```

      ## Implementation Example

      ```python
      # Step 1: Find a specific file
      result = grep_search(query="<file path=\"examples/fastmcp/complex_inputs.py\">")

      # Step 2: Extract the line number
      start_line = extract_line_number_from_result(result)

      # Step 3: Read the relevant section
      file_content = read_file(
          relative_workspace_path="output.txt",
          start_line_one_indexed=start_line,
          end_line_one_indexed_inclusive=start_line + 100  # Adjust as needed
      )

      # Step 4: Process the content
      # Now analyze the file_content to understand the implementation
      ```

      ## Best Practices

      1. **Be specific in your searches**: Target exact file paths or unique content
      2. **Read in meaningful chunks**: Avoid reading the entire file at once
      3. **Follow imports and references**: Build a connected understanding of components
      4. **Look for examples**: Example code often provides the clearest insight
      5. **Preserve file context**: Always note which file a code segment comes from
      6. **Verify with direct file access**: When possible, cross-check with the actual files in the repository

examples:
  - input: |
      # Need to find examples of FastMCP implementation
      # Where can I find them in the output.txt file?
    output: |
      I'll help you find FastMCP examples in the output.txt file:

      ```python
      # First, let's search for FastMCP example files
      grep_search(query="<file path=\"examples/fastmcp/")

      # This should return something like:
      # output.txt:1095:<file path="examples/fastmcp/complex_inputs.py">
      # output.txt:1128:<file path="examples/fastmcp/desktop.py">
      # output.txt:1156:<file path="examples/fastmcp/echo.py">
      # ... and more

      # Now let's read one of these files, starting with complex_inputs.py
      read_file(
          relative_workspace_path="output.txt",
          start_line_one_indexed=1095,  # Line where complex_inputs.py begins
          end_line_one_indexed_inclusive=1127  # Adjust to read the complete file
      )
      ```

      These examples will show you different aspects of FastMCP implementation:

      1. complex_inputs.py - Demonstrates validation via Pydantic
      2. desktop.py - Shows how to list files on the user's desktop
      3. echo.py - Implements a simple echo server

      Let me know which specific aspect of FastMCP you're interested in, and I can help locate the most relevant examples.

  - input: |
      # I need to understand how text encoding works in the repository
      # Can you find relevant examples in output.txt?
    output: |
      I'll search for text encoding examples in the output.txt file:

      ```python
      # Search for encoding-related content
      grep_search(query="encoding")

      # For more specific Unicode handling
      grep_search(query="unicode")

      # This revealed a Unicode example file
      grep_search(query="<file path=\"examples/fastmcp/unicode_example.py\">")

      # Found at line 1700, let's read it
      read_file(
          relative_workspace_path="output.txt",
          start_line_one_indexed=1700,
          end_line_one_indexed_inclusive=1750
      )
      ```

      The unicode_example.py file demonstrates:

      1. How to properly handle Unicode characters in tool descriptions
      2. Handling of Unicode in parameter defaults
      3. Returning Unicode strings from tools
      4. Support for emojis and international character sets

      This file provides a good reference for ensuring your code handles text encoding correctly, particularly when working with international character sets.

metadata:
  priority: medium
  version: 1.0
  author: "AI Assistant"
  created: "2024-07-25"
</rule>

## References and Resources

- [Model Context Protocol (MCP) Specification](https://github.com/microsoft/mcp) - For understanding structured data formats
- [Python regex documentation](https://docs.python.org/3/library/re.html) - Helpful for creating precise search patterns
- [JSON Schema](https://json-schema.org/) - For understanding schema formats in output.txt files
