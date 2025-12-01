#!/usr/bin/env python3
"""
FastMCP server for FL Studio
Handles piano roll operations and music theory tools
"""

from fastmcp import FastMCP
import json
import os
from pathlib import Path
import subprocess
import tempfile


# Initialize FastMCP server
mcp = FastMCP("FL Studio MCP Server")

# Chord definitions (MIDI offsets from root note)
CHORD_DEFINITIONS = {
    "major": [0, 4, 7],
    "minor": [0, 3, 7],
    "dim": [0, 3, 6],
    "aug": [0, 4, 8],
    "maj7": [0, 4, 7, 11],
    "min7": [0, 3, 7, 10],
    "dom7": [0, 4, 7, 10],
    "sus2": [0, 2, 7],
    "sus4": [0, 5, 7],
    "maj9": [0, 4, 7, 11, 2],
    "min9": [0, 3, 7, 10, 2],
}

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
def analyze_piano_roll() -> str:
    """
    Analyze the current piano roll and provide a human-readable description.

    Returns a summary of:
    - Total number of notes
    - Note range (lowest and highest pitches)
    - Time span of the pattern
    - Average velocity
    - Color distribution
    """
    if not STATE_FILE.exists():
        return "No piano roll state file found. Please run the Piano Roll Bridge script and click 'Export State' first."

    try:
        with open(STATE_FILE, 'r') as f:
            state = json.load(f)

        notes = state.get("notes", [])
        if not notes:
            return "Piano roll is empty - no notes found."

        # Calculate statistics
        note_numbers = [n["number"] for n in notes]
        velocities = [n["velocity"] for n in notes]
        times = [n["time"] for n in notes]
        colors = [n["color"] for n in notes]

        min_pitch = min(note_numbers)
        max_pitch = max(note_numbers)
        min_time = min(times)
        max_time = max(times) + max([n["length"] for n in notes], default=0)
        avg_velocity = sum(velocities) / len(velocities) if velocities else 0

        # Convert MIDI numbers to note names for readability
        note_names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        min_note_name = f"{note_names[min_pitch % 12]}{min_pitch // 12 - 1}"
        max_note_name = f"{note_names[max_pitch % 12]}{max_pitch // 12 - 1}"

        # Count colors
        from collections import Counter
        color_counts = Counter(colors)

        ppq = state.get("ppq", 480)
        duration_bars = (max_time - min_time) / (ppq * 4) if ppq else 0

        analysis = f"""
Piano Roll Analysis:
==================
Total Notes: {len(notes)}
Pitch Range: {min_note_name} to {max_note_name} (MIDI {min_pitch} to {max_pitch})
Time Span: {duration_bars:.2f} bars (ticks {min_time} to {max_time})
Average Velocity: {avg_velocity:.2f} (0.0-1.0)
Color Distribution: {dict(color_counts)}
PPQ: {ppq}
"""
        return analysis

    except Exception as e:
        return f"Error analyzing piano roll: {str(e)}"


@mcp.tool
def describe_notes_detail() -> str:
    """
    Get a detailed description of all notes in the piano roll.

    Lists each note with its properties in a human-readable format.
    """
    if not STATE_FILE.exists():
        return "No piano roll state file found. Please run the Piano Roll Bridge script and click 'Export State' first."

    try:
        with open(STATE_FILE, 'r') as f:
            state = json.load(f)

        notes = state.get("notes", [])
        if not notes:
            return "Piano roll is empty - no notes found."

        note_names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        ppq = state.get("ppq", 480)

        description = "Detailed Notes List:\n" + "=" * 50 + "\n"

        for i, note in enumerate(notes, 1):
            pitch_name = f"{note_names[note['number'] % 12]}{note['number'] // 12 - 1}"
            time_beats = note["time"] / ppq if ppq else 0
            length_beats = note["length"] / ppq if ppq else 0

            description += f"""
Note {i}: {pitch_name}
  MIDI Number: {note['number']}
  Time: {note['time']} ticks ({time_beats:.2f} beats)
  Length: {note['length']} ticks ({length_beats:.2f} beats)
  Velocity: {note['velocity']:.2f}
  Pan: {note['pan']:.2f}
  Color: {note['color']}
"""

        return description

    except Exception as e:
        return f"Error describing notes: {str(e)}"


@mcp.tool
def create_chord_from_name(chord_name: str, root_note: int = 60, octave: int = 4, duration: float = 1.0, time: float = None, mode: str = "add") -> str:
    """
    Create a chord from a chord name and send it to the FL Studio piano roll.

    Args:
        chord_name: Name of the chord (e.g., "major", "minor", "maj7", "dom7")
        root_note: MIDI note number for the root (default 60 = Middle C)
        octave: Octave multiplier for spacing (default 4 = normal spacing)
        duration: Note duration as a multiplier of quarter notes (default 1.0 = quarter note)
                  Examples: 0.25=16th, 0.5=8th, 1.0=quarter, 1.5=dotted quarter, 2.0=half, 4.0=whole
        time: Start time in quarter notes from beginning (default None = place after last note)
        mode: Either "add" to add to existing notes or "replace" to clear first (default "add")

    Returns:
        Status of the chord creation request
    """
    chord_name_lower = chord_name.lower().strip()

    if chord_name_lower not in CHORD_DEFINITIONS:
        available = ", ".join(CHORD_DEFINITIONS.keys())
        return f"Unknown chord type '{chord_name}'. Available chords: {available}"

    # Get the chord intervals
    intervals = CHORD_DEFINITIONS[chord_name_lower]

    # Create note data for the chord
    notes = []
    for i, interval in enumerate(intervals):
        midi_note = root_note + interval
        notes.append({
            "midi": midi_note,
            "velocity": 0.8,
            "offset": 0,  # All notes play at the same time
            "duration": duration
        })

    # Create request for the FL Studio bridge
    request = {
        "action": "add_chord",
        "chord_name": chord_name_lower,
        "notes": notes,
        "root_note": root_note,
        "duration": duration,
        "time": time,  # None means auto-place after last note
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

        # Append this chord request
        requests.append(request)

        # Write updated list
        with open(REQUEST_FILE, 'w') as f:
            json.dump(requests, f, indent=2)

        return f"Chord '{chord_name}' created with root note MIDI {root_note}, duration {duration}. Notes: {[n['midi'] for n in notes]}"

    except Exception as e:
        return f"Error creating chord: {str(e)}"


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
