#!/bin/bash
# FL Studio MCP - Clean Installation Script
# This script removes all installed components for a fresh installation test

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   FL Studio MCP - Clean Installation                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo
echo "⚠️  This will remove all FL Studio MCP components:"
echo "   • Virtual environment (.venv)"
echo "   • uv package manager"
echo "   • Auto-trigger process and logs"
echo "   • FL Studio JSON files"
echo "   • MCP server registration from Claude Code"
echo

# Ask for confirmation
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Starting cleanup..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Define paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FL_SCRIPTS_DIR="$HOME/Documents/Image-Line/FL Studio/Settings/Piano roll scripts"
PID_FILE="$SCRIPT_DIR/.auto_trigger.pid"

# ============================================================
# STEP 1: Stop auto-trigger process
# ============================================================

echo "1️⃣  Stopping auto-trigger process..."

if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "   Stopping process (PID: $OLD_PID)..."
        kill "$OLD_PID" 2>/dev/null || true
        sleep 1
        echo "   ✅ Process stopped"
    else
        echo "   ℹ️  Process not running"
    fi
else
    echo "   ℹ️  No PID file found"
fi

# ============================================================
# STEP 2: Remove local files
# ============================================================

echo
echo "2️⃣  Removing local files..."

# Remove virtual environment
if [ -d "$SCRIPT_DIR/.venv" ]; then
    echo "   Removing .venv..."
    rm -rf "$SCRIPT_DIR/.venv"
    echo "   ✅ Virtual environment removed"
else
    echo "   ℹ️  No virtual environment found"
fi

# Remove PID file
if [ -f "$PID_FILE" ]; then
    echo "   Removing PID file..."
    rm -f "$PID_FILE"
    echo "   ✅ PID file removed"
fi

# Remove log file
if [ -f "$SCRIPT_DIR/auto_trigger.log" ]; then
    echo "   Removing log file..."
    rm -f "$SCRIPT_DIR/auto_trigger.log"
    echo "   ✅ Log file removed"
fi

# ============================================================
# STEP 3: Remove FL Studio files
# ============================================================

echo
echo "3️⃣  Removing FL Studio files..."

if [ -d "$FL_SCRIPTS_DIR" ]; then
    # Remove JSON files
    if ls "$FL_SCRIPTS_DIR"/mcp_*.json "$FL_SCRIPTS_DIR"/piano_roll_state.json 2>/dev/null; then
        echo "   Removing JSON files..."
        rm -f "$FL_SCRIPTS_DIR/mcp_request.json"
        rm -f "$FL_SCRIPTS_DIR/mcp_response.json"
        rm -f "$FL_SCRIPTS_DIR/piano_roll_state.json"
        echo "   ✅ JSON files removed"
    else
        echo "   ℹ️  No JSON files found"
    fi

    # Note: We keep ComposeWithLLM.pyscript in place
    # It will be overwritten by fresh install
    if [ -f "$FL_SCRIPTS_DIR/ComposeWithLLM.pyscript" ]; then
        echo "   ℹ️  ComposeWithLLM.pyscript will be overwritten on reinstall"
    fi
else
    echo "   ⚠️  FL Studio scripts directory not found"
    echo "      Expected: $FL_SCRIPTS_DIR"
fi

# ============================================================
# STEP 4: Unregister MCP server
# ============================================================

echo
echo "4️⃣  Unregistering MCP server from Claude Code..."

if command -v claude &> /dev/null; then
    if claude mcp remove fl-studio 2>/dev/null; then
        echo "   ✅ MCP server unregistered"
    else
        echo "   ℹ️  MCP server not registered or already removed"
    fi
else
    echo "   ⚠️  Claude CLI not found, skipping MCP unregistration"
fi

# ============================================================
# Summary
# ============================================================

echo
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Cleanup Complete! ✨                                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo
echo "✅ All components removed. You can now run a fresh installation:"
echo
echo "   ./install_and_run.sh"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
