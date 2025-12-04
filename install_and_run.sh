#!/bin/bash
# FL Studio MCP - Unified Installation and Auto-Trigger Script
# This script installs the MCP server, sets up FL Studio, and starts the auto-trigger watcher

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   FL Studio MCP - Installation & Auto-Trigger             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo

# Define paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FL_SCRIPTS_DIR="$HOME/Documents/Image-Line/FL Studio/Settings/Piano roll scripts"
VENV_PYTHON="$SCRIPT_DIR/.venv/bin/python"
SERVER_SCRIPT="$SCRIPT_DIR/fl_studio_mcp_server.py"
AUTO_TRIGGER_SCRIPT="$SCRIPT_DIR/fl_studio_auto_trigger.py"
PID_FILE="$SCRIPT_DIR/.auto_trigger.pid"

# ============================================================
# PART 1: MCP Server Installation
# ============================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  PART 1: Installing MCP Server"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Check if uv is installed, install if needed
if ! command -v uv &> /dev/null; then
    echo "📦 uv not found, installing automatically..."

    # Detect OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        echo "   Detected macOS, installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        echo "   Detected Linux, installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        # Windows
        echo "   Detected Windows, installing uv..."
        powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
    else
        echo "❌ Unsupported OS: $OSTYPE"
        echo "   Please install uv manually: https://docs.astral.sh/uv/"
        exit 1
    fi

    # Add uv to PATH for current session
    export PATH="$HOME/.cargo/bin:$PATH"

    # Verify installation
    if ! command -v uv &> /dev/null; then
        echo "❌ uv installation failed"
        echo "   Please install manually: https://docs.astral.sh/uv/"
        exit 1
    fi

    echo "✅ uv installed successfully"
else
    echo "✅ uv is already installed"
fi

# Check if virtual environment exists, create if needed
if [ ! -f "$VENV_PYTHON" ]; then
    echo "📦 Virtual environment not found, creating with uv sync..."

    # Run uv sync to create venv and install dependencies
    if uv sync; then
        echo "✅ Virtual environment created successfully"
    else
        echo "❌ Failed to create virtual environment"
        exit 1
    fi
else
    echo "✅ Virtual environment found"
fi

# Check if server script exists
if [ ! -f "$SERVER_SCRIPT" ]; then
    echo "❌ Server script not found at $SERVER_SCRIPT"
    exit 1
fi

echo "✅ Server script found"

# Register the MCP server with Claude Code
echo "📝 Registering MCP server with Claude Code..."
if claude mcp add --transport stdio fl-studio -- "$VENV_PYTHON" "$SERVER_SCRIPT"; then
    echo "✅ MCP server registered successfully!"
else
    echo "⚠️  MCP server registration failed or already exists"
    echo "   Continuing with FL Studio setup..."
fi
echo

# ============================================================
# PART 2: FL Studio Setup
# ============================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  PART 2: Setting Up FL Studio"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

echo "📂 FL Studio scripts directory: $FL_SCRIPTS_DIR"

# Check if FL Studio scripts directory exists
if [ ! -d "$FL_SCRIPTS_DIR" ]; then
    echo "❌ FL Studio scripts directory not found!"
    echo "   Expected: $FL_SCRIPTS_DIR"
    echo
    echo "   Please make sure FL Studio is installed."
    echo "   You may need to create this directory manually."
    exit 1
fi

echo "✅ FL Studio scripts directory found"

# Copy ComposeWithLLM.pyscript
echo "📋 Copying ComposeWithLLM.pyscript to FL Studio..."
if cp "$SCRIPT_DIR/ComposeWithLLM.pyscript" "$FL_SCRIPTS_DIR/"; then
    echo "✅ ComposeWithLLM.pyscript installed"
else
    echo "❌ Failed to copy ComposeWithLLM.pyscript"
    exit 1
fi

# Create initial JSON files
echo "📝 Creating initial JSON files..."
echo "[]" > "$FL_SCRIPTS_DIR/mcp_request.json"
echo "{}" > "$FL_SCRIPTS_DIR/mcp_response.json"
echo "{\"ppq\": 96, \"noteCount\": 0, \"notes\": []}" > "$FL_SCRIPTS_DIR/piano_roll_state.json"
echo "✅ JSON files created"
echo

# ============================================================
# PART 3: Start Auto-Trigger Watcher
# ============================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  PART 3: Starting Auto-Trigger Watcher"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Check if auto-trigger is already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "⚠️  Auto-trigger already running (PID: $OLD_PID)"
        echo "   Stopping old instance..."
        kill "$OLD_PID" 2>/dev/null || true
        sleep 1
    fi
    rm -f "$PID_FILE"
fi

# Start auto-trigger in background
echo "🚀 Starting auto-trigger watcher in background..."
nohup "$VENV_PYTHON" "$AUTO_TRIGGER_SCRIPT" > "$SCRIPT_DIR/auto_trigger.log" 2>&1 &
AUTO_TRIGGER_PID=$!

# Save PID
echo "$AUTO_TRIGGER_PID" > "$PID_FILE"

# Wait a moment and verify it's running
sleep 1
if ps -p "$AUTO_TRIGGER_PID" > /dev/null 2>&1; then
    echo "✅ Auto-trigger running (PID: $AUTO_TRIGGER_PID)"
    echo "📄 Logs: $SCRIPT_DIR/auto_trigger.log"
else
    echo "❌ Auto-trigger failed to start"
    echo "📄 Check logs at: $SCRIPT_DIR/auto_trigger.log"
    exit 1
fi
echo

# ============================================================
# Summary
# ============================================================

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Installation Complete! 🎉                                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo
echo "✨ Everything is ready! Here's what's running:"
echo
echo "  • MCP Server: Registered with Claude Code"
echo "  • FL Studio Script: ComposeWithLLM installed"
echo "  • Auto-Trigger: Running in background (PID: $AUTO_TRIGGER_PID)"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "1️⃣  Restart Claude Code to load the MCP server"
echo
echo "2️⃣  Open FL Studio and open a piano roll"
echo
echo "3️⃣  Run ComposeWithLLM ONCE to initialize:"
echo "   Tools → Scripting → ComposeWithLLM"
echo
echo "4️⃣  Talk to Claude - notes will appear automatically! ✨"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Management Commands:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "📄 View logs:           tail -f $SCRIPT_DIR/auto_trigger.log"
echo "🛑 Stop auto-trigger:   kill $AUTO_TRIGGER_PID"
echo "🔄 Restart this script: ./install_and_run.sh"
echo
