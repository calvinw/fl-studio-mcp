# Signal MCP Integration Plan

## Executive Summary

**Goal:** Enable Claude to control Signal's piano roll using MIDI I/O, similar to the existing FL Studio MCP Bridge.

**Key Finding:** Yes, this is absolutely possible! Signal's WebMIDI-based architecture makes it an excellent candidate for MCP integration using virtual MIDI devices.

**Recommended Approach:** Use virtual MIDI ports for bi-directional communication between the MCP server and Signal app.

---

## Architecture Comparison

### Current FL Studio MCP Bridge

**Communication Method:** JSON file-based request queue
```
Claude → MCP Server → JSON Files → FL Studio Python Script → Piano Roll
                                          ↓
                                   State Export (JSON)
```

**Workflow:**
1. User opens `call_llm.pyscript` in FL Studio
2. Script exports current state to `piano_roll_state.json`
3. Script clears request queue (`mcp_request.json` → `[]`)
4. Claude sends requests via MCP tools → Accumulate in JSON queue
5. User clicks "Regenerate" → Script processes all queued requests
6. User clicks "Accept" → Changes committed to piano roll

**Pros:**
- Simple file-based protocol
- No network complexity
- Queue accumulation for preview
- Easy to debug (human-readable JSON)

**Cons:**
- FL Studio specific (requires Python scripting API)
- File polling overhead
- Manual script invocation required
- Not real-time

---

### Proposed Signal MCP Bridge

**Communication Method:** Virtual MIDI I/O + WebMIDI API
```
Claude → MCP Server → Virtual MIDI Port → Signal WebMIDI → Piano Roll
                                              ↓
                                       State Export via MIDI
```

**Three Implementation Options:**

#### Option 1: Virtual MIDI Device (Recommended)
**Best for:** Zero Signal code changes, universal compatibility

**Architecture:**
```
MCP Server (Python)
  ↓ Creates/manages
Virtual MIDI Port (OS-level: IAC Driver, loopMIDI, JACK)
  ↓ WebMIDI API discovers
Signal App (Browser/Electron)
  ↓ MIDIInput/MIDIOutput services
Piano Roll (Track events)
```

**How it works:**
1. MCP server creates a virtual MIDI output port (e.g., "Claude MCP Out")
2. MCP server creates a virtual MIDI input port (e.g., "Claude MCP In")
3. Signal auto-discovers these ports via WebMIDI API
4. User enables them in Signal's MIDI settings
5. MCP server sends MIDI note events → Signal receives and adds to piano roll
6. Signal sends current state as MIDI events → MCP server receives and decodes

**Implementation:**
- Python library: `python-rtmidi` or `mido` with virtual port support
- No Signal code changes needed
- Works with stock Signal app (web or Electron)

**Pros:**
- ✅ No Signal fork required
- ✅ Standard MIDI protocol
- ✅ Works with any MIDI software
- ✅ Bi-directional communication
- ✅ Real-time capable

**Cons:**
- ⚠️ Limited metadata (MIDI only carries note/velocity/channel)
- ⚠️ Requires OS-level virtual MIDI driver setup
- ⚠️ MIDI protocol constraints (127 notes, 16 channels)

---

#### Option 2: Custom SynthOutput Plugin (Advanced)
**Best for:** Rich metadata, custom protocol, Signal power users

**Architecture:**
```
Signal Fork
  ↓ Modified GroupOutput.ts
Custom MCPOutput class (implements SynthOutput)
  ↓ WebSocket/HTTP
MCP Server
  ↓
Claude
```

**How it works:**
1. Fork Signal and add a new `MCPOutput` class in `/app/src/services/MCPOutput.ts`
2. Register it in `GroupOutput` alongside `SoundFontSynth` and `MIDIOutput`
3. When Signal plays/sends events, route them to MCP server via WebSocket
4. MCP server sends back note modifications → Signal applies them

