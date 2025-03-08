I'll help you analyze this repository and identify everything related to fastmacp. Let's start by understanding the repository structure.

Ran tool
Let's look at the source directory to understand the codebase structure:

Ran tool
Let's look at the MCP directory:

Ran tool
Now, let's search for "fastmacp" in the codebase to find all related files and code:

Ran tool
Let's try a different approach. Let's search for "fast" and "mcp" together to find related files:

Ran tool
Now, let's look at the server directory to find the FastMCP implementation:

Ran tool
Great! Let's look at the FastMCP directory structure:

Ran tool
Let's look at the main FastMCP server implementation:

Read file: src/mcp/server/fastmcp/__init__.py
Now, let's look at the main server implementation:

Read file: src/mcp/server/fastmcp/server.py
Let's also look at the utilities directory to understand the supporting functionality:

Ran tool
Let's look at the tools directory:

Ran tool
Let's look at the resources directory:

Ran tool
Let's look at the prompts directory:

Ran tool
Now, let's look at some example FastMCP implementations to understand how it's used:

Read file: examples/fastmcp/echo.py
Let's look at a more complex example:

Read file: examples/fastmcp/complex_inputs.py
Let's look at the FastMCP exceptions:

Read file: src/mcp/server/fastmcp/exceptions.py
Let's look at the types module to understand the data structures:

Read file: src/mcp/server/fastmcp/utilities/types.py
Based on the analysis of the repository, I'll now provide a comprehensive overview of everything related to FastMCP:

# FastMCP Analysis

## Overview

FastMCP is a high-level, ergonomic interface for building MCP (Model Context Protocol) servers in Python. It provides a more developer-friendly API on top of the lower-level MCP implementation.

## Core Components

### 1. FastMCP Server Class

The main `FastMCP` class in `src/mcp/server/fastmcp/server.py` is the central component that:
- Manages server configuration and settings
- Handles tool registration and execution
- Manages resources and resource templates
- Handles prompt registration and execution
- Provides transport mechanisms (stdio, SSE)
- Manages server lifecycle

### 2. Context Class

The `Context` class provides a clean interface to MCP's RequestContext functionality:
- Logging (debug, info, warning, error)
- Progress reporting
- Resource access
- Request information (client_id, request_id)

### 3. Tools System

Tools are functions that can be called by the AI model:
- Registered via `@mcp.tool()` decorator or `mcp.add_tool()`
- Automatically validates inputs and outputs using type annotations
- Supports Pydantic models for complex parameter validation

### 4. Resources System

Resources provide data to the AI model:
- Static resources via `@mcp.resource("uri")` decorator
- Dynamic resource templates via `@mcp.resource("uri/{param}")` decorator
- Resource management through the ResourceManager class

### 5. Prompts System

Prompts allow the AI model to request text generation:
- Registered via `@mcp.prompt()` decorator
- Managed by the PromptManager class

### 6. Utilities

Supporting utilities include:
- `Image` class for handling image data
- Function metadata extraction
- Logging configuration
- Custom exceptions

## Directory Structure

```
src/mcp/server/fastmcp/
├── __init__.py           # Package exports
├── exceptions.py         # Custom exceptions
├── server.py             # Main FastMCP implementation
├── prompts/              # Prompt system
│   ├── __init__.py
│   ├── base.py           # Base prompt classes
│   ├── manager.py        # Prompt manager
│   └── prompt_manager.py
├── resources/            # Resource system
│   ├── __init__.py
│   ├── base.py           # Base resource classes
│   ├── resource_manager.py
│   ├── templates.py      # Resource templates
│   └── types.py          # Resource types
├── tools/                # Tool system
│   ├── __init__.py
│   ├── base.py           # Base tool classes
│   └── tool_manager.py   # Tool manager
└── utilities/            # Utility functions
    ├── __init__.py
    ├── func_metadata.py  # Function metadata extraction
    ├── logging.py        # Logging utilities
    └── types.py          # Common types (Image)
```

## Testing Infrastructure

