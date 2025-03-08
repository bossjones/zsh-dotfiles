---
description: Anthropic Model Context Protocol (MCP) Specification Reference
globs: **/*.py, **/*.md, **/*.json
alwaysApply: false
---

# Anthropic Model Context Protocol (MCP) Reference

## Overview

The Model Context Protocol (MCP) is a standardized JSON-RPC 2.0 based communication protocol for interaction between LLM clients and servers. It enables structured communication for accessing resources, calling tools, and exchanging messages with LLMs.

## Core Concepts

### Protocol Structure

- JSON-RPC 2.0 based
- Bidirectional communication
- Request/response pattern with notifications
- Support for resource discovery and manipulation
- Support for prompt templates
- Support for tool invocation

### Communication Types

1. **Requests**: Messages that expect a response
   - Client → Server: `InitializeRequest`, `ListResourcesRequest`, `CallToolRequest`, etc.
   - Server → Client: `CreateMessageRequest`, `ListRootsRequest`, etc.

2. **Notifications**: Messages that do not expect a response
   - Client → Server: `InitializedNotification`, `RootsListChangedNotification`
   - Server → Client: `ResourceUpdatedNotification`, `LoggingMessageNotification`

3. **Results**: Responses to requests
   - Server → Client: `InitializeResult`, `ReadResourceResult`, `CallToolResult`
   - Client → Server: `CreateMessageResult`, `ListRootsResult`

## Protocol Flow

### Initialization

1. Client connects and sends `initialize` request with capabilities
2. Server responds with `InitializeResult` containing its capabilities
3. Client sends `notifications/initialized` to complete initialization

### Core Interactions

- Resource discovery and content retrieval
- Prompt retrieval and usage
- Tool invocation
- LLM sampling via client

### Termination

- Either side can terminate the connection

## Message Components

### Roles

- `user`: Represents the end user
- `assistant`: Represents the AI assistant

### Content Types

- `TextContent`: Text provided to or from an LLM
  ```json
  {
    "text": "Content string",
    "type": "text"
  }
  ```

- `ImageContent`: Image provided to or from an LLM
  ```json
  {
    "data": "base64-encoded-data",
    "mimeType": "image/png",
    "type": "image"
  }
  ```

- `EmbeddedResource`: Contents of a resource embedded in a prompt or result
  ```json
  {
    "resource": { /* TextResourceContents or BlobResourceContents */ },
    "type": "resource"
  }
  ```

## Resources

Resources represent data that the server can provide to the client.

### Resource Types

- `Resource`: A known resource the server can read
  ```json
  {
    "name": "example_resource",
    "uri": "mcp://example/resource",
    "description": "An example resource",
    "mimeType": "text/plain"
  }
  ```

- `ResourceTemplate`: A template for creating resource URIs
  ```json
  {
    "name": "template_example",
    "uriTemplate": "mcp://example/{param}",
    "description": "Template for example resources"
  }
  ```

- `TextResourceContents`: Text content of a resource
  ```json
  {
    "text": "Resource content",
    "uri": "mcp://example/resource",
    "mimeType": "text/plain"
  }
  ```

- `BlobResourceContents`: Binary content of a resource
  ```json
  {
    "blob": "base64-encoded-binary-data",
    "uri": "mcp://example/resource",
    "mimeType": "application/octet-stream"
  }
  ```

### Resource Operations

- `resources/list`: Get available resources
- `resources/templates/list`: Get available resource templates
- `resources/read`: Read a specific resource
- `resources/subscribe`: Subscribe to resource updates
- `resources/unsubscribe`: Unsubscribe from resource updates

## Prompts

Prompts represent templates for generating messages to an LLM.

### Prompt Components

- `Prompt`: A prompt or prompt template
  ```json
  {
    "name": "example_prompt",
    "description": "An example prompt",
    "arguments": [
      {
        "name": "arg1",
        "description": "First argument",
        "required": true
      }
    ]
  }
  ```

- `PromptArgument`: An argument for a prompt template
  ```json
  {
    "name": "arg_name",
    "description": "Argument description",
    "required": true
  }
  ```

- `PromptMessage`: A message in a prompt
  ```json
  {
    "role": "user",
    "content": { "text": "Message content", "type": "text" }
  }
  ```

### Prompt Operations

- `prompts/list`: Get available prompts
- `prompts/get`: Get a specific prompt
- `completion/complete`: Get completion options for an argument

## Tools

Tools represent functions that the client can call on the server.

### Tool Components

- `Tool`: Definition of a callable tool
  ```json
  {
    "name": "example_tool",
    "description": "An example tool",
    "inputSchema": {
      "type": "object",
      "properties": {
        "param1": { "type": "string" }
      },
      "required": ["param1"]
    }
  }
  ```

- `CallToolRequest`: Request to invoke a tool
  ```json
  {
    "method": "tools/call",
    "params": {
      "name": "example_tool",
      "arguments": {
        "param1": "value1"
      }
    }
  }
  ```

- `CallToolResult`: Result of a tool invocation
  ```json
  {
    "content": [
      { "text": "Tool result", "type": "text" }
    ],
    "isError": false
  }
  ```

### Tool Operations

- `tools/list`: Get available tools
- `tools/call`: Call a specific tool

## Sampling

Sampling allows the server to request LLM responses from the client.

### Sampling Components

- `CreateMessageRequest`: Request to sample an LLM
  ```json
  {
    "method": "sampling/createMessage",
    "params": {
      "messages": [
        {
          "role": "user",
          "content": { "text": "User message", "type": "text" }
        }
      ],
      "maxTokens": 1000
    }
  }
  ```

- `CreateMessageResult`: Result of sampling
  ```json
  {
    "role": "assistant",
    "content": { "text": "Assistant response", "type": "text" },
    "model": "model-name"
  }
  ```

- `SamplingMessage`: A message in a sampling request/result

- `ModelPreferences`: Preferences for model selection
  ```json
  {
    "intelligencePriority": 0.8,
    "speedPriority": 0.5,
    "costPriority": 0.3,
    "hints": [
      { "name": "claude-3-5-sonnet" }
    ]
  }
  ```

## Root Access

Roots allow servers to access specific directories or files.

### Root Components

- `Root`: A root directory or file
  ```json
  {
    "name": "example_root",
    "uri": "file:///path/to/directory"
  }
  ```

- `ListRootsRequest`: Request for available roots
  ```json
  {
    "method": "roots/list",
    "params": {}
  }
  ```

- `ListRootsResult`: Result containing available roots
  ```json
  {
    "roots": [
      { "name": "example_root", "uri": "file:///path/to/directory" }
    ]
  }
  ```

- `RootsListChangedNotification`: Notification of roots changes

## Progress Tracking

- `ProgressToken`: Token for associating notifications with requests
  ```json
  "token123"
  ```

- `ProgressNotification`: Notification of progress updates
  ```json
  {
    "method": "notifications/progress",
    "params": {
      "progressToken": "token123",
      "progress": 50,
      "total": 100
    }
  }
  ```

## Logging

- `LoggingLevel`: Severity level for log messages (debug, info, warning, etc.)
- `LoggingMessageNotification`: Notification of a log message
  ```json
  {
    "method": "notifications/message",
    "params": {
      "level": "info",
      "data": "Log message",
      "logger": "example-logger"
    }
  }
  ```
- `SetLevelRequest`: Request to set logging level

## Capabilities

Capabilities objects define features supported by clients and servers.

### Client Capabilities

```json
{
  "sampling": {},
  "roots": {
    "listChanged": true
  },
  "experimental": {
    "customCapability": {}
  }
}
```

### Server Capabilities

```json
{
  "resources": {
    "subscribe": true,
    "listChanged": true
  },
  "prompts": {
    "listChanged": true
  },
  "tools": {
    "listChanged": true
  },
  "logging": {},
  "experimental": {
    "customCapability": {}
  }
}
```

## Error Handling

MCP uses JSON-RPC error responses with standard error codes:

- `-32700`: Parse error
- `-32600`: Invalid request
- `-32601`: Method not found
- `-32602`: Invalid params
- `-32603`: Internal error
- `-32000` to `-32099`: Server error

Tool-specific errors are reported within the `CallToolResult` object with `isError: true`, not as protocol-level errors, allowing the LLM to see and handle them.

## JSON Schema Reference

### Key Schema Definitions

```json
{
  "Role": {
    "enum": ["assistant", "user"],
    "type": "string"
  },

  "TextContent": {
    "properties": {
      "text": { "type": "string" },
      "type": { "const": "text" }
    },
    "required": ["text", "type"]
  },

  "ImageContent": {
    "properties": {
      "data": { "format": "byte", "type": "string" },
      "mimeType": { "type": "string" },
      "type": { "const": "image" }
    },
    "required": ["data", "mimeType", "type"]
  },

  "EmbeddedResource": {
    "properties": {
      "resource": { /* TextResourceContents or BlobResourceContents */ },
      "type": { "const": "resource" }
    },
    "required": ["resource", "type"]
  }
}
```

## Implementation Guidelines

### Client Implementation

1. Initialize connection with server
2. Discover available resources, prompts, and tools
3. Handle resource updates and notifications
4. Support LLM sampling requests
5. Manage progress tracking and cancellations

### Server Implementation

1. Handle initialization with capabilities
2. Provide access to resources
3. Offer prompts and prompt templates
4. Implement tools for client invocation
5. Request LLM sampling when needed

## Versioning and Compatibility

- Protocol version is negotiated during initialization
- Clients and servers should specify supported versions
- Servers should respond with their preferred version
- Clients must disconnect if they cannot support the server's version

## Security Considerations

- Access control for resources
- Validation of tool inputs
- Human-in-the-loop for LLM sampling
- Proper handling of binary data

## References

- [Anthropic documentation](https://docs.anthropic.com/)
- [MCP GitHub repository](https://github.com/anthropics/anthropic-model-context-protocol)
- [RFC 6570 - URI Template](https://datatracker.ietf.org/doc/html/rfc6570)
- [JSON-RPC 2.0 Specification](https://www.jsonrpc.org/specification)