**Example code:**
```typescript
// app/src/services/MCPOutput.ts
import { SynthOutput } from '@signal-app/player'

class MCPOutput implements SynthOutput {
  private ws: WebSocket

  activate() {
    this.ws = new WebSocket('ws://localhost:8765')
  }

  sendEvent(event, delayTime, timestampNow, trackId) {
    this.ws.send(JSON.stringify({
      type: 'midi_event',
      event,
      timestamp: timestampNow + delayTime * 1000,
      trackId,
      // Send extra metadata not available in MIDI
      trackName: rootStore.song.tracks[trackId]?.name,
      ppq: rootStore.song.timebase,
      projectName: rootStore.song.name
    }))
  }
}

// Register in RootStore.ts
const mcpOutput = new MCPOutput()
this.synthGroup.outputs.push({
  synth: mcpOutput,
  isEnabled: true
})
```

**Pros:**
- ✅ Rich metadata (track names, project info, etc.)
- ✅ Custom protocol (not limited to MIDI)
- ✅ Direct communication (no virtual MIDI overhead)
- ✅ Can send entire song structure

**Cons:**
- ❌ Requires Signal fork
- ❌ Maintenance burden (keep up with upstream)
- ❌ Not available in stock Signal

---

#### Option 3: Electron IPC Extension (Desktop Only)
**Best for:** Desktop app users, Node.js integration

**Architecture:**
```
Signal Electron Main Process
  ↓ IPC Bridge
Signal Renderer (React)
  ↓ Native Node.js
MCP Server (local process)
```

**How it works:**
1. Add IPC handlers in `electron/src/ipcMain.ts`
2. Expose MCP communication API via `contextBridge`
3. React components call Electron IPC → Main process forwards to MCP
4. MCP sends back changes → IPC → Renderer updates state

**Example code:**
```typescript
// electron/src/ipcMain.ts
ipcMain.handle('mcp:send-notes', async (event, notes) => {
  // Forward to MCP server via HTTP/WebSocket
  const response = await fetch('http://localhost:8765/mcp/add-notes', {
    method: 'POST',
    body: JSON.stringify(notes)
  })
  return response.json()
})

// electron/src/ElectronAPI.ts
export interface ElectronAPI {
  // Existing methods...
  sendNotesToMCP: (notes: Note[]) => Promise<void>
  getMCPState: () => Promise<Song>
}
```

**Pros:**
- ✅ Desktop app native integration
- ✅ Can use Node.js libraries
- ✅ File system access (could sync state to disk)

**Cons:**
- ❌ Desktop-only (no web version)
- ❌ Requires Signal fork
- ❌ Limited to Electron builds

---

## Detailed Design: Option 1 (Virtual MIDI - Recommended)

### Why Option 1?

1. **No Signal changes needed** - Works with stock Signal app
2. **Standard protocol** - MIDI is universal and well-understood
3. **Real-time** - Low latency communication
4. **Bi-directional** - Can send notes AND read current state
5. **Future-proof** - Works with any DAW/sequencer that supports MIDI

### Technical Architecture

#### Component Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     MCP Server (Python)                     │
│  - FastMCP server with tools                                │
│  - python-rtmidi for virtual MIDI port creation             │
│  - MIDI encoding/decoding (note on/off, SysEx for metadata) │
└─────────────────┬──────────────────────┬────────────────────┘
                  │                      │
         Virtual MIDI Out          Virtual MIDI In
         "Claude MCP Out"          "Claude MCP In"
                  │                      │
                  ↓                      ↑
┌─────────────────────────────────────────────────────────────┐
│                    OS Virtual MIDI Driver                   │
│  - macOS: IAC Driver (built-in)                             │
│  - Windows: loopMIDI (free)                                 │
│  - Linux: JACK ALSA MIDI bridge                             │
└─────────────────┬──────────────────────┬────────────────────┘
                  │                      │
                  ↓                      ↑
┌─────────────────────────────────────────────────────────────┐
│                Signal App (Browser/Electron)                │
│  - WebMIDI API auto-discovers virtual ports                 │
│  - MIDIInput service receives notes                         │
│  - MIDIOutput service sends current state                   │
│  - Piano roll updates reactively (MobX)                     │
└─────────────────────────────────────────────────────────────┘
```

### Protocol Design

#### Sending Notes to Signal (Claude → Signal)

**MCP Tool:** `send_notes_to_signal(notes)`

**MIDI Encoding:**
```python
# For each note in the request:
{
  "midi": 60,       # MIDI note number
  "velocity": 100,  # 0-127 (convert from 0.0-1.0)
  "duration": 1.0,  # Quarter notes
  "time": 0.0,      # Quarter notes from start
  "channel": 0      # MIDI channel 0-15
}

