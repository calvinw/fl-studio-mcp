#!/bin/bash
# Stop FL Studio Auto-Trigger Script
# Finds and kills any running fl_studio_auto_trigger.py processes

echo "🛑 Stopping FL Studio Auto-Trigger..."

# Find PIDs of the auto-trigger script
PIDS=$(pgrep -f "fl_studio_auto_trigger.py")

if [ -z "$PIDS" ]; then
    echo "ℹ️  No auto-trigger process found running"
    exit 0
fi

# Kill each process
for PID in $PIDS; do
    echo "   Killing process $PID..."
    kill "$PID" 2>/dev/null
done

# Wait a moment and verify
sleep 0.5

# Check if any are still running
REMAINING=$(pgrep -f "fl_studio_auto_trigger.py")
if [ -z "$REMAINING" ]; then
    echo "✅ Auto-trigger stopped successfully"
else
    echo "⚠️  Some processes still running, force killing..."
    pkill -9 -f "fl_studio_auto_trigger.py"
    echo "✅ Force killed remaining processes"
fi
