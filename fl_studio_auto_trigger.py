#!/usr/bin/env python3
"""
FL Studio Auto-Trigger Script

Watches the mcp_request.json file and automatically triggers the FL Studio
script when Claude sends new notes via MCP.

Requirements:
- pip install pynput

Usage:
1. Open FL Studio piano roll
2. Run ComposeWithLLM script ONCE: Tools → Scripting → ComposeWithLLM
3. Run this script: python fl_studio_auto_trigger.py
4. Talk to Claude - notes will appear automatically!

How it works:
- Monitors mcp_request.json for changes
- When requests are detected, sends Ctrl+Alt+Y
- Ctrl+Alt+Y re-runs the last FL Studio script (ComposeWithLLM)
- Notes are applied and state is updated
"""

import time
import os
import json
import sys
from pathlib import Path

try:
    from pynput.keyboard import Key, Controller
except ImportError:
    print("❌ Error: pynput not installed")
    print("📦 Install with: pip install pynput")
    sys.exit(1)


# File paths
REQUEST_FILE = Path.home() / "Documents/Image-Line/FL Studio/Settings/Piano roll scripts/mcp_request.json"

# Keyboard controller
keyboard = Controller()

# State tracking
last_mtime = 0
trigger_count = 0


def has_pending_requests():
    """Check if there are requests to process"""
    if not REQUEST_FILE.exists():
        return False

    try:
        with open(REQUEST_FILE, 'r') as f:
            content = json.load(f)
            return isinstance(content, list) and len(content) > 0
    except:
        return False


def send_trigger():
    """Use AppleScript to click the Run last script menu item"""
    global trigger_count
    import subprocess

    print(f"   🎹 Triggering FL Studio via menu click...")

    # AppleScript to activate detached piano roll window and send keystroke
    applescript = '''
    tell application "System Events"
        tell process "OsxFL"
            set frontmost to true
            delay 0.5
            -- Focus the detached piano roll window (window 1)
            perform action "AXRaise" of window 1
            delay 0.7
            -- Send the keystroke
            keystroke "y" using {command down, option down}
        end tell
    end tell
    '''

    try:
        result = subprocess.run(
            ['osascript', '-e', applescript],
            timeout=5,
            capture_output=True,
            text=True
        )

        if result.returncode == 0:
            trigger_count += 1
            print(f"   ✅ Menu clicked successfully")
        else:
            print(f"   ⚠️  AppleScript error: {result.stderr}")
            trigger_count += 1

    except subprocess.TimeoutExpired:
        print(f"   ⚠️  AppleScript timeout")
    except Exception as e:
        print(f"   ❌ Error: {e}")


def main():
    """Main watch loop"""
    global last_mtime

    print("🎹 FL Studio MCP Auto-Trigger")
    print("=" * 50)
    print(f"📂 Watching: {REQUEST_FILE}")
    print("⌨️  Trigger: Cmd+Opt+Y (macOS)")
    print("🛑 Stop: Press Ctrl+C")
    print()

    # Check if request file exists
    if not REQUEST_FILE.exists():
        print("⚠️  Warning: Request file doesn't exist yet")
        print("   It will be created when you run the FL Studio script")
        print()

    # Initialize last modification time
    if REQUEST_FILE.exists():
        last_mtime = REQUEST_FILE.stat().st_mtime

    print("✅ Auto-trigger is running...")
    print("💬 Talk to Claude to send notes!")
    print()

    try:
        while True:
            if REQUEST_FILE.exists():
                current_mtime = REQUEST_FILE.stat().st_mtime

                # Check if file was modified
                if current_mtime > last_mtime:
                    last_mtime = current_mtime

                    # Check if there are actual requests
                    if has_pending_requests():
                        print(f"🔔 New requests detected! Triggering FL Studio... (#{trigger_count + 1})")
                        send_trigger()

                        # Wait a moment for FL Studio to process
                        time.sleep(0.3)

                        print(f"   ✅ Trigger sent at {time.strftime('%H:%M:%S')}")

            # Poll every 300ms for responsive triggering
            time.sleep(0.3)

    except KeyboardInterrupt:
        print()
        print("=" * 50)
        print(f"🛑 Auto-trigger stopped")
        print(f"📊 Total triggers sent: {trigger_count}")
        print()
        sys.exit(0)


if __name__ == "__main__":
    main()
