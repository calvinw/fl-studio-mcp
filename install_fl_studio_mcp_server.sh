#!/bin/bash
# Install FL Studio MCP Server for Claude Code

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Paths relative to script directory
VENV_PYTHON="$SCRIPT_DIR/.venv/bin/python"
SERVER_SCRIPT="$SCRIPT_DIR/fl_studio_mcp_server.py"

# Check if virtual environment exists
if [ ! -f "$VENV_PYTHON" ]; then
    echo "Error: Virtual environment not found at $VENV_PYTHON"
    echo "Please run: python -m venv .venv && .venv/bin/pip install fastmcp"
    exit 1
fi

# Check if server script exists
if [ ! -f "$SERVER_SCRIPT" ]; then
    echo "Error: Server script not found at $SERVER_SCRIPT"
    exit 1
fi

# Register the MCP server with Claude Code
claude mcp add --transport stdio fl-studio -- "$VENV_PYTHON" "$SERVER_SCRIPT"

echo "FL Studio MCP server registered!"
echo ""
echo "Next steps:"
echo "1. Copy call_llm.pyscript to FL Studio scripts directory:"
echo "   cp call_llm.pyscript ~/Documents/Image-Line/FL\ Studio/Settings/Piano\ roll\ scripts/"
echo ""
echo "2. Restart Claude Code to load the MCP server"
echo ""
echo "3. In FL Studio, open Piano Roll and go to: Tools → Scripting → call_llm"
echo ""
echo "4. Ask Claude to add a chord!"