# Encode as MIDI events:
timestamp_ticks = time * ppq
duration_ticks = duration * ppq

# Send Note On
midi_out.send([0x90 | channel, midi, velocity], timestamp_ms)

# Send Note Off (scheduled for later)
midi_out.send([0x80 | channel, midi, 0], timestamp_ms + duration_ms)
```

**Signal receives:**
- `MIDIInput.onMidiMessage()` fires for each event
- If recording enabled: `MIDIRecorder` adds to current track
- If in pencil mode: Notes preview in piano roll

#### Reading State from Signal (Signal → Claude)

**Challenge:** MIDI can't send entire song state efficiently

**Solutions:**

**A. SysEx Dump (Recommended)**
Signal doesn't natively send state, but we can trigger it:

```typescript
// Add a keyboard shortcut or menu item in Signal
// (Requires small Signal modification, but non-invasive)

// When user triggers "Export to MCP":
const exportToMCP = () => {
  const song = rootStore.song
  const state = {
    ppq: song.timebase,
    tracks: song.tracks.map(track => ({
      id: track.id,
      channel: track.channel,
      events: track.events.filter(e => e.type === 'channel' && e.subtype === 'note')
    }))
  }

  // Send as SysEx (unlimited size)
  const json = JSON.stringify(state)
  const bytes = new TextEncoder().encode(json)

  midiOutput.send([0xF0, ...bytes, 0xF7])  // SysEx message
}
```

MCP server receives SysEx → decodes JSON → provides to Claude

**B. MIDI File Export (No Signal changes)**
Use Signal's existing export:
1. User exports MIDI file (Ctrl+S or File → Export MIDI)
2. MCP server watches export directory
3. Parse MIDI file with `midifile-ts` or Python `mido`
4. Provide state to Claude

**C. Real-time Monitoring (Passive)**
MCP server listens to Signal's MIDI output:
- Accumulates all Note On/Off events
- Builds internal state representation
- Provides current state on request

**Recommended: Hybrid Approach**
- Use SysEx for initial state dump (one-time Signal modification)
- Use real-time monitoring for incremental updates
- Fall back to MIDI file export if SysEx unavailable

### MCP Tools API

```python
@mcp.tool
def send_notes_to_signal(
    notes: list[dict],
    mode: str = "add",
    channel: int = 0
) -> str:
    """
    Send notes to Signal via virtual MIDI port.

    Args:
        notes: List of note dicts with midi, duration, time, velocity
        mode: "add" or "replace" (replace sends clear SysEx first)
        channel: MIDI channel 0-15

    Returns:
        Status message
    """
    # Encode and send MIDI events
    ...

@mcp.tool
def get_signal_piano_roll_state() -> str:
    """
    Get current piano roll state from Signal.

    Triggers state export via SysEx or reads last MIDI export.

    Returns:
        JSON with tracks, notes, PPQ, etc.
    """
    # Request state via SysEx trigger or parse MIDI file
    ...

@mcp.tool
def create_chord_in_signal(
    chord_name: str,
    root_note: int = 60,
    duration: float = 1.0,
    time: float = 0.0,
    channel: int = 0
) -> str:
    """
    Create chord in Signal's piano roll.

    Same API as FL Studio version, but sends via MIDI.
    """
    # Generate chord notes and send via MIDI
    ...

@mcp.tool
def delete_notes_from_signal(
    notes: list[dict],
    channel: int = 0
) -> str:
    """
    Delete specific notes from Signal.

    Sends custom SysEx delete command.
    """
    # Send delete command via SysEx
    ...

@mcp.tool
def clear_signal_piano_roll(channel: int = 0) -> str:
    """
    Clear all notes in Signal's current track.

    Sends custom SysEx clear command.
    """
    # Send clear command
    ...
