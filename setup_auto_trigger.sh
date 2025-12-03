#!/bin/bash

# FL Studio MCP Auto-Trigger Setup Script
# This script installs the auto-trigger system for FL Studio

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   FL Studio MCP Auto-Trigger Setup                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo

# Define paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FL_SCRIPTS_DIR="$HOME/Documents/Image-Line/FL Studio/Settings/Piano roll scripts"

echo "📂 Source directory: $SCRIPT_DIR"
echo "🎹 FL Studio scripts directory: $FL_SCRIPTS_DIR"
echo

# Step 1: Check if FL Studio scripts directory exists
if [ ! -d "$FL_SCRIPTS_DIR" ]; then
    echo "❌ FL Studio scripts directory not found!"
    echo "   Expected: $FL_SCRIPTS_DIR"
    echo
    echo "   Please make sure FL Studio is installed."
    echo "   You may need to create this directory manually."
    exit 1
fi

echo "✅ FL Studio scripts directory found"
echo

# Step 2: Install pynput
echo "📦 Installing pynput (for keyboard automation)..."
if pip3 install pynput; then
    echo "✅ pynput installed successfully"
else
    echo "⚠️  pynput installation failed"
    echo "   You may need to install it manually:"
    echo "   pip3 install pynput"
fi
echo

# Step 3: Copy ComposeWithLLM.pyscript
echo "📋 Copying ComposeWithLLM.pyscript to FL Studio..."
if cp "$SCRIPT_DIR/ComposeWithLLM.pyscript" "$FL_SCRIPTS_DIR/"; then
    echo "✅ ComposeWithLLM.pyscript installed"
else
    echo "❌ Failed to copy ComposeWithLLM.pyscript"
    exit 1
fi
echo

# Step 4: All done
echo

# Step 5: Create initial JSON files
echo "📝 Creating initial JSON files..."
echo "[]" > "$FL_SCRIPTS_DIR/mcp_request.json"
echo "{}" > "$FL_SCRIPTS_DIR/mcp_response.json"
echo "{\"ppq\": 96, \"noteCount\": 0, \"notes\": []}" > "$FL_SCRIPTS_DIR/piano_roll_state.json"
echo "✅ JSON files created"
echo

# Summary
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Installation Complete! 🎉                                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo
echo "Next steps:"
echo
echo "1️⃣  Open FL Studio and open a piano roll"
echo
echo "2️⃣  Run the script ONCE to initialize it:"
echo "   Tools → Scripting → ComposeWithLLM"
echo
echo "3️⃣  Start the auto-trigger watcher:"
echo "   cd $SCRIPT_DIR"
echo "   python3 fl_studio_auto_trigger.py"
echo
echo "4️⃣  Talk to Claude - notes will appear automatically! ✨"
echo
echo "Tip: Press Ctrl+Alt+Y anytime to manually refresh the piano roll state"
echo
echo "Available modes:"
echo "  • ComposeWithLLM  - Auto mode (no dialog, instant apply)"
echo