FastMCP includes a comprehensive test suite that ensures reliability and correctness:

### Test Directory Structure

```
tests/
├── server/
│   └── fastmcp/
│       ├── test_server.py             # Main FastMCP server tests
│       ├── test_tool_manager.py       # Tool registration and execution tests
│       ├── test_func_metadata.py      # Function metadata extraction tests
│       ├── test_parameter_descriptions.py # Parameter description tests
│       ├── servers/
│       │   └── test_file_server.py    # File server implementation tests
│       ├── resources/
│       │   ├── test_resource_manager.py
│       │   ├── test_resource_template.py
│       │   ├── test_resources.py
│       │   ├── test_file_resources.py
│       │   └── test_function_resources.py
│       └── prompts/
│           ├── test_base.py
│           └── test_manager.py
└── test_examples.py                   # Tests for example servers
```

### Testing Methodology

- **Pytest Framework**: Uses pytest for all tests with fixtures for setup/teardown
- **Memory-Based Sessions**: Tests use in-memory client-server sessions for isolation
- **Type Checking**: All test files include proper type annotations
- **Comprehensive Coverage**: Tests cover normal operation, edge cases, and error conditions
- **Integration Testing**: Example servers are tested for end-to-end functionality

### Key Test Areas

1. **Server Functionality**:
   - Server creation and configuration
   - Tool registration and execution
   - Resource registration and access
   - Prompt registration and execution
   - Unicode and non-ASCII character handling

2. **Tool Manager**:
   - Basic and complex function registration
   - Async function support
   - Pydantic model validation
   - Parameter validation and error handling
   - Context injection

3. **Function Metadata**:
   - Complex type handling (Annotated, Union types)
   - Pydantic model integration
   - Default value handling
   - Parameter description extraction

4. **Resources**:
   - Static and template-based resources
   - Resource content validation
   - URI template parameter extraction
   - File-based resources

5. **Prompts**:
   - Prompt registration and execution
   - Message construction
   - Embedded resources in prompts

6. **Example Servers**:
   - Validation of example implementations
   - End-to-end functionality testing
   - Real-world usage patterns

## Usage Examples

The repository contains several examples in the `examples/fastmcp/` directory:

1. **Simple Echo Server** (`echo.py`):
   - Basic tool, resource, and prompt registration
   - Minimal implementation

2. **Complex Inputs** (`complex_inputs.py`):
   - Demonstrates Pydantic model validation
   - Shows nested model structures

3. **Memory** (`memory.py`):
   - Demonstrates persistent state
   - Uses local filesystem for storage

4. **Screenshot** (`screenshot.py`):
   - Shows how to work with images
   - Uses the Image class for handling image data

5. **Parameter Descriptions** (`parameter_descriptions.py`):
   - Shows how to add detailed parameter descriptions

All examples are tested in `tests/test_examples.py` to ensure they work correctly and demonstrate proper usage patterns.

## Key Features

1. **Decorator-based API**:
   ```python
   @mcp.tool()
   def my_tool(param: str) -> str:
       return f"Processed: {param}"
   ```

2. **Type Validation**:
   - Uses Python type annotations
   - Supports Pydantic models for complex validation
   - Handles Annotated types with Field for parameter descriptions
   - Supports Union types (e.g., `list[str] | str`)

3. **Resource Templates**:
   ```python
   @mcp.resource("data://{id}")
   def get_data(id: str) -> str:
       return f"Data for {id}"
   ```

4. **Context Injection**:
   ```python
   @mcp.tool()
   def log_tool(message: str, ctx: Context) -> str:
       ctx.info(f"Processing: {message}")
       return "Logged"
   ```

5. **Image Handling**:
   ```python
   @mcp.tool()
   def get_image() -> Image:
       return Image(path="path/to/image.png")
   ```

6. **Multiple Transport Options**:
   - stdio (default)
   - SSE (Server-Sent Events)

7. **Advanced Features**:
   - Unicode and non-ASCII character support
   - Async function support
   - Comprehensive error handling
   - Progress reporting

