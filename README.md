# MCP Todo Connector

A Model Context Protocol (MCP) server that provides todo management capabilities for AI assistants and applications.

## Overview

The MCP Todo Connector enables AI assistants to create, read, update, and delete todo items through a standardized interface. This server implements the Model Context Protocol specification, allowing seamless integration with various AI platforms and applications.

## Features

- ✅ **CRUD Operations**: Create, read, update, and delete todo items
- 📝 **Rich Metadata**: Support for priorities, due dates, categories, and tags
- 🔍 **Search & Filter**: Advanced querying capabilities
- 💾 **Flexible Storage**: File-based or database storage options
- 🔒 **Authentication**: Optional API key authentication
- 📊 **Logging**: Comprehensive logging and monitoring
- 🚀 **Easy Setup**: Automated setup scripts for multiple platforms

## Quick Start

### Prerequisites

- Node.js 18.0.0 or higher
- npm or yarn package manager

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/CloudBoostUP/mcp-todo-connector.git
   cd mcp-todo-connector
   ```

2. **Run the setup script:**
   
   **Linux/macOS:**
   ```bash
   chmod +x scripts/setup.sh
   ./scripts/setup.sh
   ```
   
   **Windows:**
   ```powershell
   .\scripts\setup.ps1
   ```

3. **Configure environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your preferred settings
   ```

4. **Start the server:**
   
   **Linux/macOS:**
   ```bash
   ./scripts/start.sh
   ```
   
   **Windows:**
   ```powershell
   .\scripts\start.ps1
   ```

## Configuration

The server can be configured through environment variables. Copy `.env.example` to `.env` and modify as needed:

```env
# Server Configuration
MCP_SERVER_NAME=mcp-todo-connector
PORT=3000

# Storage Configuration
TODO_STORAGE_TYPE=file
TODO_STORAGE_PATH=./data/todos.json

# Authentication (optional)
API_KEY=your-api-key-here

# Logging
LOG_LEVEL=info
```

## MCP Integration

### Connecting to AI Assistants

This server implements the Model Context Protocol, making it compatible with various AI assistants and applications that support MCP.

#### Example Configuration

```json
{
  "mcpServers": {
    "todo-connector": {
      "command": "node",
      "args": ["path/to/mcp-todo-connector/index.js"],
      "env": {
        "TODO_STORAGE_PATH": "./todos.json"
      }
    }
  }
}
```

### Available Tools

The server provides the following MCP tools:

- `create_todo`: Create a new todo item
- `list_todos`: List all todo items with optional filtering
- `get_todo`: Get a specific todo item by ID
- `update_todo`: Update an existing todo item
- `delete_todo`: Delete a todo item
- `search_todos`: Search todos by text, tags, or categories

### Available Resources

- `todos://all`: Access to all todo items
- `todos://categories`: List of all categories
- `todos://tags`: List of all tags

## API Reference

### Todo Item Structure

```json
{
  "id": "unique-id",
  "title": "Todo title",
  "description": "Detailed description",
  "completed": false,
  "priority": "high|medium|low",
  "dueDate": "2024-12-31T23:59:59Z",
  "category": "work",
  "tags": ["urgent", "meeting"],
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

### Tool Examples

#### Create Todo
```json
{
  "name": "create_todo",
  "arguments": {
    "title": "Review project proposal",
    "description": "Review the Q4 project proposal document",
    "priority": "high",
    "dueDate": "2024-12-15T17:00:00Z",
    "category": "work",
    "tags": ["review", "urgent"]
  }
}
```

#### List Todos
```json
{
  "name": "list_todos",
  "arguments": {
    "completed": false,
    "category": "work",
    "priority": "high"
  }
}
```

## Development

### Project Structure

```
mcp-todo-connector/
├─ package.json          # Project dependencies and scripts
├─ .env.example         # Environment configuration template
├─ .gitignore          # Git ignore rules
├─ README.md           # This file
├─ index.js            # Main server entry point
├─ src/                # Source code
│  ├─ server.js        # MCP server implementation
│  ├─ storage/         # Storage adapters
│  └─ utils/           # Utility functions
├─ data/               # Default data directory
├─ tests/              # Test files
└─ scripts/            # Setup and utility scripts
   ├─ setup.sh         # Linux/macOS setup script
   ├─ setup.ps1        # Windows setup script
   ├─ start.sh         # Linux/macOS start script
   ├─ start.ps1        # Windows start script
   └─ auth-note.md     # Authentication setup notes
```

### Running Tests

```bash
npm test
```

### Development Mode

```bash
npm run dev
```

## Authentication

For authentication setup and configuration details, see [scripts/auth-note.md](scripts/auth-note.md).

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📧 **Email**: support@cloudboostup.com
- 🐛 **Issues**: [GitHub Issues](https://github.com/CloudBoostUP/mcp-todo-connector/issues)
- 📖 **Documentation**: [Wiki](https://github.com/CloudBoostUP/mcp-todo-connector/wiki)

## Acknowledgments

- [Model Context Protocol](https://modelcontextprotocol.io/) for the specification
- [Anthropic](https://www.anthropic.com/) for MCP development
- CloudBoostUP team for project support

---

**Made with ❤️ by CloudBoostUP**