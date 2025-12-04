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
# PART 1: FL Studio Setup
# ============================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  PART 1: Setting Up FL Studio"
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
# PART 2: Start Auto-Trigger Watcher
# ============================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  PART 2: Starting Auto-Trigger Watcher"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

if [ ! -f "$SCRIPT_DIR/run_auto_trigger.sh" ]; then
    echo "❌ run_auto_trigger.sh not found"
    exit 1
fi

chmod +x "$SCRIPT_DIR/run_auto_trigger.sh"
"$SCRIPT_DIR/run_auto_trigger.sh"

# ============================================================
# Summary
# ============================================================

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   FL Studio Setup Complete! 🎉                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo
echo "✨ FL Studio scripts and auto-trigger are ready!"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Installation Workflow:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "1️⃣  Install prerequisites:"
echo "   ./install_prerequisites.sh"
echo
echo "2️⃣  Register with Claude Code:"
echo "   ./install_mcp_for_claude.sh"
echo
echo "3️⃣  (Optional) Generate Gemini config:"
echo "   ./install_mcp_for_gemini.sh"
echo
echo "4️⃣  Set up FL Studio and start auto-trigger:"
echo "   ./install_and_run.sh"
echo
echo "5️⃣  Or just start the auto-trigger watcher:"
echo "   ./run_auto_trigger.sh"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Management Commands:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "📄 View logs:           tail -f $SCRIPT_DIR/auto_trigger.log"
echo "🔄 Restart auto-trigger: ./run_auto_trigger.sh"
echo
