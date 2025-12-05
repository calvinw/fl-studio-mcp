# FL Studio Piano Roll MCP(macOS)

An MCP (Model Context Protocol) server that enables AI assistants like Claude to interact with FL Studio's piano roll on **macOS**. Create melodies, chord progressions, and musical patterns through natural language conversation with **automatic, real-time updates**.

See the video here:
[Claude Code and FL Studio Piano Roll (MacOs Version)](https://youtu.be/IbjqLRPr-Fg)

## Overview

Talk to Claude and watch your musical ideas appear instantly in FL Studio:
- Generate chord progressions by name or custom notes
- Create melodies and bass lines
- Modify existing MIDI notes
- Export and analyze piano roll state
- **Zero manual intervention** - notes appear automatically!

## Platform Support

**⚠️ macOS Only** - This project currently only supports macOS. The auto-trigger system uses AppleScript to send keystrokes to FL Studio, which is a macOS-specific technology.

## Prerequisites

- **macOS** (required for AppleScript-based auto-trigger)
- **FL Studio** (any recent version with Python scripting support)
- **Python 3.11+** (managed automatically by uv)
- **MCP-compatible client** (Claude Desktop, Claude Code CLI, or other MCP client)
- **uv** (Fast Python package manager - [installation guide](https://docs.astral.sh/uv/getting-started/installation/))

### macOS Accessibility Permissions

The auto-trigger needs permission to send keystrokes to FL Studio. You must enable Accessibility access for **Terminal** (or your terminal app) and **Claude Code** (if using Claude Code CLI):

1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Click the **+** button to add applications
3. Add **Terminal** (or iTerm, Warp, etc.)
4. Add **Claude** (Claude Code CLI) if you're using it
5. Ensure the toggles are **enabled** for each app

Without these permissions, the auto-trigger cannot send the Cmd+Opt+Y keystroke to FL Studio.

## Installation

### Quick Start (3 Commands)

```bash
git clone https://github.com/calvinw/fl-studio-mcp.git
cd fl-studio-mcp

./install_prerequisites.sh    # Install uv and Python
./install_mcp_for_claude.sh   # Register the mcp with Claude Code
./install_and_run.sh          # Setup FL Studio and start auto-trigger
```

**Then restart Claude Code and you're ready to go!**

### Detailed Installation

See [INSTALL.md](INSTALL.md) for comprehensive setup instructions including:
- Step-by-step installation for prerequisites
- Claude Code registration
- Gemini CLI registration (optional)
- FL Studio setup
- Auto-trigger management

### What Gets Installed

From `pyproject.toml`:
- **fastmcp** - MCP server framework
- **pynput** - Keyboard automation (for auto-trigger)
- **Python 3.11+** - Managed automatically by `uv`

## Usage

### Quick Start (Every Session)

**Step 1: Open FL Studio**
1. Open FL Studio
2. Open or create a piano roll
3. **Detach the piano roll window** (click the detach icon or drag it out) - this is required for the auto-trigger to work properly

**Step 2: Initialize the Script**

Run the script **once** to initialize the system:

```
Tools → Scripting → ComposeWithLLM
```

This sets up the piano roll state and clears the request queue (no dialog appears).

**Step 3: Auto-Trigger is Already Running**

After installation, the auto-trigger watcher runs in the background automatically.

To verify it's running:
```bash
ps aux | grep "fl_studio_auto_trigger.py" | grep -v grep
```

If it's not running:
```bash
./run_auto_trigger.sh
```

**Step 4: Talk to Claude or Gemini**

Now just talk to your AI assistant:

- "Add a C major chord"
- "Create a sad chord progression in Am"
- "Add a bass line"
- "Create a pentatonic melody"

Notes will appear automatically in FL Studio! (~0.5 seconds)

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

1. Press `Cmd+Opt+Y` (macOS) or `Ctrl+Alt+Y` (Windows) to refresh the state
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

## Available Tools

Your AI assistant has access to these MCP tools:

- `get_piano_roll_state()` - Read current piano roll state
- `send_notes(notes, mode)` - Add or replace notes (chords are just multiple notes with the same time)
- `delete_notes(notes)` - Remove specific notes
- `clear_queue()` - Discard pending requests

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
- Ensure the piano roll is **detached** (not docked inside FL Studio)
- Check that Terminal/Claude has **Accessibility permissions** (System Settings → Privacy & Security → Accessibility)

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
├── ComposeWithLLM.pyscript           (source bridge script)
├── fl_studio_mcp_server.py            (MCP server)
├── fl_studio_auto_trigger.py          (auto-trigger watcher)
├── install_prerequisites.sh           (install uv & Python environment)
├── install_mcp_for_claude.sh          (register with Claude Code)
├── install_mcp_for_gemini.sh          (register with Gemini CLI)
├── install_and_run.sh                 (setup FL Studio & start auto-trigger)
├── run_auto_trigger.sh                (start/restart auto-trigger)
├── stop_auto_trigger.sh               (stop auto-trigger)
├── CLAUDE.md                          (AI assistant documentation)
├── INSTALL.md                         (detailed installation guide)
└── README.md                          (this file)
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