## Configuration

FastMCP can be configured via:
- Constructor parameters
- Environment variables with `FASTMCP_` prefix
- `.env` file

## Best Practices (from CONTRIBUTING.md)

1. **Server Naming**:
   - The server name in `FastMCP("name")` must match the key in the `mcpServers` object in `.cursor/mcp.json`

2. **Dependencies**:
   - Specify dependencies in the FastMCP constructor:
   ```python
   mcp = FastMCP("My Server", dependencies=["pandas", "numpy"])
   ```

3. **Testing**:
   - Test servers using the MCP Inspector or direct invocation
   - Write comprehensive tests for custom servers
   - Test edge cases and error conditions
   - Ensure proper type annotations in tests

## Conclusion

FastMCP provides a high-level, developer-friendly API for building MCP servers in Python. It handles the low-level details of the MCP protocol while providing a clean, type-safe interface for defining tools, resources, and prompts. The framework is designed to be extensible and customizable, with support for various transport mechanisms and configuration options.

The extensive test suite ensures reliability and correctness, while the example servers demonstrate best practices for different use cases. The framework is well-tested for a variety of scenarios, including complex type handling, async functions, and error conditions, making it a robust foundation for building MCP servers.

## Additional Information from README.md

### Running Your Server

#### Development Mode

The fastest way to test and debug your server is with the MCP Inspector:

```bash
mcp dev server.py

# Add dependencies
mcp dev server.py --with pandas --with numpy

# Mount local code
mcp dev server.py --with-editable .
```

#### Claude Desktop Integration

Once your server is ready, install it in Claude Desktop:

```bash
mcp install server.py

# Custom name
mcp install server.py --name "My Analytics Server"

# Environment variables
mcp install server.py -v API_KEY=abc123 -v DB_URL=postgres://...
mcp install server.py -f .env
```

#### Direct Execution

For advanced scenarios like custom deployments:

```python
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("My App")

if __name__ == "__main__":
    mcp.run()
```

Run it with:
```bash
python server.py
# or
mcp run server.py
```

### Lifespan Support

FastMCP supports application lifecycle management through the lifespan API:

```python
from dataclasses import dataclass
from typing import AsyncIterator
from contextlib import asynccontextmanager
from mcp.server.fastmcp import FastMCP

@dataclass
class AppContext:
    db: Database  # Replace with your actual DB type

@asynccontextmanager
async def app_lifespan(server: FastMCP) -> AsyncIterator[AppContext]:
    """Manage application lifecycle with type-safe context"""
    try:
        # Initialize on startup
        await db.connect()
        yield AppContext(db=db)
    finally:
        # Clean up on shutdown
        await db.disconnect()

# Pass lifespan to server
mcp = FastMCP("My App", lifespan=app_lifespan)

# Access type-safe lifespan context in tools
@mcp.tool()
def query_db(ctx: Context) -> str:
    """Tool that uses initialized resources"""
    db = ctx.request_context.lifespan_context["db"]
    return db.query()
```

### Example Implementations

#### SQLite Explorer

A more complex example showing database integration:

```python
from mcp.server.fastmcp import FastMCP
import sqlite3

mcp = FastMCP("SQLite Explorer")

@mcp.resource("schema://main")
def get_schema() -> str:
    """Provide the database schema as a resource"""
    conn = sqlite3.connect("database.db")
    schema = conn.execute(
        "SELECT sql FROM sqlite_master WHERE type='table'"
    ).fetchall()
    return "\n".join(sql[0] for sql in schema if sql[0])

@mcp.tool()
def query_data(sql: str) -> str:
    """Execute SQL queries safely"""
    conn = sqlite3.connect("database.db")
    try:
        result = conn.execute(sql).fetchall()
        return "\n".join(str(row) for row in result)
    except Exception as e:
        return f"Error: {str(e)}"
```

### MCP Primitives

The MCP protocol defines three core primitives that servers can implement:

