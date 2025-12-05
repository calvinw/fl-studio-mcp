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


def is_fl_studio_running():
    """Check if FL Studio is running"""
    import subprocess

    check_script = '''
    tell application "System Events"
        set flRunning to (name of processes) contains "OsxFL"
        return flRunning
    end tell
    '''

    try:
        result = subprocess.run(
            ['osascript', '-e', check_script],
            timeout=3,
            capture_output=True,
            text=True
        )
        return result.returncode == 0 and "true" in result.stdout.lower()
    except:
        return False


def find_piano_roll_window():
    """Find the piano roll window in FL Studio and return its index"""
    import subprocess

    # AppleScript to find a window with "Piano roll" in the title
    find_script = '''
    tell application "System Events"
        tell process "OsxFL"
            set windowList to every window
            set windowIndex to 0
            repeat with w in windowList
                set windowIndex to windowIndex + 1
                try
                    set windowTitle to title of w
                    if windowTitle contains "Piano roll" then
                        return windowIndex
                    end if
                end try
            end repeat
            -- No piano roll window found, return 0
            return 0
        end tell
    end tell
    '''

    try:
        result = subprocess.run(
            ['osascript', '-e', find_script],
            timeout=3,
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            try:
                return int(result.stdout.strip())
            except ValueError:
                return 0
        return 0
    except:
        return 0


def send_trigger():
    """Use AppleScript to trigger FL Studio's run last script command"""
    global trigger_count
    import subprocess

    print(f"   🎹 Triggering FL Studio...")

    # First check if FL Studio is running
    if not is_fl_studio_running():
        print(f"   ❌ FL Studio is not running!")
        print(f"   💡 Please open FL Studio and a piano roll first")
        return False

    # Find the piano roll window
    piano_roll_index = find_piano_roll_window()
    if piano_roll_index == 0:
        print(f"   ⚠️  No Piano roll window found")
        print(f"   💡 Please open and detach a piano roll window")
        # Still try with window 1 as fallback
        piano_roll_index = 1

    # AppleScript to save focus, trigger FL Studio, then restore focus
    applescript = f'''
    -- Save the current frontmost application
    tell application "System Events"
        set originalApp to name of first application process whose frontmost is true
    end tell

    -- Trigger FL Studio
    tell application "System Events"
        tell process "OsxFL"
            -- Bring FL Studio to front
            set frontmost to true
            delay 0.3

            -- Try to raise the piano roll window
            try
                perform action "AXRaise" of window {piano_roll_index}
                delay 0.3
            on error
                -- If that fails, try to focus the first window
                try
                    perform action "AXRaise" of window 1
                    delay 0.3
                end try
            end try

            -- Send the keystroke to run last script
            keystroke "y" using {{command down, option down}}
        end tell
    end tell

    -- Wait for FL Studio to process
    delay 0.3

    -- Restore focus to original application using System Events (avoids dialog prompts)
    try
        tell application "System Events"
            set frontmost of process originalApp to true
        end tell
    end try

    return "success"
    '''

    max_retries = 2
    for attempt in range(max_retries):
        try:
            result = subprocess.run(
                ['osascript', '-e', applescript],
                timeout=8,
                capture_output=True,
                text=True
            )

            if result.returncode == 0:
                trigger_count += 1
                print(f"   ✅ Trigger sent successfully")
                return True
            else:
                error_msg = result.stderr.strip()
                if "not allowed" in error_msg.lower() or "accessibility" in error_msg.lower():
                    print(f"   ❌ Accessibility permission denied!")
                    print(f"   💡 Grant access in: System Settings → Privacy & Security → Accessibility")
                    print(f"   💡 Add Terminal (or your terminal app) and Claude Code")
                    return False
                elif attempt < max_retries - 1:
                    print(f"   ⚠️  Attempt {attempt + 1} failed, retrying...")
                    time.sleep(0.5)
                else:
                    print(f"   ⚠️  AppleScript error: {error_msg}")
                    trigger_count += 1  # Count as attempt even if failed
                    return False

        except subprocess.TimeoutExpired:
            if attempt < max_retries - 1:
                print(f"   ⚠️  Timeout on attempt {attempt + 1}, retrying...")
            else:
                print(f"   ⚠️  AppleScript timeout after {max_retries} attempts")
                return False
        except Exception as e:
            print(f"   ❌ Error: {e}")
            return False

    return False


def main():
    """Main watch loop"""
    global last_mtime

    print("🎹 FL Studio MCP Auto-Trigger")
    print("=" * 50)
    print(f"📂 Watching: {REQUEST_FILE}")
    print("⌨️  Trigger: Cmd+Opt+Y (macOS)")
    print("🛑 Stop: Press Ctrl+C")
    print()

    # Check if FL Studio is running
    if is_fl_studio_running():
        print("✅ FL Studio is running")
        piano_roll_idx = find_piano_roll_window()
        if piano_roll_idx > 0:
            print(f"✅ Piano roll window found (window {piano_roll_idx})")
        else:
            print("⚠️  No Piano roll window detected")
            print("   💡 Open a piano roll and detach it for best results")
    else:
        print("⚠️  FL Studio is not currently running")
        print("   💡 Start FL Studio and open a piano roll")
        print("   💡 The script will detect it when it starts")
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

    # Track consecutive failures for better feedback
    consecutive_failures = 0

    try:
        while True:
            if REQUEST_FILE.exists():
                current_mtime = REQUEST_FILE.stat().st_mtime

                # Check if file was modified
                if current_mtime > last_mtime:
                    last_mtime = current_mtime

                    # Check if there are actual requests
                    if has_pending_requests():
                        print(f"🔔 New requests detected! (#{trigger_count + 1})")
                        success = send_trigger()

                        if success:
                            consecutive_failures = 0
                            print(f"   📍 Completed at {time.strftime('%H:%M:%S')}")
                        else:
                            consecutive_failures += 1
                            if consecutive_failures >= 3:
                                print(f"   ⚠️  Multiple failures. Check FL Studio is running with piano roll open.")
                                consecutive_failures = 0  # Reset to avoid spamming

                        # Wait a moment for FL Studio to process
                        time.sleep(0.3)

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
