#!/usr/bin/env python3
"""
FastMCP server for FL Studio
Handles piano roll operations and music theory tools
"""

from fastmcp import FastMCP
import json
import os
from pathlib import Path


# Initialize FastMCP server
mcp = FastMCP("FL Studio MCP Server")

# Request/Response file paths for communication
BRIDGE_DIR = Path(os.path.expanduser("~/Documents/Image-Line/FL Studio/Settings/Piano roll scripts"))
REQUEST_FILE = BRIDGE_DIR / "mcp_request.json"
RESPONSE_FILE = BRIDGE_DIR / "mcp_response.json"

# Path to the piano roll scripts directory
SCRIPT_DIR = Path(os.path.expanduser("~/Documents/Image-Line/FL Studio/Settings/Piano roll scripts"))
STATE_FILE = SCRIPT_DIR / "piano_roll_state.json"


@mcp.tool
def get_piano_roll_state() -> str:
    """
    Read the current piano roll state from the exported JSON file.

    The FL Studio script must have exported the state by pressing the 'Export State' button.

    Returns:
        A JSON string containing all notes and metadata from the piano roll.
    """
    if not STATE_FILE.exists():
        return json.dumps({
            "error": "No piano roll state file found. Please run the Piano Roll Bridge script and click 'Export State'.",
            "expected_location": str(STATE_FILE)
        })

    try:
        with open(STATE_FILE, 'r') as f:
            state = json.load(f)
        return json.dumps(state, indent=2)
    except Exception as e:
        return json.dumps({
            "error": f"Failed to read piano roll state: {str(e)}"
        })


@mcp.tool
def send_notes(notes: list[dict], mode: str = "add") -> str:
    """
    Send arbitrary notes to the FL Studio piano roll.

    Args:
        notes: List of note dictionaries, each containing:
            - midi: MIDI note number (0-127)
            - duration: Note duration as multiplier of quarter notes (e.g., 1.0=quarter, 2.0=half)
            - time: Start time offset in quarter notes from beginning (default 0)
            - velocity: Note velocity 0.0-1.0 (default 0.8)
        mode: Either "add" to add to existing notes or "replace" to clear first (default "add")

    Example:
        send_notes([
            {"midi": 60, "duration": 1.0, "time": 0},
            {"midi": 64, "duration": 0.5, "time": 1.0},
            {"midi": 67, "duration": 2.0, "time": 1.5}
        ], mode="replace")

    Returns:
        Status of the note creation request
    """
    if not notes:
        return "Error: notes list cannot be empty"

    # Validate and prepare notes
    prepared_notes = []
    for i, note in enumerate(notes):
        if "midi" not in note:
            return f"Error: note {i} missing required 'midi' field"
        if "duration" not in note:
            return f"Error: note {i} missing required 'duration' field"

        prepared_note = {
            "midi": note["midi"],
            "duration": note["duration"],
            "time": note.get("time", 0),  # Time in quarter notes
            "velocity": note.get("velocity", 0.8)
        }
        prepared_notes.append(prepared_note)

    # Create request for the FL Studio bridge
    request = {
        "action": "add_notes",
        "notes": prepared_notes,
        "mode": mode
    }

    try:
        # Read existing requests or create new list
        requests = []
        if REQUEST_FILE.exists():
            try:
                with open(REQUEST_FILE, 'r') as f:
                    content = json.load(f)
                    if isinstance(content, list):
                        requests = content
            except:
                pass

        # If mode is replace, clear the list first and add a clear action
        if mode == "replace":
            requests = [{"action": "clear"}]

        # Append this notes request
        requests.append(request)

        # Write updated list
        with open(REQUEST_FILE, 'w') as f:
            json.dump(requests, f, indent=2)

        return f"Sent {len(prepared_notes)} notes to FL Studio. MIDI notes: {[n['midi'] for n in prepared_notes]}"

    except Exception as e:
        return f"Error sending notes: {str(e)}"


@mcp.tool
def delete_notes(notes: list[dict]) -> str:
    """
    Delete specific notes from the FL Studio piano roll.

    Args:
        notes: List of note dictionaries to delete, each containing:
            - midi: MIDI note number (0-127)
            - time: Start time in quarter notes

    Example:
        delete_notes([
            {"midi": 67, "time": 4},
            {"midi": 72, "time": 8}
        ])

    Returns:
        Status of the delete request
    """
    if not notes:
        return "Error: notes list cannot be empty"

    # Validate notes
    for i, note in enumerate(notes):
        if "midi" not in note:
            return f"Error: note {i} missing required 'midi' field"
        if "time" not in note:
            return f"Error: note {i} missing required 'time' field"

    # Create request for the FL Studio bridge
    request = {
        "action": "delete_notes",
        "notes": notes
    }

    try:
        # Read existing requests or create new list
        requests = []
        if REQUEST_FILE.exists():
            try:
                with open(REQUEST_FILE, 'r') as f:
                    content = json.load(f)
                    if isinstance(content, list):
                        requests = content
            except:
                pass

        # Append this delete request
        requests.append(request)

        # Write updated list
        with open(REQUEST_FILE, 'w') as f:
            json.dump(requests, f, indent=2)

        return f"Delete request for {len(notes)} notes added to queue. MIDI notes: {[n['midi'] for n in notes]}"

    except Exception as e:
        return f"Error creating delete request: {str(e)}"


@mcp.tool
def clear_queue() -> str:
    """
    Clear the pending request queue without affecting the piano roll.

    Use this to discard accumulated add/delete requests before they are applied.
    The piano roll itself remains unchanged until you send new requests.

    Returns:
        Status of the queue clearing operation
    """
    try:
        # Clear the request file
        with open(REQUEST_FILE, 'w') as f:
            f.write("[]")

        return "Queue cleared. All pending requests have been discarded."

    except Exception as e:
        return f"Error clearing queue: {str(e)}"


if __name__ == "__main__":
    mcp.run()
