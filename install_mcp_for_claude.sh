#!/bin/bash
# FL Studio MCP - Claude Code Registration
# Registers the MCP server with Claude Code

set -e  # Exit on error

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Registering MCP Server with Claude Code"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Define paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_PYTHON="$SCRIPT_DIR/.venv/bin/python"
SERVER_SCRIPT="$SCRIPT_DIR/fl_studio_mcp_server.py"

# Check if server script exists
if [ ! -f "$SERVER_SCRIPT" ]; then
    echo "❌ Server script not found at $SERVER_SCRIPT"
    exit 1
fi

echo "✅ Server script found"
echo

# Check if MCP server is already registered
echo "📝 Checking if MCP server is already registered..."
if claude mcp list 2>/dev/null | grep -q "fl-studio-mcp"; then
    echo "⚠️  MCP server 'fl-studio-mcp' is already registered"
    echo "   Skipping registration"
else
    echo "   Not registered yet, adding now..."
    if claude mcp add --transport stdio fl-studio-mcp -- "$VENV_PYTHON" "$SERVER_SCRIPT"; then
        echo "✅ MCP server registered successfully!"
    else
        echo "❌ MCP server registration failed"
        exit 1
    fi
fi

echo
echo "✅ Claude Code registration complete"
echo