```

### Workflow Comparison

#### FL Studio Workflow
```
1. Open call_llm script → Exports state, clears queue
2. Claude sends requests → Accumulate in JSON file
3. Click "Regenerate" → Process all requests, preview
4. Click "Accept" → Commit changes
```

#### Signal Workflow (Option 1)
```
1. Enable "Claude MCP Out" in Signal MIDI settings
2. Enable "Claude MCP In" for state export
3. Claude sends notes → Appear immediately in piano roll
4. To get state: User triggers export (keyboard shortcut or auto-export)
5. Claude reads state from MCP server cache
```

**Key Difference:** Signal is immediate (no preview queue), unless we add a modification.

### Optional: Add Preview Queue to Signal

If you want FL Studio-style preview behavior, add a small modification:

```typescript
// app/src/stores/MCPQueueStore.ts
class MCPQueueStore {
  @observable pendingNotes: Note[] = []

  @action
  addToQueue(notes: Note[]) {
    this.pendingNotes.push(...notes)
  }

  @action
  applyQueue() {
    const track = rootStore.selectedTrack
    this.pendingNotes.forEach(note => {
      track.events.push(note)
    })
    this.pendingNotes = []
  }

  @action
  clearQueue() {
    this.pendingNotes = []
  }
}

// Show pending notes as ghost notes in piano roll
// Add UI buttons: "Apply Changes" and "Discard"
```

This adds a review step like FL Studio's Regenerate/Accept.

---

## Implementation Roadmap

### Phase 1: Virtual MIDI Setup (No Signal Changes)

**Goal:** Proof of concept with manual MIDI recording

**Tasks:**
1. Set up virtual MIDI driver on your OS
2. Create basic MCP server with `python-rtmidi`
3. Test sending notes from MCP → Signal
4. Verify Signal receives and records notes

**Deliverables:**
- MCP server that creates virtual MIDI ports
- `send_notes_to_signal()` tool
- Demo: Claude adds chord progression to Signal

**Time:** 1-2 days

---

### Phase 2: State Reading (Minimal Signal Changes)

**Goal:** Bi-directional communication

**Tasks:**
1. Add SysEx export to Signal (or use MIDI file export)
2. MCP server receives and decodes state
3. `get_signal_piano_roll_state()` tool
4. Claude can read and modify

**Deliverables:**
- State export from Signal → MCP
- Full CRUD operations on piano roll
- Demo: Claude analyzes and modifies existing song

**Time:** 2-3 days

---

### Phase 3: Advanced Features (Optional)

**Goal:** Enhanced UX and metadata

**Tasks:**
1. Add preview queue to Signal (optional)
2. Multi-track support via MIDI channels
3. Velocity/expression controls
4. Chord recognition from existing notes

**Deliverables:**
- Preview before applying changes
- Multi-track chord progressions
- Music theory analysis tools

**Time:** 3-5 days

---

## Code Examples

### MCP Server with Virtual MIDI (Python)

```python
#!/usr/bin/env python3
"""
Signal MCP Server with Virtual MIDI I/O
"""

from fastmcp import FastMCP
import rtmidi
import json
import time
from threading import Thread

mcp = FastMCP("Signal MCP Server")

# Create virtual MIDI ports
midi_out = rtmidi.MidiOut()
midi_in = rtmidi.MidiIn()

# Open virtual ports
midi_out.open_virtual_port("Claude MCP Out")
midi_in.open_virtual_port("Claude MCP In")

# State cache
current_state = {
    "ppq": 480,
    "tracks": []
}

# MIDI input callback
def midi_callback(event, data=None):
    message, deltatime = event

    # Handle SysEx state dump
    if message[0] == 0xF0:  # SysEx start
        # Decode JSON state
        json_bytes = bytes(message[1:-1])  # Remove F0 and F7
        state_json = json_bytes.decode('utf-8')
        global current_state
        current_state = json.loads(state_json)
        print(f"Received state: {len(current_state['tracks'])} tracks")

midi_in.set_callback(midi_callback)

