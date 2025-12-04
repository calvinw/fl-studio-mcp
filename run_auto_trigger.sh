#!/bin/bash
# FL Studio MCP - Auto-Trigger Watcher
# Starts the auto-trigger watcher for live piano roll updates

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   FL Studio Auto-Trigger Watcher                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo

# Define paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_PYTHON="$SCRIPT_DIR/.venv/bin/python"
AUTO_TRIGGER_SCRIPT="$SCRIPT_DIR/fl_studio_auto_trigger.py"
PID_FILE="$SCRIPT_DIR/.auto_trigger.pid"

# Check if auto-trigger script exists
if [ ! -f "$AUTO_TRIGGER_SCRIPT" ]; then
    echo "❌ Auto-trigger script not found at $AUTO_TRIGGER_SCRIPT"
    exit 1
fi

echo "✅ Auto-trigger script found"
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
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Management Commands:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "📄 View logs:           tail -f $SCRIPT_DIR/auto_trigger.log"
echo "🛑 Stop auto-trigger:   kill $AUTO_TRIGGER_PID"
echo "🔄 Restart watcher:     ./run_auto_trigger.sh"
echo
