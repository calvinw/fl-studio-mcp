# FL Studio MCP Bridge

An MCP (Model Context Protocol) server that enables AI assistants like Claude to interact with FL Studio's piano roll. Create melodies, chord progressions, and musical patterns through natural language conversation with **automatic, real-time updates**.

## Overview

Talk to Claude and watch your musical ideas appear instantly in FL Studio:
- Generate chord progressions by name or custom notes
- Create melodies and bass lines
- Modify existing MIDI notes
- Export and analyze piano roll state
- **Zero manual intervention** - notes appear automatically!

## Prerequisites

- **FL Studio** (any recent version with Python scripting support)
- **Python 3.11+** (managed automatically by uv)
- **MCP-compatible client** (Claude Desktop, Claude Code CLI, or other MCP client)
- **uv** (Fast Python package manager - [installation guide](https://docs.astral.sh/uv/getting-started/installation/))

## Installation

### 1. Clone or Download This Repository

```bash
git clone https://github.com/calvinw/fl-studio-mcp.git
cd fl-studio-mcp
```

### 2. Install All Dependencies

Install everything with a single command using `uv sync`:

```bash
uv sync
```

This will:
- Create a virtual environment with Python 3.11
- Install all project dependencies (fastmcp, pynput, etc.)
- Set up the project in editable mode

### 3. Install the MCP Server

Run the installation script to register the MCP server with Claude Code:

```bash
./install_fl_studio_mcp_server.sh
```

This will register the FL Studio MCP server with Claude Code.

### 4. Set Up FL Studio and Auto-Trigger

Run the auto-trigger setup script:

```bash
./setup_auto_trigger.sh
```

This will:
- Copy `ComposeWithLLM.pyscript` to FL Studio's scripts directory
- Create initial JSON communication files
- Verify installation

**Verify installation:**
```bash
ls ~/Documents/Image-Line/FL\ Studio/Settings/Piano\ roll\ scripts/
```

Should show:
- `ComposeWithLLM.pyscript`
- `mcp_request.json`
- `mcp_response.json`
- `piano_roll_state.json`

### 5. Restart Claude Code

Restart Claude Code to load the newly registered MCP server.

## Usage

### Quick Start (Every Session)

**Step 1: Open FL Studio**
1. Open FL Studio
2. Open or create a piano roll

**Step 2: Initialize the Script**

Run the direct script **once** to set it as the "last script":

```
Tools → Scripting → ComposeWithLLM
```

The script will execute instantly (no dialog appears).

**Step 3: Start Auto-Trigger**

Open a terminal and run:

```bash
cd /path/to/fl-studio-mcp
uv run python fl_studio_auto_trigger.py
```

You should see:
```
🎹 FL Studio MCP Auto-Trigger
==================================================
📂 Watching: .../mcp_request.json
⌨️  Trigger: Cmd+Opt+Y (macOS) / Ctrl+Alt+Y (Windows/Linux)
🛑 Stop: Press Ctrl+C

✅ Auto-trigger is running...
💬 Talk to Claude to send notes!
```

**Leave this terminal window open!**

**Step 4: Talk to Claude**

Now just talk to your AI assistant:

- "Add a C major chord"
- "Create a sad chord progression in Am"
- "Add a bass line"
- "Create a pentatonic melody"

Notes will appear automatically in FL Studio!

### How It Works

```
You: "Add C major chord"
    ↓
Claude → Writes notes to mcp_request.json
    ↓
Auto-trigger detects file change → Sends Cmd+Opt+Y
    ↓
FL Studio re-runs ComposeWithLLM script
    ↓
Script adds notes to piano roll
    ↓
Notes appear! (~0.5 seconds)
```

### Important Tips

#### Refreshing State After Manual Edits

If you manually add/edit notes in FL Studio **between** talking to Claude:

1. Press `Cmd+Opt+Y` (macOS) or `Ctrl+Alt+Y` (Windows/Linux) to refresh the state
2. Then talk to Claude

This ensures Claude sees your manual changes!

**Example:**
```
You: "Add C major chord"
[Claude adds it automatically ✅]

[You manually add a melody 🎹]

[Press Cmd+Opt+Y to refresh state 🔄]

You: "Add a bass line"
[Claude sees the chord AND melody ✅]
```

### Example Requests

- "Create a I-IV-V-I progression in C major"
- "Add a pentatonic melody over these chords"
- "Add a bass note on the root of each chord"
- "Change that G note to an A"
- "Clear everything and create a jazz progression"
- "Add some arpeggios starting at beat 4"

## Available Commands

Your AI assistant has access to these tools:

- `get_piano_roll_state()` - Read current notes
- `send_notes(notes, mode)` - Add/replace notes
- `create_chord_from_name(chord_name, root_note, ...)` - Create chord by name
- `delete_notes(notes)` - Remove specific notes
- `clear_queue()` - Discard pending changes

See [CLAUDE.md](CLAUDE.md) for detailed documentation on how the AI assistant uses these tools.

## Architecture

```
┌─────────┐         ┌────────────┐         ┌──────────────┐
│ Claude  │────────▶│ MCP Server │────────▶│ Request Queue│
└─────────┘         └────────────┘         │ (JSON file)  │
                                           └──────┬───────┘
                                                  │
                                                  ▼
                                       ┌──────────────────┐
                                       │ Auto-Trigger     │
                                       │ Watches File     │
                                       └────────┬─────────┘
                                                │
                                                ▼
                                       Sends Cmd+Opt+Y
                                                │
                                                ▼
┌─────────────┐         ┌─────────────────────────────────┐
│ Piano Roll  │◀────────│ FL Studio Bridge Script         │
└─────────────┘         │ (re-runs, applies changes)      │
                        └─────────────────────────────────┘
                                     │
                                     ▼
                              ┌─────────────┐
                              │ State Export│
                              │ (JSON file) │
                              └─────────────┘
```

1. AI assistant sends musical requests via MCP tools
2. MCP server writes requests to JSON queue
3. Auto-trigger detects file change
4. Auto-trigger sends Cmd+Opt+Y to FL Studio
5. FL Studio re-runs ComposeWithLLM script
6. Script processes queue and applies changes
7. Notes appear instantly in piano roll
8. State is exported for Claude to see

## Configuration

### Supported Chord Types

The `create_chord_from_name` tool supports:
- Basic: `major`, `minor`, `dim`, `aug`
- Seventh: `maj7`, `min7`, `dom7`
- Suspended: `sus2`, `sus4`
- Extended: `maj9`, `min9`

## Troubleshooting

### Script Not Appearing in FL Studio

**Problem:** Bridge script doesn't show in Tools menu

**Solutions:**
- Re-run the setup script: `./setup_auto_trigger.sh`
- Ensure file has `.pyscript` extension
- Restart FL Studio
- Check FL Studio version supports Python scripting

### Changes Not Appearing

**Problem:** Sent requests but nothing happens

**Solutions:**
- Make sure auto-trigger script is running (check the terminal)
- Verify you ran `ComposeWithLLM` once in FL Studio
- Make sure FL Studio window is active
- Try pressing Cmd+Opt+Y manually to trigger

### Auto-Trigger Not Working

**Problem:** Terminal shows errors or nothing happens

**Solutions:**
- Restart the auto-trigger script
- Run `ComposeWithLLM` in FL Studio again
- Make sure dependencies are installed: `uv sync`
- Check FL Studio is the active window

### MCP Server Not Connecting

**Problem:** AI assistant doesn't have FL Studio tools

**Solutions:**
- Restart your MCP client (Claude Desktop/Code)
- Verify configuration file has correct path to `fl_studio_mcp_server.py`
- Ensure dependencies are installed: `uv sync`
- Check that the virtual environment was created in `.venv/`

### Notes at Wrong Positions

**Problem:** Notes appear at incorrect times

**Solutions:**
- Time values should be in quarter notes, not ticks
- `time=0` is beat 1, `time=4` is beat 5 (measure 2 in 4/4)
- Check PPQ value in state export for reference

### Permission Errors

**Problem:** Cannot write to JSON files

**Solutions:**
- Ensure FL Studio scripts directory exists
- Check file permissions (should be read/write)
- On Windows, may need to run FL Studio as administrator

## File Locations

**FL Studio scripts directory:**
```
~/Documents/Image-Line/FL Studio/Settings/Piano roll scripts/
├── ComposeWithLLM.pyscript  (bridge script - auto mode)
├── mcp_request.json          (request queue)
├── mcp_response.json         (execution results)
└── piano_roll_state.json     (exported piano roll state)
```

**Source repository:**
```
/path/to/fl-studio-mcp/
├── ComposeWithLLM.pyscript      (source bridge script)
├── fl_studio_mcp_server.py       (MCP server)
├── fl_studio_auto_trigger.py     (auto-trigger watcher)
├── setup_auto_trigger.sh         (installation script)
├── CLAUDE.md                     (AI assistant documentation)
└── README.md                     (this file)
```

## Development

### Making Changes

1. Edit files in this repository
2. For bridge script changes:
   ```bash
   cp ComposeWithLLM.pyscript \
     ~/Documents/Image-Line/FL\ Studio/Settings/Piano\ roll\ scripts/
   ```
3. Run the script once in FL Studio to reload

### Debugging

- Check the auto-trigger terminal for real-time status
- Look at `mcp_response.json` for execution results
- Enable debug output in the MCP server if needed

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

MIT License - feel free to use and modify for your projects.

## Support

For issues, questions, or feature requests, please open an issue on GitHub.

## Acknowledgments

Built using the [Model Context Protocol](https://modelcontextprotocol.io/) specification.

Special thanks to the FL Studio and Python communities.
