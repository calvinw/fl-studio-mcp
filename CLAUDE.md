# FL Studio MCP Bridge - Documentation

## Overview

This system allows Claude to interact with FL Studio's piano roll through an MCP (Model Context Protocol) server. It provides a bridge between Claude's AI capabilities and FL Studio's music production environment.

## Getting Started (For AI Assistants)

If you're an LLM helping the user with this system, here's what you need to know:

### 1. Check Available Tools

First, verify you have access to these MCP tools (they'll have the `mcp__fl-studio__` prefix):
- `mcp__fl-studio__get_piano_roll_state`
- `mcp__fl-studio__send_notes`
- `mcp__fl-studio__create_chord_from_name`
- `mcp__fl-studio__delete_notes`
- `mcp__fl-studio__clear_queue`

If these aren't available, the MCP server needs to be started or reconnected.

### 2. Understand the User Workflow

The user will:
1. **Open the call_llm script** in FL Studio's piano roll (Tools → Scripting → call_llm)
2. **Tell you what they want** (add chords, modify notes, create progressions, etc.)
3. **You send requests** using the MCP tools
4. **User clicks "Regenerate"** to preview your changes
5. **User clicks "Accept"** to commit, or tells you to adjust

### 3. Always Start With State

Before making ANY changes, get the current piano roll state:

```python
state = mcp__fl-studio__get_piano_roll_state()
```

This tells you:
- What notes already exist
- The PPQ (timing resolution)
- What you're working with

### 4. Key Concepts for LLMs

**Request Queue System:**
- Requests accumulate in a JSON file
- User previews ALL accumulated requests with "Regenerate"
- Nothing happens in FL Studio until user clicks "Regenerate"
- Multiple requests = multiple tool calls that stack up

**Time is Always in Quarter Notes:**
- `time=0` = beat 1
- `time=4` = beat 5 (measure 2 in 4/4)
- `duration=1` = quarter note
- `duration=4` = whole note
- Never use ticks - the bridge converts automatically

**Chords Are Just Multiple Notes:**
- A chord = multiple notes with the same `time` value
- You can use `create_chord_from_name` for convenience
- Or `send_notes` with same time for all notes

### 5. Common Interaction Patterns

**Pattern: Add a chord progression**
```python
# User: "Add a I-IV-V progression in C"

# Start by getting state (good practice)
state = mcp__fl-studio__get_piano_roll_state()

# Send each chord
mcp__fl-studio__send_notes([
    {"midi": 60, "duration": 4, "time": 0},
    {"midi": 64, "duration": 4, "time": 0},
    {"midi": 67, "duration": 4, "time": 0}
], mode="add")  # C major

mcp__fl-studio__send_notes([
    {"midi": 65, "duration": 4, "time": 4},
    {"midi": 69, "duration": 4, "time": 4},
    {"midi": 72, "duration": 4, "time": 4}
], mode="add")  # F major

mcp__fl-studio__send_notes([
    {"midi": 67, "duration": 4, "time": 8},
    {"midi": 71, "duration": 4, "time": 8},
    {"midi": 74, "duration": 4, "time": 8}
], mode="add")  # G major

# Tell user: "Click Regenerate to preview the progression"
```

**Pattern: Modify existing notes**
```python
# User: "Change that G note to an A"

# Get state to see what's there
state = mcp__fl-studio__get_piano_roll_state()

# Find the G note in the state (look for number: 67)
# Delete it
mcp__fl-studio__delete_notes([{"midi": 67, "time": 0}])

# Add replacement
mcp__fl-studio__send_notes([{"midi": 69, "duration": 4, "time": 0}])

# Tell user to Regenerate
```

**Pattern: Start fresh**
```python
# User: "Clear everything and give me a C major scale"

# Use replace mode to clear and add
mcp__fl-studio__send_notes([
    {"midi": 60, "duration": 0.5, "time": 0},   # C
    {"midi": 62, "duration": 0.5, "time": 0.5}, # D
    {"midi": 64, "duration": 0.5, "time": 1},   # E
    {"midi": 65, "duration": 0.5, "time": 1.5}, # F
    {"midi": 67, "duration": 0.5, "time": 2},   # G
    {"midi": 69, "duration": 0.5, "time": 2.5}, # A
    {"midi": 71, "duration": 0.5, "time": 3},   # B
    {"midi": 72, "duration": 0.5, "time": 3.5}  # C
], mode="replace")
```

**Pattern: User doesn't like the preview**
```python
# User: "Actually, I don't like that. Start over."

# Clear the queue
mcp__fl-studio__clear_queue()

# Now send new requests
```

### 6. Important Rules for LLMs

**DO:**
- ✅ Always get state first with `get_piano_roll_state()`
- ✅ Always specify `time` for every note (don't rely on defaults)
- ✅ Use quarter notes for time and duration
- ✅ Tell user to "Click Regenerate" after sending requests
- ✅ Use `mode="add"` by default (accumulate changes)
- ✅ Use `mode="replace"` when user wants to start fresh
- ✅ Offer to `clear_queue()` if user changes their mind

**DON'T:**
- ❌ Don't assume notes will appear without user clicking Regenerate
- ❌ Don't use ticks/PPQ directly - always use quarter notes
- ❌ Don't forget to get state before making changes
- ❌ Don't send requests without telling user what to do next

### 7. Troubleshooting for LLMs

**User says "Nothing happened"**
- Ask: "Did you click Regenerate in FL Studio?"
- Requests queue up but don't apply until Regenerate is clicked

**User says "It replaced everything"**
- Check if you used `mode="replace"` accidentally
- Should use `mode="add"` for incremental changes

**User says "Times are wrong"**
- Verify you're using quarter notes, not ticks
- Remember: time=4 is beat 5, not beat 4 (counting starts at 0)

**User wants to undo**
- Use `clear_queue()` to discard pending changes
- Or tell them to close the script without clicking Accept

### 8. Musical Knowledge Tips

When helping with music:
- **MIDI note numbers**: C4 (middle C) = 60, each semitone = +1
- **Common durations**: 0.25=16th, 0.5=8th, 1=quarter, 2=half, 4=whole
- **Chord voicings**: Consider inversions for smoother voice leading
- **Bass notes**: Typically 1-2 octaves below the chord (MIDI 36-48 range)
- **Time signatures**: In 4/4, measures are 4 beats (time increments of 4)

### 9. Example Session

```
User: "Open the script"
[User opens call_llm in FL Studio]

User: "Add a sad chord progression"

You: Get state first
> mcp__fl-studio__get_piano_roll_state()

You: Send Am - F - C - G progression
> mcp__fl-studio__send_notes([...]) # Am at time 0
> mcp__fl-studio__send_notes([...]) # F at time 4
> mcp__fl-studio__send_notes([...]) # C at time 8
> mcp__fl-studio__send_notes([...]) # G at time 12

You: "I've queued up a sad Am-F-C-G progression. Click Regenerate to preview!"

User: "Great! Add a bass line"

You: Send bass notes
> mcp__fl-studio__send_notes([...]) # Bass notes at appropriate times

You: "Added bass notes. Click Regenerate again to hear it with bass!"

User: "Perfect!" [Clicks Accept]

[Session done - user has committed the changes]
```

## Architecture

The system consists of three main components:

1. **MCP Server** (`fl_studio_mcp_server.py`) - Provides tools for Claude to send musical requests
2. **FL Studio Bridge Script** (`call_llm.pyscript`) - Runs inside FL Studio to process requests
3. **JSON Communication Files** - Request queue and state files for communication

### Communication Flow

```
Claude → MCP Server → Request Queue (JSON) → FL Studio Bridge → Piano Roll
                                                      ↓
                                           State Export (JSON)
```

## Workflow

1. **Open call_llm script** (Tools → Scripting → call_llm) → Automatically:
   - Exports current piano roll state to `piano_roll_state.json`
   - Clears request queue (sets to `[]`)

2. **Claude sends requests** → Accumulate in queue as list of actions

3. **Click "Regenerate"** → Preview all accumulated changes

4. **Click "Accept"** → Commit changes and close dialog

5. **Repeat** - Open script again to start fresh

## Available MCP Tools

### `get_piano_roll_state()`
Read the current piano roll state exported by FL Studio.

**Returns:** JSON with PPQ, note count, and all notes with properties (number, time, length, velocity, etc.)

**Example:**
```python
state = get_piano_roll_state()
# See all notes currently in the piano roll
```

### `send_notes(notes, mode="add")`
Send arbitrary notes to the piano roll.

**Parameters:**
- `notes`: List of note dictionaries
  - `midi`: MIDI note number (0-127)
  - `duration`: Duration in quarter notes
  - `time`: Start time in quarter notes
  - `velocity`: Optional, 0.0-1.0 (default 0.8)
- `mode`: "add" or "replace"

**Example:**
```python
# Send a C major chord at beat 0
send_notes([
    {"midi": 60, "duration": 2, "time": 0},
    {"midi": 64, "duration": 2, "time": 0},
    {"midi": 67, "duration": 2, "time": 0}
])

# Send a melody
send_notes([
    {"midi": 60, "duration": 0.5, "time": 0},
    {"midi": 62, "duration": 0.5, "time": 0.5},
    {"midi": 64, "duration": 0.5, "time": 1},
    {"midi": 65, "duration": 0.5, "time": 1.5}
])
```

### `create_chord_from_name(chord_name, root_note=60, duration=1.0, time=None, mode="add")`
Create a chord from a chord name.

**Parameters:**
- `chord_name`: "major", "minor", "dim", "aug", "maj7", "min7", "dom7", "sus2", "sus4", "maj9", "min9"
- `root_note`: MIDI note number (default 60 = Middle C)
- `duration`: Duration in quarter notes (default 1.0)
- `time`: Start time in quarter notes (default None = place at beat 0)
- `mode`: "add" or "replace"

**Example:**
```python
# C major chord at beat 0
create_chord_from_name("major", root_note=60, duration=2, time=0)

# F minor chord at beat 4
create_chord_from_name("minor", root_note=65, duration=2, time=4)
```

### `delete_notes(notes)`
Delete specific notes from the piano roll.

**Parameters:**
- `notes`: List of note dictionaries to delete
  - `midi`: MIDI note number
  - `time`: Start time in quarter notes

**Example:**
```python
# Delete G note at beat 0
delete_notes([{"midi": 67, "time": 0}])

# Delete multiple notes
delete_notes([
    {"midi": 67, "time": 0},
    {"midi": 72, "time": 4}
])
```

### `clear_queue()`
Clear all pending requests without affecting the piano roll.

**Use case:** Discard accumulated changes if you don't like the preview.

**Example:**
```python
# Made a mistake, clear the queue and start over
clear_queue()
```

## Modes

### Add Mode (`mode="add"`)
- Appends to existing queue
- Adds to existing notes in piano roll
- Default behavior

### Replace Mode (`mode="replace"`)
- Clears queue first
- Adds `{"action": "clear"}` to delete all notes
- Then adds new notes
- Use for complete rewrites

## Time and Duration

- **Time units:** Quarter notes (beats)
  - `time=0` → Beat 1
  - `time=4` → Beat 5 (start of measure 2 in 4/4)
  - `time=8` → Beat 9 (start of measure 3)

- **Duration units:** Quarter note multipliers
  - `0.25` = 16th note
  - `0.5` = 8th note
  - `1.0` = Quarter note
  - `1.5` = Dotted quarter
  - `2.0` = Half note
  - `4.0` = Whole note

- **PPQ (Pulses Per Quarter):** Typically 96 or 480
  - Ticks = PPQ × Quarter Notes
  - Conversion handled automatically by bridge script

## Request Queue System

Requests accumulate as a list of actions in `mcp_request.json`:

```json
[
  {"action": "delete_notes", "notes": [{"midi": 67, "time": 0}]},
  {"action": "add_notes", "notes": [{"midi": 69, "duration": 2, "time": 0}]},
  {"action": "add_notes", "notes": [{"midi": 65, "duration": 2, "time": 2}]}
]
```

**Processing order:** Actions are executed in order when you click Regenerate.

## File Locations

**FL Studio scripts directory:**
```
~/Documents/Image-Line/FL Studio/Settings/Piano roll scripts/
├── call_llm.pyscript         (copy of bridge script)
├── mcp_request.json          (request queue)
├── mcp_response.json         (execution results)
└── piano_roll_state.json     (exported piano roll state)
```

**Source repository:**
```
/Users/calvinw/fl_mcp/
├── call_llm.pyscript         (source bridge script)
├── fl_studio_mcp_server.py   (MCP server)
└── CLAUDE.md                 (this file)
```

## Typical Workflows

### Building a Chord Progression

```python
# Open call_llm script (clears queue, exports state)

# Send chord progression
send_notes([
    {"midi": 60, "duration": 4, "time": 0},
    {"midi": 64, "duration": 4, "time": 0},
    {"midi": 67, "duration": 4, "time": 0}
])  # C major

send_notes([
    {"midi": 65, "duration": 4, "time": 4},
    {"midi": 68, "duration": 4, "time": 4},
    {"midi": 72, "duration": 4, "time": 4}
])  # F minor

# Click Regenerate to preview
# Click Accept to commit
```

### Modifying Existing Notes

```python
# Open call_llm script (exports current state)

# Get current state
state = get_piano_roll_state()

# Delete a specific note
delete_notes([{"midi": 67, "time": 0}])

# Add replacement
send_notes([{"midi": 69, "duration": 4, "time": 0}])

# Click Regenerate to preview
# Click Accept to commit
```

### Starting Fresh (Replace Mode)

```python
# Clear everything and add new progression
send_notes([
    {"midi": 60, "duration": 2, "time": 0},
    {"midi": 64, "duration": 2, "time": 0},
    {"midi": 67, "duration": 2, "time": 0}
], mode="replace")

# Click Regenerate - old notes gone, new chord appears
# Click Accept to commit
```

### Discarding Changes

```python
# Made some requests but don't like them
send_notes([...])
send_notes([...])

# Changed your mind
clear_queue()

# Start over with new requests
```

## Tips

1. **Always specify `time`** - Every note should have an explicit time position
2. **Use quarter notes** - All time/duration values are in quarter note units
3. **Preview before committing** - Click Regenerate to see changes before Accept
4. **Get state first** - Call `get_piano_roll_state()` before making changes
5. **Clear queue if needed** - Use `clear_queue()` to discard unwanted changes
6. **Reload script for fresh start** - Close and reopen to reset everything

## Troubleshooting

**Changes not appearing?**
- Make sure you clicked "Regenerate" after sending requests
- Reload the call_llm script to pick up code changes

**Notes at wrong positions?**
- Check PPQ value in state export
- Ensure time values are in quarter notes, not ticks

**Queue accumulating incorrectly?**
- Close and reopen script to clear queue
- Use `clear_queue()` to reset

**Script not responding?**
- Check that call_llm.pyscript is copied to Piano roll scripts directory
- Verify MCP server is running
- Restart MCP server after code changes

## Future Enhancements

Potential additions:
- Delete by time range
- Modify note properties (velocity, length)
- Pattern generation tools
- Harmonic analysis tools
- MIDI file import/export