@mcp.tool
def send_notes_to_signal(notes: list[dict], mode: str = "add", channel: int = 0) -> str:
    """
    Send notes to Signal via virtual MIDI.

    Args:
        notes: List of note dicts with midi, duration, time, velocity
        mode: "add" or "replace"
        channel: MIDI channel 0-15

    Returns:
        Status message
    """
    ppq = current_state.get("ppq", 480)

    if mode == "replace":
        # Send clear SysEx command
        clear_msg = [0xF0, 0x7E, 0x00, 0x00, 0xF7]  # Custom clear command
        midi_out.send_message(clear_msg)
        time.sleep(0.01)

    for note in notes:
        midi_num = note["midi"]
        velocity = int(note.get("velocity", 0.8) * 127)
        time_qn = note.get("time", 0.0)
        duration_qn = note["duration"]

        # Calculate timestamps (in milliseconds from now)
        timestamp_ms = time_qn * (60000.0 / 120)  # Assume 120 BPM for now
        duration_ms = duration_qn * (60000.0 / 120)

        # Send Note On
        note_on = [0x90 | channel, midi_num, velocity]
        midi_out.send_message(note_on)

        # Schedule Note Off (in separate thread)
        def send_note_off():
            time.sleep(duration_ms / 1000.0)
            note_off = [0x80 | channel, midi_num, 0]
            midi_out.send_message(note_off)

        Thread(target=send_note_off).start()

        # Small delay between notes
        time.sleep(0.001)

    return f"Sent {len(notes)} notes to Signal on channel {channel}"

@mcp.tool
def get_signal_piano_roll_state() -> str:
    """
    Get current piano roll state from Signal.

    Returns:
        JSON with tracks, notes, PPQ
    """
    # Request state via SysEx trigger
    # (Assumes Signal modified to respond to this)
    request_state = [0xF0, 0x7E, 0x00, 0x01, 0xF7]  # Custom request command
    midi_out.send_message(request_state)

    # Wait for callback to populate current_state
    time.sleep(0.1)

    return json.dumps(current_state, indent=2)

@mcp.tool
def create_chord_in_signal(
    chord_name: str,
    root_note: int = 60,
    duration: float = 1.0,
    time: float = 0.0,
    channel: int = 0
) -> str:
    """
    Create chord in Signal's piano roll.
    """
    CHORD_DEFINITIONS = {
        "major": [0, 4, 7],
        "minor": [0, 3, 7],
        "maj7": [0, 4, 7, 11],
        "min7": [0, 3, 7, 10],
        "dom7": [0, 4, 7, 10],
        # ... more chords
    }

    intervals = CHORD_DEFINITIONS.get(chord_name.lower())
    if not intervals:
        return f"Unknown chord: {chord_name}"

    notes = [
        {
            "midi": root_note + interval,
            "duration": duration,
            "time": time,
            "velocity": 0.8
        }
        for interval in intervals
    ]

    return send_notes_to_signal(notes, mode="add", channel=channel)

if __name__ == "__main__":
    print("Signal MCP Server running...")
    print(f"Virtual MIDI ports created:")
    print(f"  Output: Claude MCP Out")
    print(f"  Input: Claude MCP In")
    mcp.run()
```

### Signal Modification (Optional SysEx Handler)

```typescript
// app/src/services/MCPListener.ts
/**
 * Optional: Listen for MCP SysEx commands and respond
 */

import { RootStore } from "../stores/RootStore"

export class MCPListener {
  private rootStore: RootStore

  constructor(rootStore: RootStore) {
    this.rootStore = rootStore
    this.setupListener()
  }

  private setupListener() {
    // Listen to MIDI input for SysEx commands
    this.rootStore.midiInput.on("midiMessage", (message) => {
      if (message.data[0] === 0xF0) {  // SysEx
        this.handleSysEx(message.data)
      }
    })
  }

  private handleSysEx(data: Uint8Array) {
    // Check for custom commands
    if (data[1] === 0x7E && data[2] === 0x00) {
      switch (data[3]) {
        case 0x00:  // Clear command
          this.clearTrack()
          break
        case 0x01:  // Request state
          this.sendState()
          break
      }
    }
  }

