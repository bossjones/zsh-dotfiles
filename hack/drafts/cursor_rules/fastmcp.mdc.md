---
description: Fast Python MCP Server Development
globs: *.py
alwaysApply: false
---
# Fast Python MCP Server Development

This rule provides comprehensive guidance for developing Model Context Protocol (MCP) servers in Python, enabling seamless communication between AI clients and servers.

<rule>
name: fastmcp
description: Expert guidelines for developing Python MCP servers efficiently

filters:
  - type: file_extension
    pattern: "\\.py$"
  - type: path
    pattern: ".*/mcp/.*"

actions:
  - type: suggest
    message: |
      # Python MCP Server Development Guidelines

      ## Server Type Selection

      When creating a new FastMCP server, it's important to determine which type of server best suits your needs. Please specify which type of FastMCP server you want to implement:

      1. **Simple Echo Server** - Basic server that echoes input text
      2. **Desktop Files Listing** - Server exposing file system information
      3. **Parameter Descriptions** - Server demonstrating detailed parameter documentation
      4. **Text Message Service** - Server integrating with external SMS API
      5. **Screenshot Tool** - Server returning images as response
      6. **Unicode Support** - Server supporting international characters and emojis
      7. **Complex Input Validation** - Server using Pydantic models for advanced validation
      8. **Dynamic Resources** - Server with path templates and variable resources

      If you have specific requirements that don't match any of these templates, please describe your use case and I'll suggest the most appropriate approach.

      ### Recommendations by Use Case

      Not sure which server type to choose? Here are recommendations based on common use cases:

      - **Getting Started**: Choose the **Simple Echo Server**
      - **Data Validation Focus**: Choose **Complex Input Validation**
      - **Documentation Focus**: Choose **Parameter Descriptions**
      - **External API Integration**: Choose **Text Message Service**
      - **File System Integration**: Choose **Desktop Files Listing**
      - **International Support**: Choose **Unicode Support**
      - **Binary Data Handling**: Choose **Screenshot Tool**
      - **Dynamic Content**: Choose **Dynamic Resources**

      ## Overview

      The Model Context Protocol (MCP) is a standardized communication protocol that enables AI clients and servers to exchange
      messages, capabilities, and resources. This guide provides best practices for implementing MCP servers in Python.

      ## Core MCP Concepts

      1. **Protocol Structure**: MCP follows the JSON-RPC 2.0 specification with specific message types:
         - **Requests**: Messages requiring a response (with ID)
         - **Responses**: Replies to requests (matching request ID)
         - **Notifications**: Messages not requiring a response (no ID)

      2. **Lifecycle Phases**:
         - **Initialization**: Capability negotiation and protocol version agreement
         - **Operation**: Normal message exchange
         - **Shutdown**: Graceful connection termination

      3. **Transport Mechanisms**:
         - **stdio**: Communication over standard input/output
         - **HTTP with SSE**: Server-Sent Events for server-to-client communication
         - **WebSocket**: Bidirectional communication (if supported)

      ## Project Structure

      The MCP Python SDK has the following structure:

      ```
      src/mcp/
      ├── __init__.py             # Package initialization
      ├── types.py                # Core type definitions
      ├── server/                 # Server implementation
      │   ├── __init__.py
      │   ├── fastmcp/            # High-level FastMCP framework
      │   │   ├── __init__.py
      │   │   ├── server.py       # Main FastMCP implementation
      │   │   ├── exceptions.py   # FastMCP-specific exceptions
      │   │   ├── tools/          # Tool implementation
      │   │   ├── resources/      # Resource implementation
      │   │   ├── prompts/        # Prompt implementation
      │   │   └── utilities/      # Utility functions
      │   ├── lowlevel/           # Low-level server implementation
      │   ├── stdio.py            # stdio transport
      │   └── sse.py              # HTTP+SSE transport
      ├── client/                 # Client implementation
      └── shared/                 # Shared utilities
      ```

      ## FastMCP: High-level API

      FastMCP provides a convenient, decorator-based API for creating MCP servers. Here are examples of different server types:

      ### Simple Echo Server

      ```python
      """
      FastMCP Echo Server
      """

      from mcp.server.fastmcp import FastMCP

      # Create server
      mcp = FastMCP("Echo Server")


      @mcp.tool()
      def echo(text: str) -> str:
          """Echo the input text"""
          return text
      ```

      ### Desktop Files Listing

      ```python
      """
      FastMCP Desktop Example

      A simple example that exposes the desktop directory as a resource.
      """

      from pathlib import Path

      from mcp.server.fastmcp import FastMCP

      # Create server
      mcp = FastMCP("Demo")


      @mcp.resource("dir://desktop")
      def desktop() -> list[str]:
          """List the files in the user's desktop"""
          desktop = Path.home() / "Desktop"
          return [str(f) for f in desktop.iterdir()]


      @mcp.resource("file://{path}")
      def get_file(path: str) -> str:
          """Get the contents of a file"""
          file_path = Path(path)
          if not file_path.exists():
              raise FileNotFoundError(f"File not found: {path}")
          return file_path.read_text()


      @mcp.tool()
      def list_directory(path: str = ".") -> list[str]:
          """List the contents of a directory"""
          dir_path = Path(path)
          if not dir_path.exists() or not dir_path.is_dir():
              raise NotADirectoryError(f"Not a directory: {path}")
          return [str(f) for f in dir_path.iterdir()]
      ```

      ### Parameter Descriptions

      ```python
      from pydantic import Field
      from mcp.server.fastmcp import FastMCP

      mcp = FastMCP("Parameter Descriptions Server")

      @mcp.tool()
      def greet_user(
          name: str = Field(description="The name of the person to greet"),
          title: str = Field(description="Optional title like Mr/Ms/Dr", default=""),
          times: int = Field(description="Number of times to repeat the greeting", default=1),
      ) -> str:
          """Greet a user with optional title and repetition"""
          greeting = f"Hello {title + ' ' if title else ''}{name}!"
          return "\n".join([greeting] * times)
      ```

      ### Text Message Service

      ```python
      """
      FastMCP Text Me Server
      --------------------------------
      This defines a simple FastMCP server that sends a text message to a phone number via https://surgemsg.com/.

      To run this example, create a `.env` file with the following values:

      SURGE_API_KEY=...
      SURGE_ACCOUNT_ID=...
      SURGE_MY_PHONE_NUMBER=...
      SURGE_MY_FIRST_NAME=...
      SURGE_MY_LAST_NAME=...

      Visit https://surgemsg.com/ and click "Get Started" to obtain these values.
      """

      from typing import Annotated

      import httpx
      from pydantic import BeforeValidator
      from pydantic_settings import BaseSettings, SettingsConfigDict

      from mcp.server.fastmcp import FastMCP


      class SurgeSettings(BaseSettings):
          model_config: SettingsConfigDict = SettingsConfigDict(
              env_prefix="SURGE_", env_file=".env"
          )

          api_key: str
          account_id: str
          my_phone_number: Annotated[
              str, BeforeValidator(lambda v: "+" + v if not v.startswith("+") else v)
          ]
          my_first_name: str
          my_last_name: str


      # Create server
      mcp = FastMCP("Text me")
      surge_settings = SurgeSettings()  # type: ignore


      @mcp.tool(name="textme", description="Send a text message to me")
      def text_me(text_content: str) -> str:
          """Send a text message to a phone number via https://surgemsg.com/"""
          with httpx.Client() as client:
              response = client.post(
                  "https://api.surgemsg.com/messages",
                  headers={
                      "Authorization": f"Bearer {surge_settings.api_key}",
                      "Surge-Account": surge_settings.account_id,
                      "Content-Type": "application/json",
                  },
                  json={
                      "body": text_content,
                      "conversation": {
                          "contact": {
                              "first_name": surge_settings.my_first_name,
                              "last_name": surge_settings.my_last_name,
                              "phone_number": surge_settings.my_phone_number,
                          }
                      },
                  },
              )
              response.raise_for_status()
              return f"Message sent: {text_content}"
      ```

      ### Screenshot Tool

      ```python
      import io
      from mcp.server.fastmcp import FastMCP
      from mcp.server.fastmcp.utilities.types import Image

      mcp = FastMCP("Screenshot Demo", dependencies=["pyautogui", "Pillow"])

      @mcp.tool()
      def take_screenshot() -> Image:
          """
          Take a screenshot of the user's screen and return it as an image.
          """
          import pyautogui

          buffer = io.BytesIO()
          screenshot = pyautogui.screenshot()
          screenshot.convert("RGB").save(buffer, format="JPEG", quality=60, optimize=True)
          return Image(data=buffer.getvalue(), format="jpeg")
      ```

      ### Unicode Support

      ```python
      from mcp.server.fastmcp import FastMCP

      mcp = FastMCP()

      @mcp.tool(
          description="🌟 A tool that uses various Unicode characters in its description: "
          "á é í ó ú ñ 漢字 🎉"
      )
      def hello_unicode(name: str = "世界", greeting: str = "¡Hola") -> str:
          """
          A simple tool that demonstrates Unicode handling in:
          - Tool description (emojis, accents, CJK characters)
          - Parameter defaults (CJK characters)
          - Return values (Spanish punctuation, emojis)
          """
          return f"{greeting}, {name}! 👋"
      ```

      ### Complex Input Validation with Pydantic

      ```python
      from typing import Annotated, List
      from pydantic import BaseModel, Field
      from mcp.server.fastmcp import FastMCP

      mcp = FastMCP("Validation Example")

      # Define complex models with validation
      class User(BaseModel):
          name: str
          email: Annotated[str, Field(pattern=r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$")]
          age: Annotated[int, Field(ge=0, lt=150)]

      class TeamRequest(BaseModel):
          team_name: Annotated[str, Field(min_length=3, max_length=50)]
          members: Annotated[List[User], Field(min_length=1)]

      @mcp.tool()
      def create_team(request: TeamRequest) -> dict:
          """Create a team with the given members"""
          return {
              "team_id": "team_123",
              "team_name": request.team_name,
              "member_count": len(request.members),
              "members": [user.name for user in request.members]
          }
      ```

      ### Dynamic Resources with Path Templates

      ```python
      from mcp.server.fastmcp import FastMCP

      mcp = FastMCP("Demo")

      # Dynamic resource with path variable
      @mcp.resource("greeting://{name}")
      def get_greeting(name: str) -> str:
          """Get a personalized greeting"""
          return f"Hello, {name}!"
      ```

      ## Using Context in Tools and Resources

      FastMCP provides a Context object that can be injected into tool and resource functions to access MCP capabilities:

      ```python
      from mcp.server.fastmcp import FastMCP
      from mcp.server.fastmcp.server import Context

      mcp = FastMCP("Context Demo")

      @mcp.tool()
      def log_message(message: str, ctx: Context) -> str:
          """Log a message and return it"""
          # Log messages to the client
          ctx.info(f"Processing message: {message}")

          # Report progress
          ctx.report_progress(50, 100)

          # Access request information
          request_id = ctx.request_id

          return f"Logged: {message}"
      ```

      ## Testing FastMCP Servers

      Testing FastMCP servers is straightforward with pytest:

      ```python
      import pytest
      from mcp.shared.memory import create_connected_server_and_client_session as client_session
      from mcp.types import TextContent

      @pytest.mark.anyio
      async def test_echo_server():
          """Test the echo server"""
          from examples.fastmcp.simple_echo import mcp

          async with client_session(mcp._mcp_server) as client:
              result = await client.call_tool("echo", {"text": "hello"})

              assert len(result.content) == 1
              content = result.content[0]
              assert isinstance(content, TextContent)
              assert content.text == "hello"
      ```

      ## Best Practices

      1. **Clean Architecture**:
         - Separate message handling from business logic
         - Use dependency injection for flexibility
         - Implement proper error handling

      2. **Asynchronous Design**:
         - Use `asyncio` for non-blocking I/O
         - Handle multiple concurrent requests efficiently
         - Implement proper cancellation support

      3. **Testing**:
         - Unit test each component in isolation
         - Integration test the server with mock clients
         - Test error handling and edge cases

      4. **Security Considerations**:
         - Validate all incoming messages
         - Implement proper authentication if needed
         - Sanitize all outputs to prevent injection attacks

      ## References

      - [MCP GitHub Repository](https://github.com/anthropics/anthropic-model-context-protocol)
      - [JSON-RPC 2.0 Specification](https://www.jsonrpc.org/specification)
      - [Python asyncio Documentation](https://docs.python.org/3/library/asyncio.html)

examples:
  - input: |
      # I need to create a simple MCP server that echoes text
      from mcp.server.fastmcp import FastMCP
    output: |
      Here's how to implement a simple echo server with FastMCP:

      ```python
      """
      FastMCP Echo Server
      """

      from mcp.server.fastmcp import FastMCP

      # Create server
      mcp = FastMCP("Echo Server")


      @mcp.tool()
      def echo(text: str) -> str:
          """Echo the input text"""
          return text
      ```

      This creates a minimal MCP server with a single tool that echoes back any text sent to it. To run this server:

      1. Save this code to a file (e.g., `echo_server.py`)
      2. Run it with Python: `python echo_server.py`

      The server will start and listen on the stdio transport by default. You can also specify the transport:

      ```python
      if __name__ == "__main__":
          mcp.run(transport="stdio")  # or "sse" for HTTP+SSE
      ```

  - input: |
      # How do I implement a FastMCP server that exposes file system resources?
      from mcp.server.fastmcp import FastMCP
    output: |
      Here's how to implement a FastMCP server that exposes file system resources:

      ```python
      """
      FastMCP Desktop Example

      A simple example that exposes the desktop directory as a resource.
      """

      from pathlib import Path

      from mcp.server.fastmcp import FastMCP

      # Create server
      mcp = FastMCP("File System Demo")


      @mcp.resource("dir://desktop")
      def desktop() -> list[str]:
          """List the files in the user's desktop"""
          desktop = Path.home() / "Desktop"
          return [str(f) for f in desktop.iterdir()]


      @mcp.resource("file://{path}")
      def get_file(path: str) -> str:
          """Get the contents of a file"""
          file_path = Path(path)
          if not file_path.exists():
              raise FileNotFoundError(f"File not found: {path}")
          return file_path.read_text()


      @mcp.tool()
      def list_directory(path: str = ".") -> list[str]:
          """List the contents of a directory"""
          dir_path = Path(path)
          if not dir_path.exists() or not dir_path.is_dir():
              raise NotADirectoryError(f"Not a directory: {path}")
          return [str(f) for f in dir_path.iterdir()]
      ```

      This server exposes:
      1. A static resource that lists desktop files
      2. A dynamic resource template that can access any file by path
      3. A tool that lists directory contents

      Remember to handle security considerations carefully when exposing file system resources.

  - input: |
      # How do I use Pydantic models for parameter validation in FastMCP?
      from mcp.server.fastmcp import FastMCP
    output: |
      Here's how to use Pydantic models for parameter validation in FastMCP:

      ```python
      from typing import Annotated, List
      from pydantic import BaseModel, Field
      from mcp.server.fastmcp import FastMCP

      # Create server
      mcp = FastMCP("Validation Example")

      # Define complex models with validation
      class User(BaseModel):
          name: str
          email: Annotated[str, Field(pattern=r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$")]
          age: Annotated[int, Field(ge=0, lt=150)]

      class TeamRequest(BaseModel):
          team_name: Annotated[str, Field(min_length=3, max_length=50)]
          members: Annotated[List[User], Field(min_length=1)]

      @mcp.tool()
      def create_team(request: TeamRequest) -> dict:
          """Create a team with the given members"""
          return {
              "team_id": "team_123",
              "team_name": request.team_name,
              "member_count": len(request.members),
              "members": [user.name for user in request.members]
          }
      ```

      This example demonstrates:
      1. Creating Pydantic models with validation rules
      2. Using `Annotated` with `Field` for detailed constraints
      3. Nesting models for complex data structures
      4. Using the models as parameter types in tool functions

      FastMCP will automatically:
      - Generate proper JSON Schema for these models
      - Validate incoming requests against the schema
      - Convert valid JSON to Pydantic model instances
      - Provide helpful error messages for invalid inputs

metadata:
  priority: high
  version: 1.0
  author: "AI Assistant"
  created: "2024-07-16"
</rule>

## References and Resources

- [MCP GitHub Repository](https://github.com/anthropics/anthropic-model-context-protocol) - Official specification
- [JSON-RPC 2.0 Specification](https://www.jsonrpc.org/specification) - Base protocol
- [Python asyncio Documentation](https://docs.python.org/3/library/asyncio.html) - Asynchronous I/O for Python

## Testing FastMCP Servers

Testing FastMCP servers is an essential part of ensuring your implementation works correctly. The MCP framework provides utilities that make testing straightforward with pytest.

### Testing Framework Setup

To test FastMCP servers, you'll need:

1. **pytest**: The testing framework
2. **mcp.shared.memory**: For creating in-memory client-server connections
3. **mcp.types**: For type checking and response validation

### Basic Test Structure

Here's a standard pattern for writing tests for FastMCP servers:

```python
import pytest

from mcp.shared.memory import (
    create_connected_server_and_client_session as client_session,
)
from mcp.types import TextContent, TextResourceContents

@pytest.mark.anyio
async def test_your_server():
    """Test description"""
    # Import your FastMCP server
    from your_module import mcp

    # Create an in-memory client-server connection
    async with client_session(mcp._mcp_server) as client:
        # Call your tool and test the response
        result = await client.call_tool("your_tool_name", {"param1": "value1"})

        # Assertions to validate the response
        assert len(result.content) == 1
        content = result.content[0]
        assert isinstance(content, TextContent)
        assert content.text == "expected_output"
```

### Example: Testing a Simple Echo Server

This example demonstrates testing a simple echo server:

```python
@pytest.mark.anyio
async def test_simple_echo():
    """Test the simple echo server"""
    from examples.fastmcp.simple_echo import mcp

    async with client_session(mcp._mcp_server) as client:
        result = await client.call_tool("echo", {"text": "hello"})
        assert len(result.content) == 1
        content = result.content[0]
        assert isinstance(content, TextContent)
        assert content.text == "hello"
```

### Example: Testing Resources

For testing resources, you can use the `read_resource` method:

```python
@pytest.mark.anyio
async def test_desktop_resource():
    """Test the desktop resource"""
    from examples.fastmcp.desktop import mcp
    from pydantic import AnyUrl

    async with client_session(mcp._mcp_server) as client:
        result = await client.read_resource(AnyUrl("dir://desktop"))
        assert len(result.contents) == 1
        content = result.contents[0]
        assert isinstance(content, TextResourceContents)
        assert isinstance(content.text, str)
```

### Testing Best Practices for FastMCP Servers

1. **Isolate Tests**: Each test should focus on one specific functionality
2. **Mock External Dependencies**: Use `monkeypatch` or `pytest-mock` to avoid actual file system or network calls
3. **Test Error Cases**: Verify that your server correctly handles invalid inputs
4. **Test Protocol Conformance**: Ensure your server follows the MCP protocol correctly
5. **Use Client Session**: Always use `client_session` to create a proper in-memory connection
6. **Type Check Results**: Verify that responses contain the expected types
7. **Content Validation**: Check the actual content of responses, not just their structure

By following these testing patterns, you can ensure your FastMCP servers work correctly and reliably.