| Primitive | Control               | Description                                         | Example Use                  |
|-----------|-----------------------|-----------------------------------------------------|------------------------------|
| Prompts   | User-controlled       | Interactive templates invoked by user choice        | Slash commands, menu options |
| Resources | Application-controlled| Contextual data managed by the client application   | File contents, API responses |
| Tools     | Model-controlled      | Functions exposed to the LLM to take actions        | API calls, data updates      |

### Server Capabilities

MCP servers declare capabilities during initialization:

| Capability  | Feature Flag                 | Description                        |
|-------------|------------------------------|------------------------------------|
| `prompts`   | `listChanged`                | Prompt template management         |
| `resources` | `subscribe`<br/>`listChanged`| Resource exposure and updates      |
| `tools`     | `listChanged`                | Tool discovery and execution       |
| `logging`   | -                            | Server logging configuration       |
| `completion`| -                            | Argument completion suggestions    |

### Low-Level Server

For more control, you can use the low-level server implementation directly:

```python
from contextlib import asynccontextmanager
from typing import AsyncIterator
from mcp.server.lowlevel import Server, NotificationOptions
from mcp.server.models import InitializationOptions
import mcp.server.stdio
import mcp.types as types

@asynccontextmanager
async def server_lifespan(server: Server) -> AsyncIterator[dict]:
    """Manage server startup and shutdown lifecycle."""
    try:
        # Initialize resources on startup
        await db.connect()
        yield {"db": db}
    finally:
        # Clean up on shutdown
        await db.disconnect()

# Create a server instance with lifespan
server = Server("example-server", lifespan=server_lifespan)

@server.list_prompts()
async def handle_list_prompts() -> list[types.Prompt]:
    return [
        types.Prompt(
            name="example-prompt",
            description="An example prompt template",
            arguments=[
                types.PromptArgument(
                    name="arg1",
                    description="Example argument",
                    required=True
                )
            ]
        )
    ]

@server.get_prompt()
async def handle_get_prompt(
    name: str,
    arguments: dict[str, str] | None
) -> types.GetPromptResult:
    if name != "example-prompt":
        raise ValueError(f"Unknown prompt: {name}")

    return types.GetPromptResult(
        description="Example prompt",
        messages=[
            types.PromptMessage(
                role="user",
                content=types.TextContent(
                    type="text",
                    text="Example prompt text"
                )
            )
        ]
    )

async def run():
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="example",
                server_version="0.1.0",
                capabilities=server.get_capabilities(
                    notification_options=NotificationOptions(),
                    experimental_capabilities={},
                )
            )
        )

if __name__ == "__main__":
    import asyncio
    asyncio.run(run())
```

### Writing MCP Clients

The SDK provides a high-level client interface for connecting to MCP servers:

```python
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

# Create server parameters for stdio connection
server_params = StdioServerParameters(
    command="python", # Executable
    args=["example_server.py"], # Optional command line arguments
    env=None # Optional environment variables
)

# Optional: create a sampling callback
async def handle_sampling_message(message: types.CreateMessageRequestParams) -> types.CreateMessageResult:
    return types.CreateMessageResult(
        role="assistant",
        content=types.TextContent(
            type="text",
            text="Hello, world! from model",
        ),
        model="gpt-3.5-turbo",
        stopReason="endTurn",
    )

async def run():
    async with stdio_client(server_params) as (read, write):
        async with ClientSession(read, write, sampling_callback=handle_sampling_message) as session:
            # Initialize the connection
            await session.initialize()

            # List available prompts
            prompts = await session.list_prompts()

            # Get a prompt
            prompt = await session.get_prompt("example-prompt", arguments={"arg1": "value"})

            # List available resources
            resources = await session.list_resources()

            # List available tools
            tools = await session.list_tools()

            # Read a resource
            content, mime_type = await session.read_resource("file://some/path")

            # Call a tool
            result = await session.call_tool("tool-name", arguments={"arg1": "value"})

if __name__ == "__main__":
    import asyncio
    asyncio.run(run())
```
