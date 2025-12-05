#!/bin/bash
# FL Studio MCP - Codex CLI Registration
# Registers the MCP server with OpenAI Codex CLI

set -e  # Exit on error

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Registering MCP Server with Codex CLI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Define paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_PYTHON="$SCRIPT_DIR/.venv/bin/python"
SERVER_SCRIPT="$SCRIPT_DIR/fl_studio_mcp_server.py"
CODEX_CONFIG_DIR="$HOME/.codex"
CODEX_CONFIG_FILE="$CODEX_CONFIG_DIR/config.toml"

# Check if server script exists
if [ ! -f "$SERVER_SCRIPT" ]; then
    echo "❌ Server script not found at $SERVER_SCRIPT"
    exit 1
fi

echo "✅ Server script found"
echo

# Check if codex CLI is installed
if ! command -v codex &> /dev/null; then
    echo "❌ Codex CLI is not installed"
    echo "   Install it with: npm install -g @openai/codex"
    exit 1
fi

echo "✅ Codex CLI is installed"
echo

# Create config directory if it doesn't exist
if [ ! -d "$CODEX_CONFIG_DIR" ]; then
    echo "📁 Creating Codex config directory..."
    mkdir -p "$CODEX_CONFIG_DIR"
fi

# Check if config file exists and if server is already registered
if [ -f "$CODEX_CONFIG_FILE" ]; then
    if grep -q "\[mcp_servers.fl-studio-mcp\]" "$CODEX_CONFIG_FILE"; then
        echo "⚠️  MCP server 'fl-studio-mcp' is already registered in config.toml"
        echo "   Skipping registration"
        echo
        echo "✅ Codex CLI registration complete"
        echo
        exit 0
    fi
fi

# Try using the codex mcp add command first
echo "📝 Registering MCP server with Codex..."
if codex mcp add fl-studio-mcp -- "$VENV_PYTHON" "$SERVER_SCRIPT" 2>/dev/null; then
    echo "✅ MCP server registered successfully using codex mcp add!"
else
    # Fallback: manually add to config.toml
    echo "   codex mcp add failed, adding manually to config.toml..."

    # Create or append to config.toml
    if [ ! -f "$CODEX_CONFIG_FILE" ]; then
        echo "   Creating new config.toml..."
        cat > "$CODEX_CONFIG_FILE" << EOF
# Codex CLI Configuration
# https://developers.openai.com/codex/local-config/

[mcp_servers.fl-studio-mcp]
command = "$VENV_PYTHON"
args = ["$SERVER_SCRIPT"]
EOF
    else
        echo "   Appending to existing config.toml..."
        cat >> "$CODEX_CONFIG_FILE" << EOF

[mcp_servers.fl-studio-mcp]
command = "$VENV_PYTHON"
args = ["$SERVER_SCRIPT"]
EOF
    fi

    echo "✅ MCP server added to config.toml!"
fi

echo
echo "✅ Codex CLI registration complete"
echo
echo "To verify, run: codex mcp list"
echo "Or check: ~/.codex/config.toml"
echo
