#!/bin/bash
# FL Studio MCP - Gemini CLI Registration
# Registers the MCP server with Gemini CLI

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   FL Studio MCP - Registering with Gemini CLI              ║"
echo "╚════════════════════════════════════════════════════════════╝"
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

# Check if gemini command is available
if ! command -v gemini &> /dev/null; then
    echo "❌ Gemini CLI not found"
    echo "   Please install Gemini CLI first: https://geminicli.com"
    exit 1
fi

echo "✅ Gemini CLI is installed"
echo

# Check if MCP server is already registered
echo "📝 Checking if MCP server is already registered..."
if gemini mcp list 2>/dev/null | grep -q "fl-studio-mcp"; then
    echo "⚠️  MCP server 'fl-studio-mcp' is already registered"
    echo "   Skipping registration"
else
    echo "   Not registered yet, adding now..."
    if gemini mcp add fl-studio-mcp "$VENV_PYTHON" "$SERVER_SCRIPT"; then
        echo "✅ MCP server registered successfully!"
    else
        echo "❌ MCP server registration failed"
        exit 1
    fi
fi

echo
echo "✅ Gemini CLI registration complete"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "1. Make sure FL Studio is set up by running:"
echo "   ./install_and_run.sh"
echo
echo "2. Then use Gemini CLI with FL Studio MCP tools!"
echo