  private clearTrack() {
    const track = this.rootStore.song.tracks[this.rootStore.selectedTrackId]
    if (track) {
      // Remove all note events
      track.events = track.events.filter(e =>
        !(e.type === 'channel' && e.subtype === 'note')
      )
    }
  }

  private sendState() {
    // Export current song state as SysEx
    const state = {
      ppq: this.rootStore.song.timebase,
      tracks: this.rootStore.song.tracks.map(track => ({
        id: track.id,
        channel: track.channel,
        events: track.events.filter(e =>
          e.type === 'channel' && e.subtype === 'note'
        )
      }))
    }

    const json = JSON.stringify(state)
    const bytes = new TextEncoder().encode(json)

    // Send via MIDI output
    const sysex = new Uint8Array([0xF0, ...bytes, 0xF7])

    this.rootStore.midiDeviceStore.outputs.forEach(output => {
      if (output.name === "Claude MCP In") {
        output.send(sysex)
      }
    })
  }
}

// Register in RootStore.ts
this.mcpListener = new MCPListener(this)
```

---

## Testing Plan

### Test 1: Basic MIDI Output
```
1. Start MCP server with virtual MIDI
2. Open Signal in browser
3. Go to Settings → MIDI Devices
4. Enable "Claude MCP Out" as input
5. Claude: "Add a C major chord at beat 0"
6. Verify: Chord appears in Signal piano roll
```

### Test 2: State Reading
```
1. Create notes manually in Signal
2. Claude: "What's in the piano roll?"
3. MCP server requests state via SysEx
4. Verify: Claude describes existing notes accurately
```

### Test 3: Modification
```
1. Create a chord progression manually
2. Claude: "Change the second chord to F minor"
3. MCP server deletes old chord, sends new one
4. Verify: Chord updated correctly
```

### Test 4: Complex Progression
```
1. Claude: "Create a jazz ii-V-I progression in Bb"
2. Verify: Cm7 - F7 - BbMaj7 appears correctly
3. Claude: "Add a walking bass line"
4. Verify: Bass notes appear on separate channel/track
```

---

## FAQ

### Q: Why not just use MIDI file import/export?
**A:** MIDI files require manual user action (save/load). Virtual MIDI enables real-time, automated communication without user intervention.

### Q: Can this work with the web version of Signal?
**A:** Yes! WebMIDI API works in Chrome-based browsers (Chrome, Edge, Opera). The Electron desktop app uses Chromium, so it works there too. Firefox doesn't support WebMIDI.

### Q: What about timing? MIDI has latency.
**A:** For composition (not live performance), latency doesn't matter. We're sending notes to be recorded, not playing them in real-time. Signal's `MIDIRecorder` handles timing.

### Q: How do we handle multiple tracks?
**A:** Two options:
1. Use MIDI channels (0-15) to target different tracks
2. Modify Signal to route channels to tracks (small change)

### Q: Can we preserve FL Studio-style preview queue?
**A:** Yes, add an optional `MCPQueueStore` to Signal (see "Optional: Add Preview Queue" section above).

### Q: What if Signal is already using MIDI for a keyboard?
**A:** No conflict! Signal can have multiple MIDI inputs enabled simultaneously. User keyboard and MCP virtual port work together.

---

## Conclusion

**Yes, you can absolutely use virtual MIDI I/O to control Signal's piano roll via MCP!**

**Recommended implementation:**
1. **Start with Option 1 (Virtual MIDI)** - No Signal changes needed, works immediately
2. **Add minimal SysEx handling** - Small Signal modification for state export and clear commands
3. **Optionally add preview queue** - If you want FL Studio-style review workflow

**Benefits over FL Studio approach:**
- ✅ Real-time communication (no file polling)
- ✅ Standard MIDI protocol (universal)
- ✅ Works with stock Signal (Option 1)
- ✅ Can extend to other MIDI software later

**Next steps:**
1. Install virtual MIDI driver (IAC on macOS, loopMIDI on Windows)
2. Create MCP server with `python-rtmidi`
3. Test sending notes to Signal
4. Iterate on protocol design

Let me know if you'd like me to implement the MCP server code for Signal!
